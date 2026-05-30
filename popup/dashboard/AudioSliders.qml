import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../themes/"
import "../../services/"

ColumnLayout {
    required property Colors c
    required property Glyphs g
    spacing: 8

    property int    volValue:   AudioService.volume
    property bool   volMuted:   AudioService.muted
    property string volLabel:   AudioService.label
    property int    micValue:   AudioService.micVol
    property bool   micMuted:   AudioService.micMuted
    property string micLabel:   AudioService.micLabel
    property int    brightValue: 50

    Process {
        id: brightGetProc
        command: ["sh", "-c", "brightnessctl -m | awk -F, '{print $4}' | tr -d '%'"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => { if (line.trim()) brightValue = parseInt(line.trim()) }
        }
    }

    Process { id: setVolProc;   property string cmd: ""; command: ["sh", "-c", cmd] }
    Process { id: setMicProc;   property string cmd: ""; command: ["sh", "-c", cmd] }
    Process { id: setBrightProc; property string cmd: ""; command: ["sh", "-c", cmd] }

    component SliderRow: Item {
        required property Colors  c
        required property Glyphs  g
        required property string  icon
        required property string  label
        required property int     value
        required property bool    isMuted
        signal iconClicked()
        signal moved(int val)

        id: sliderRoot
        height: 21
        Layout.fillWidth: true

        Rectangle {
            anchors.fill: parent
            color: "transparent"

            Row {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    width: 28; height: parent.height
                    color: sliderRoot.c.bg2

                    Text {
                        anchors.centerIn: parent
                        text: sliderRoot.icon
                        font { family: gwnce.name; pixelSize: 11 }
                        color: iconMa.containsMouse ? sliderRoot.c.accent : sliderRoot.c.fg0
                    }

                    MouseArea {
                        id: iconMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sliderRoot.iconClicked()
                    }
                }

                Rectangle { width: 1; height: parent.height; color: sliderRoot.c.bg3 }

                Item {
                    id: sliderArea
                    width: parent.width - 29
                    height: parent.height

                    Rectangle {
                        x: 1; y: 1
                        width: (sliderArea.width * sliderRoot.value / 100) - 1
                        height: parent.height - 2
                        color: sliderRoot.c.bg2
                    }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 8; rightMargin: 8; topMargin: 3; bottomMargin: 3 }
                        Text {
                            Layout.fillWidth: true
                            text: sliderRoot.label
                            font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                            color: sliderRoot.c.fg0
                            elide: Text.ElideRight
                        }
                        Text {
                            text: sliderRoot.value + "%"
                            font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                            color: sliderRoot.c.fg2
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: mouse => sliderRoot.moved(Math.max(0, Math.min(100, Math.round(mouse.x / width * 100))))
                        onPositionChanged: mouse => { if (pressed) sliderRoot.moved(Math.max(0, Math.min(100, Math.round(mouse.x / width * 100)))) }
                    }

                    Rectangle {
                        anchors.fill: parent
                        border { width: 1; color: rowHov.containsMouse ? sliderRoot.c.accent : sliderRoot.c.bg3 }
                        color: "transparent"
                    }
                }
            }

            MouseArea {
                id: rowHov
                anchors.fill: parent
                hoverEnabled: true
                propagateComposedEvents: true
                onClicked: mouse => mouse.accepted = false
            }
        }
    }

    SliderRow {
        c: parent.c; g: parent.g
        icon:    (volMuted || volValue === 0) ? g.audioMuted : volValue < 50 ? g.audioDecrease : g.audioIncrease
        label:   volLabel; value: volValue; isMuted: volMuted
        onIconClicked: { setVolProc.cmd = "pactl set-sink-mute @DEFAULT_SINK@ toggle";         setVolProc.running = true }
        onMoved: val => { setVolProc.cmd = "pactl set-sink-volume @DEFAULT_SINK@ " + val + "%"; setVolProc.running = true }
    }
    SliderRow {
        c: parent.c; g: parent.g
        icon:    (micMuted || micValue === 0) ? g.micMuted : micValue < 50 ? g.micDecrease : g.micIncrease
        label:   micLabel; value: micValue; isMuted: micMuted
        onIconClicked: { setMicProc.cmd = "pactl set-source-mute @DEFAULT_SOURCE@ toggle";         setMicProc.running = true }
        onMoved: val => { setMicProc.cmd = "pactl set-source-volume @DEFAULT_SOURCE@ " + val + "%"; setMicProc.running = true }
    }
    SliderRow {
        c: parent.c; g: parent.g
        icon:  g.layoutTile
        label: "Brightness"; value: brightValue; isMuted: false
        onIconClicked: {}
        onMoved: val => {
            setBrightProc.cmd = "brightnessctl set " + val + "%"
            setBrightProc.running = true
            brightValue = val
        }
    }
}
