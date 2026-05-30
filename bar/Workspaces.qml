import QtQuick
import "../themes/"

Item {
    required property var screen
    required property Colors c
    required property var ipc

    implicitHeight: parent.height
    implicitWidth: wrapper.implicitWidth

    Rectangle {
        id: wrapper
        anchors.centerIn: parent
        implicitWidth: dots.implicitWidth + 22
        height: 24
        color: c.bg1
        border { width: 1; color: c.bg3 }

        Row {
            id: dots
            anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 11 }
            spacing: 8

            Repeater {
                model: ipc.workspaces
                delegate: Item {
                    required property var modelData
                    implicitWidth: dot.implicitWidth
                    height: 14
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        id: dot
                        implicitWidth: modelData.isFocused ? 48 : modelData.hasWindows ? 32 : 16
                        height: 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: modelData.isFocused ? c.accent : modelData.hasWindows ? c.fg2 : c.bg4
                        border { width: 1; color: modelData.isFocused ? c.accent : c.bg3 }
                        Behavior on implicitWidth { SmoothedAnimation { velocity: 150 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ipc.focusWorkspace(modelData.id)
                    }
                }
            }
        }
    }
}
