import QtQuick
import Quickshell.Io

import "../themes/"

Item {
    required property Colors c
    implicitWidth: lbl.implicitWidth
    implicitHeight: parent.height

    property string kblayout: "??"

    Process {
        id: proc
        command: ["sh", "-c", "localectl status | grep 'X11 Layout' | awk '{print $3}'"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                if (line.trim() !== "") kblayout = line.trim()
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
