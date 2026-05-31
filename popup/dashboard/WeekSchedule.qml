import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../themes/"
import "../../services/"

ColumnLayout {
    id: root
    required property Colors c
    spacing: 4

    property var    events:   []
    property var    grouped:  ({})
    property string todayStr: _fmtDate(new Date())

    property var  hoveredEvent: null
    property real tooltipX:     0
    property real tooltipY:     0

    property bool gcalError: false

    GcalParser { id: parser }

    Timer {
        interval: {
            const now = new Date()
            const midnight = new Date(now)
            midnight.setHours(24, 0, 0, 0)
            return midnight - now
        }
        repeat: false; running: true
        onTriggered: {
            todayStr = _fmtDate(new Date())
            _triggerFetch()
            interval = 86400000
            repeat   = true
        }
    }

    function monday() {
        const d    = new Date()
        const diff = (d.getDay() === 0 ? -6 : 1 - d.getDay())
        const m    = new Date(d)
        m.setDate(d.getDate() + diff)
        return m
    }

    function sunday() {
        const m = monday()
        const s = new Date(m)
        s.setDate(m.getDate() + 6)
        return s
    }

    function _fmtDate(d) {
        return d.getFullYear() + "-" +
               (d.getMonth() + 1).toString().padStart(2, "0") + "-" +
               d.getDate().toString().padStart(2, "0")
    }

    function dayLabel(dateStr) {
        const days = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
        return days[new Date(dateStr + "T12:00:00").getDay()]
    }

    function _groupByDay(evts) {
        const groups = {}
        for (const e of evts) {
            if (!groups[e.date]) groups[e.date] = []
            groups[e.date].push(e)
        }
        return groups
    }

    readonly property var days: {
        const m   = monday()
        const arr = []
        for (let i = 0; i < 7; i++) {
            const d = new Date(m)
            d.setDate(m.getDate() + i)
            arr.push(_fmtDate(d))
        }
        return arr
    }

    function _triggerFetch() {
        fetchProc.startDate = _fmtDate(monday())
        fetchProc.endDate   = _fmtDate(sunday())
        fetchProc.running   = false
        Qt.callLater(() => fetchProc.running = true)
    }

    Timer {
        interval: 300000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: _triggerFetch()
    }

    Process {
        id: fetchProc
        property string startDate: ""
        property string endDate:   ""
        property var    buffer:    []

        command: ["sh", "-c",
            "gcalcli --nocolor agenda " + startDate + " " + endDate +
            " --details all --tsv 2>/dev/null"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                const event = parser.parseLine(line)
                if (event) fetchProc.buffer.push(event)
            }
        }

        onRunningChanged: { if (running) buffer = [] }

        onExited: code => {
            if (code !== 0) {
                gcalError = true
                console.warn("WeekSchedule: gcalcli exited with code", code)
                return
            }
            gcalError = false
            const evts = buffer.slice()

            events  = evts
            grouped = _groupByDay(evts)
        }
    }

    Component.onCompleted: _triggerFetch()

    Repeater {
        model: days
        delegate: Item {
            required property string modelData
            required property int    index

            property string dateStr:   modelData
            property bool   isToday:   dateStr === todayStr
            property var    dayEvents: grouped[dateStr] ?? []

            Layout.fillWidth: true
            implicitHeight: Math.max(22, eventsFlow.implicitHeight + 8)
            visible: isToday || dayEvents.length > 0

            Rectangle {
                width: 32; height: parent.height
                color: isToday ? c.accent : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: dayLabel(dateStr)
                    font { pixelSize: 9; family: "JetBrains Mono Nerd Font"; bold: isToday }
                    color: isToday ? c.bg0 : c.fg2
                }
            }

            Rectangle { x: 32; width: 1; height: parent.height; color: c.bg3 }

            Flow {
                id: eventsFlow
                anchors { left: parent.left; right: parent.right; leftMargin: 40; top: parent.top; topMargin: 4 }
                spacing: 4

                Repeater {
                    model: dayEvents
                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        property bool hov: false

                        implicitWidth: chipRow.implicitWidth + 14
                        height: 18
                        color: hov ? c.bg3 : c.bg2
                        border { width: 1; color: isToday ? c.accent : hov ? c.fg2 : c.bg3 }

                        Rectangle { width: 2; height: parent.height; color: isToday ? c.accent : c.fg2 }

                        RowLayout {
                            id: chipRow
                            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                            spacing: 4

                            Text {
                                text: modelData.courseCode
                                font { pixelSize: 9; bold: true; family: "JetBrains Mono Nerd Font" }
                                color: isToday ? c.accent : c.fg0
                            }
                            Text {
                                visible: modelData.start !== ""
                                text: modelData.start
                                font { pixelSize: 9; family: "JetBrains Mono Nerd Font" }
                                color: c.fg2
                            }
                            Text {
                                visible: modelData.salle !== ""
                                text: modelData.salle
                                font { pixelSize: 9; family: "JetBrains Mono Nerd Font" }
                                color: c.fg1
                            }
                        }

                        HoverHandler {
                            onHoveredChanged: {
                                hov = hovered
                                if (hovered) {
                                    hoveredEvent = modelData
                                    const pos = parent.mapToItem(root, 0, parent.height + 2)
                                    tooltipX = Math.min(pos.x, 320 - 200)
                                    tooltipY = pos.y
                                } else {
                                    hoveredEvent = null
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: dayEvents.length === 0 && isToday
                    text: "Free"
                    font { pixelSize: 9; family: "JetBrains Mono Nerd Font" }
                    color: c.bg4
                }
            }
        }
    }

    Text {
        visible: events.length === 0 && !gcalError
        text: "No events this week"
        font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
        color: c.bg4
        Layout.alignment: Qt.AlignHCenter
    }

    Text {
        visible: gcalError
        text: "Calendar unavailable"
        font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
        color: c.red
        Layout.alignment: Qt.AlignHCenter
    }

    Rectangle {
        visible: hoveredEvent !== null
        x: tooltipX; y: tooltipY
        z: 99
        width: 200
        implicitHeight: tipCol.implicitHeight + 12
        color: c.bg1
        border { width: 1; color: c.accent }

        ColumnLayout {
            id: tipCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: hoveredEvent?.courseCode ?? ""
                    font { pixelSize: 10; bold: true; family: "JetBrains Mono Nerd Font" }
                    color: c.accent
                }
                Text {
                    text: hoveredEvent ? hoveredEvent.start + " → " + hoveredEvent.end : ""
                    font { pixelSize: 9; family: "JetBrains Mono Nerd Font" }
                    color: c.fg2
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                }
            }

            Text {
                visible: (hoveredEvent?.courseName ?? "") !== ""
                text: hoveredEvent?.courseName ?? ""
                font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                color: c.fg0
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Text {
                visible: (hoveredEvent?.prof ?? "") !== "" || (hoveredEvent?.salle ?? "") !== ""
                text: (hoveredEvent?.prof ?? "") + "  •  " + (hoveredEvent?.salle ?? "")
                font { pixelSize: 9; family: "JetBrains Mono Nerd Font" }
                color: c.fg2
                Layout.fillWidth: true
            }
        }
    }
}
