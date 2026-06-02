import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../themes/"
import "../../components/"

Rectangle {
    required property Colors c
    required property Glyphs g
    height: 72
    color: c.bg1

    border { width: 1; color: c.bg3 }

    property string hostname: "moya"
    property string uptimeText: "up since ..."

    Process {
        command: ["sh", "-c", "uname -n"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => { if (line.trim()) hostname = line.trim() }
        }
    }

    Timer {
        interval: 60000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: uptimeProc.running = true
    }

    Process {
        id: uptimeProc
        command: ["sh", "-c", "uptime -p 2>/dev/null || uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}'"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                if (!line.trim()) return
                uptimeText = "up since " + line.trim()
                    .replace("up ", "").replace(/ hours?/, "h")
                    .replace(/ minutes?/, "m").replace(/ days?/, "d")
                    .replace(", ", " ")
            }
        }
    }

    // Generic power command executor
    property var _powerProc: Process {
        property string cmd: ""
        command: ["sh", "-c", cmd]
    }

    function executePowerAction(command) {
        _powerProc.cmd = command
        _powerProc.running = true
    }

    RowLayout {
        anchors { fill: parent; margins: 16 }
        spacing: 8

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true

            Row {
                spacing: 0
                Text {
                    text: Quickshell.env("USER") ?? "user"
                    font { family: "JetBrains Mono Nerd Font"; pixelSize: 14; bold: true }
                    color: c.accent
                }
                Text {
                    text: "@" + hostname
                    font { family: "JetBrains Mono Nerd Font"; pixelSize: 14 }
                    color: c.fg0
                }
            }

            Text {
                text: uptimeText
                font { family: "JetBrains Mono Nerd Font"; pixelSize: 10 }
                color: c.fg1
            }
        }

        Row {
            Layout.alignment: Qt.AlignRight
            spacing: 6
            Repeater {
                model: [
                    { icon: g.powerShutdown, cmd: "systemctl poweroff" },
                    { icon: g.powerReboot,   cmd: "systemctl reboot" },
                    { icon: g.powerSuspend,  cmd: "systemctl suspend" },
                    { icon: g.powerLogoff,   cmd: "niri msg action quit" }
                ]
                delegate: Rectangle {
                    required property var modelData
                    width: 22; height: 22
                    color: btnMa.containsMouse ? c.bg3 : c.bg2
                    border { width: 1; color: btnMa.containsMouse ? c.red : c.bg3 }
                    Behavior on color { ColorAnimation { duration: 80 } }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.icon
                        font { family: gwnce.name; pixelSize: 13 }
                        color: btnMa.containsMouse ? c.red : c.fg0
                    }

                    MouseArea {
                        id: btnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: executePowerAction(modelData.cmd)
                    }
                }
            }
        }
    }
}
