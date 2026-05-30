import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import "../themes/"

PanelWindow {
    id: root
    required property Colors c

    visible: false
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    anchors { top: true; left: true; right: true; bottom: true }

    function toggleAt(px, py) {
        popup.x = px
        popup.y = py - (popup.height-15)
        visible = !visible
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
    }

    Rectangle {
        id: popup

        width: row.implicitWidth + 16
        height: 36
        color: c.bg1
        border.width: 1
        border.color: c.bg3

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8

            Repeater {
                model: SystemTray.items
                delegate: Item {
                    required property SystemTrayItem modelData
                    width: 18; height: 18
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        anchors.fill: parent
                        source: modelData.icon
                        fillMode: Image.PreserveAspectFit
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            mouse.button === Qt.LeftButton ? modelData.activate() : modelData.secondaryActivate()
                            root.visible = false
                        }
                    }
                }
            }
        }
    }
}
