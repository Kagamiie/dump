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
        // Stocker les coordonnées cibles
        popup.targetX = px
        popup.targetY = py
        visible = !visible
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
    }

    Rectangle {
        id: popup

        property int targetX: 0
        property int targetY: 0

        width: row.implicitWidth + 16
        height: 36
        color: c.bg1
        border.width: 1
        border.color: c.bg3

        // Recalculer x/y quand height est connu ET visible
        x: targetX
        y: {
            // height est 0 avant le premier rendu — utiliser 36 comme fallback
            const h = height > 0 ? height : 36
            return targetY - (h - 15)
        }

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
                            mouse.button === Qt.LeftButton
                                ? modelData.activate()
                                : modelData.secondaryActivate()
                            root.visible = false
                        }
                    }
                }
            }
        }
    }
}
