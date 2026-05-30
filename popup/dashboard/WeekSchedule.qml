import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../themes/"

ColumnLayout {
    id: root
    required property Colors c
    spacing: 4

    property var    events:      []
    property var    buffer:      []
    property var    grouped:     ({})
    property string todayStr:    fmtDate(new Date())

    property var  hoveredEvent: null
    property real tooltipX:     0
    property real tooltipY:     0

    property bool gcalError: false

    Timer {
        interval: {
            const now = new Date()
            const midnight = new Date(now)
            midnight.setHours(24, 0, 0, 0)
            return midnight - now
        }
        repeat: false
        running: true
        onTriggered: { todayStr = fmtDate(new Date()); fetchProc.running = false; Qt.callLater(() => fetchProc.running = true) }
    }

    function monday() {
        const d = new Date()
        const diff = (d.getDay() === 0 ? -6 : 1 - d.getDay())
        const m = new Date(d)
        m.setDate(d.getDate() + diff)
        return m
    }

    function sunday() {
        const m = monday()
        const s = new Date(m)
        s.setDate(m.getDate() + 6)
        return s
    }

    function fmtDate(d) {
        return d.getFullYear() + "-" +
               (d.getMonth() + 1).toString().padStart(2, "0") + "-" +
               d.getDate().toString().padStart(2, "0")
    }

    function dayLabel(dateStr) {
        const days = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
        return days[new Date(dateStr + "T12:00:00").getDay()]
    }

    function groupByDay() {
        const groups = {}
        for (const e of events) {
            if (!groups[e.date]) groups[e.date] = []
            groups[e.date].push(e)
        }
        return groups
    }

    readonly property var days: {
        const m = monday()
        const arr = []
        for (let i = 0; i < 7; i++) {
            const d = new Date(m)
            d.setDate(m.getDate() + i)
            arr.push(fmtDate(d))
        }
        return arr
    }

    Timer {
        interval: 300000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: {
            fetchProc.startDate = fmtDate(monday())
            fetchProc.endDate   = fmtDate(sunday())
            fetchProc.running   = false
            Qt.callLater(() => fetchProc.running = true)
        }
    }

    Process {
        id: fetchProc
        property string startDate: ""
        property string endDate:   ""
        command: ["sh", "-c", "gcalcli --nocolor agenda " + startDate + " " + endDate + " --details all --tsv 2>/dev/null"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                if (!line.trim()) return
                const parts = line.split("\t")
                if (parts.length < 10 || parts[2].trim() === "start_time") return

                const date       = parts[1].trim()
                const start      = parts[2].trim()
                const end        = parts[4].trim()
                const rawTitle   = parts[9].trim().split(";")[0].trim()
                const dashIdx    = rawTitle.indexOf(" - ")
                const courseCode = dashIdx !== -1 ? rawTitle.substring(0, dashIdx).trim() : rawTitle
                const courseName = dashIdx !== -1 ? rawTitle.substring(dashIdx + 3).trim() : ""
                const salle      = parts.length > 10 ? parts[10].trim().split(" - ")[0].trim() : ""
                const prof       = parts.length > 11 ? parts[11].trim().split(";")[0].trim()   : ""

                buffer.push({ date, start, end, courseCode, courseName, salle, prof })
            }
        }

        onRunningChanged: { if (running) buffer = [] }
        onExited: code => {
            if (code !== 0) {
                gcalError = true
                return
            }
            events = buffer.slice()
            grouped = ({})
            Qt.callLater(() => { grouped = groupByDay() })
        }
    }

    Component.onCompleted: {
        fetchProc.startDate = fmtDate(monday())
        fetchProc.endDate   = fmtDate(sunday())
        fetchProc.running   = true
    }

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

            Rectangle {
                x: 32; width: 1; height: parent.height
                color: c.bg3
            }

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

                        Rectangle {
                            width: 2; height: parent.height
                            color: isToday ? c.accent : c.fg2
                        }

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
        visible: events.length === 0
        text: "No events this week"
        font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
        color: c.bg4
        Layout.alignment: Qt.AlignHCenter
    }

    // Tooltip
    Rectangle {
        visible: hoveredEvent !== null
        x: tooltipX
        y: tooltipY
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
