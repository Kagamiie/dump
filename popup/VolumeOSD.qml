import QtQuick
import Quickshell
import Quickshell.Wayland
import "../themes/"

PanelWindow {
    id: root
    required property Colors c
    required property Glyphs g

    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    anchors { top: true; left: true; right: true; bottom: true }

    property int  volume: 0
    property bool muted:  false

    mask: Region { item: osdRect }

    function show(vol, mut) { volume = vol; muted = mut; root.visible = true; hideTimer.restart() }

    Timer { id: hideTimer; interval: 3000; onTriggered: root.visible = false }

    Rectangle {
        id: osdRect
        x: (parent.width - width) / 1.01; y: 44+3
        width: 32; height: 200
        color: c.bg0
        border { width: 1; color: c.bg3 }

        Column {
            anchors { fill: parent; topMargin: 8; leftMargin: 8; rightMargin: 8 }
            spacing: 8

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                font { family: gwnce.name; pixelSize: 12 }
                color: muted ? c.red : c.fg0
                text: (muted || volume === 0) ? g.audioMuted : volume < 50 ? g.audioDecrease : g.audioIncrease
            }

            Rectangle {
                width: 6; height: parent.height - 50
                anchors.horizontalCenter: parent.horizontalCenter
                color: c.bg1

                Rectangle {
                    width: parent.width
                    height: parent.height * volume / 100
                    anchors.bottom: parent.bottom
                    color: muted ? c.red : c.fg0
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                font { family: "JetBrains Mono Nerd Font"; pixelSize: 10 }
                color: c.fg2
                text: volume + "%"
            }
        }
    }
}
