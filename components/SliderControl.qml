import QtQuick
import QtQuick.Layouts
import "../themes/"

Item {
    id: root
    required property Colors c
    required property Glyphs g
    required property string icon
    required property string label
    required property int value
    required property bool isMuted

    signal iconClicked()
    signal moved(int val)

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
                color: root.c.bg2

                Text {
                    anchors.centerIn: parent
                    text: root.icon
                    font { family: gwnce.name; pixelSize: 11 }
                    color: iconMa.containsMouse ? root.c.accent : root.c.fg0
                }

                MouseArea {
                    id: iconMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.iconClicked()
                }
            }

            Rectangle { width: 1; height: parent.height; color: root.c.bg3 }

            Item {
                id: sliderArea
                width: parent.width - 29
                height: parent.height

                Rectangle {
                    x: 1; y: 1
                    width: (sliderArea.width * root.value / 100) - 1
                    height: parent.height - 2
                    color: root.c.bg2
                }

                RowLayout {
                    anchors { fill: parent; leftMargin: 8; rightMargin: 8; topMargin: 3; bottomMargin: 3 }
                    Text {
                        Layout.fillWidth: true
                        text: root.label
                        font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                        color: root.c.fg0
                        elide: Text.ElideRight
                    }
                    Text {
                        text: root.value + "%"
                        font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                        color: root.c.fg2
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: mouse => root.moved(Math.max(0, Math.min(100, Math.round(mouse.x / width * 100))))
                    onPositionChanged: mouse => { if (pressed) root.moved(Math.max(0, Math.min(100, Math.round(mouse.x / width * 100)))) }
                }

                Rectangle {
                    anchors.fill: parent
                    border { width: 1; color: rowHov.containsMouse ? root.c.accent : root.c.bg3 }
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
