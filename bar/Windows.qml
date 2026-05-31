import QtQuick
import QtQuick.Layouts
import "../themes/"

Item {
    required property Colors c
    required property var ipc

    implicitHeight: parent?.height ?? 36

    RowLayout {
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        height: 24
        spacing: 6

        Repeater {
            model: ipc.windows
            delegate: Rectangle {
                required property var modelData
                height: 24

                Layout.fillWidth: true
                Layout.maximumWidth: 200
                color: modelData.focused ? c.bg2 : c.bg1
                border.width: 1
                border.color: c.bg3

                Text {
                    id: lbl
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        right: parent.right
                        leftMargin: 13
                        rightMargin: 13
                    }
                    text: modelData.title
                    font.pixelSize: 11
                    font.family: "JetBrains Mono Nerd Font"
                    color: modelData.focused ? c.accent : c.fg2
                    elide: Text.ElideRight
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ipc.focusWindow(modelData.id)
                }
            }
        }
    }
}
