import QtQuick
import "../themes/"

Item {
    id: tray
    required property Colors c
    required property Glyphs g
    implicitHeight: 24
    implicitWidth: toggleBox.width

    Rectangle {
        id: toggleBox
        width: 24
        height: 24
        anchors.verticalCenter: parent.verticalCenter
        color: togMa.containsMouse ? c.bg2 : c.bg1
        border { width: 1; color: c.bg3 }
        Behavior on color { ColorAnimation { duration: 80 } }

        Text {
            anchors.centerIn: parent
            text: systrayMenu.visible ? g.arrowRight : g.arrowLeft
            font { family: gwnce.name; pixelSize: 15 }
            color: c.fg3
        }

        MouseArea {
            id: togMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                const pos = toggleBox.mapToGlobal(0, toggleBox.height)
                systrayMenu.toggleAt(pos.x, pos.y)
            }
        }
    }
}
