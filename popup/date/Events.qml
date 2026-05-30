import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../themes/"
import "../../services/"

Item {
    required property Colors c
    implicitHeight: col.implicitHeight

    property var    events: []
    property var    buffer: []
    property string todayStr: {
        const d = new Date()
        return d.getFullYear() + "-" +
               (d.getMonth() + 1).toString().padStart(2, "0") + "-" +
               d.getDate().toString().padStart(2, "0")
    }
    property string tomorrowStr: {
        const d = new Date()
        d.setDate(d.getDate() + 1)
        return d.getFullYear() + "-" +
               (d.getMonth() + 1).toString().padStart(2, "0") + "-" +
               d.getDate().toString().padStart(2, "0")
    }

    GcalParser { id: parser }

    Timer {
        interval: 60000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: { fetchProc.running = false; Qt.callLater(() => fetchProc.running = true) }
    }

    Process {
        id: fetchProc
        command: ["sh", "-c", "gcalcli --nocolor agenda " + todayStr + " " + tomorrowStr + " --details all --tsv 2>/dev/null"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                const event = parser.parseLine(line)
                if (event) buffer.push(event)
            }
        }
        onRunningChanged: { if (running) buffer = [] }
        onExited: { events = buffer.slice() }
    }

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right }
        spacing: 4

        Text {
            text: "Today"
            font { pixelSize: 11; bold: true; family: "JetBrains Mono Nerd Font" }
            color: c.fg2
        }

        Text {
            visible: events.length === 0
            text: "No events today"
            font { pixelSize: 11; family: "JetBrains Mono Nerd Font" }
            color: c.bg4
        }

        Repeater {
            model: events
            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: eventCol.implicitHeight + 12
                color: c.bg1
                border { width: 1; color: c.bg3 }

                Rectangle {
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: 3
                    color: c.accent
                }

                ColumnLayout {
                    id: eventCol
                    anchors {
                        left: parent.left; right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: 12; rightMargin: 8
                    }
                    spacing: 2

                    RowLayout {
                        spacing: 6
                        Layout.fillWidth: true

                        Text {
                            text: modelData.courseCode
                            font { pixelSize: 10; bold: true; family: "JetBrains Mono Nerd Font" }
                            color: c.accent
                            elide: Text.ElideRight
                            Layout.maximumWidth: 80
                        }
                        Text {
                            visible: modelData.start !== ""
                            text: "•"
                            font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                            color: c.fg2
                        }
                        Text {
                            visible: modelData.start !== ""
                            text: modelData.start + " → " + modelData.end
                            font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                            color: c.accent
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        text: modelData.courseName !== "" ? modelData.courseName : modelData.courseCode
                        font { pixelSize: 11; bold: true; family: "JetBrains Mono Nerd Font" }
                        color: c.fg0
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        visible: modelData.start !== "" && (modelData.prof !== "" || modelData.salle !== "")
                        text: modelData.prof + "  •  " + modelData.salle
                        font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                        color: c.fg2
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
