import QtQuick
import Quickshell.Io

import "../themes/"

Item {
    required property Colors c
    implicitWidth: lbl.implicitWidth
    implicitHeight: parent.height

    property string kblayout: "??"

    Component.onDestruction: {
        proc.running = false
    }

    Timer {
        id: procTimeout
        interval: 3000
        repeat: false
        running: proc.running

        onTriggered: {
            if (proc.running) {
                proc.running = false
                console.warn("Keyboard layout query timeout")
            }
        }
    }

    Process {
        id: proc
        command: ["localectl", "status", "--no-pager"]
        running: true
        
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                const trimmed = line.trim()
                if (trimmed.startsWith("X11 Layout:")) {
                    const layout = trimmed.split(":")[1]?.trim() ?? "??"
                    if (layout) kblayout = layout
                }
            }
        }

        onExited: (code) => {
            procTimeout.stop()
            if (code !== 0) {
                console.warn("Failed to query keyboard layout (code", code + ")")
                kblayout = "ERR"
            }
        }
    }

    Text {
        id: lbl
        anchors.verticalCenter: parent.verticalCenter
        text: kblayout
        font.family: "JetBrains Mono Nerd Font"
        font.pixelSize: 11
        color: c.fg2
    }
}
