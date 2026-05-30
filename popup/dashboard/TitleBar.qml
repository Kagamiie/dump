import QtQuick
import QtQuick.Layouts
import "../../themes/"

Rectangle {
    required property Colors c
    required property Glyphs g
    height: 32
    color: c.bg1

    Rectangle {
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 1
        color: c.bg3
    }

    RowLayout {
        anchors { fill: parent; leftMargin: 10 }
        spacing: 0

        Text {
            text: "Quick Settings Menu"
            font.pixelSize: 11
            font.family: "JetBrains Mono Nerd Font"
            color: c.fg0
            Layout.fillWidth: true
        }

        Rectangle { width: 1; height: parent.height; color: c.bg3 }

        Item {
            width: 32; height: parent.height
            Text {
                anchors.centerIn: parent
                text: g.utilsHamburger
                font.family: gwnce.name
                font.pixelSize: 11
                color: c.fg2
            }
        }
    }
}
