import QtQuick
import "../themes/"

Item {
    required property Colors c
    required property Glyphs g
    required property var launcher
    implicitHeight: parent.height
    implicitWidth: row.implicitWidth + 16

    Connections {
        target: launcher ?? null
        function onVisibleChanged() {
            ic.color  = launcher.visible ? c.fg3 : c.fg2
            lbl.color = launcher.visible ? c.fg3 : c.fg2
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked:  { if (launcher) launcher.toggle() }
        onEntered:  { ic.color = c.accent; lbl.color = c.accent }
        onExited:   {
            ic.color  = (launcher && launcher.visible) ? c.fg3 : c.fg2
            lbl.color = (launcher && launcher.visible) ? c.fg3 : c.fg2
        }
    }

    Row {
        id: row
        anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 8 }
        spacing: 6

        Text {
            id: ic
            anchors.verticalCenter: parent.verticalCenter
            text: g.utilsMagnifier
            font.family: gwnce.name
            font.pixelSize: 14
            color: c.fg2
        }

        Text {
            id: lbl
            anchors.verticalCenter: parent.verticalCenter
            text: "Search"
            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 12
            color: c.fg2
        }
    }
}
