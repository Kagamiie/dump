import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    required property Colors c
    required property string text
    property string icon: ""
    property bool danger: false
    property bool filled: false
    property int minWidth: 0

    signal clicked()

    implicitWidth: Math.max(minWidth, row.implicitWidth + 16)
    implicitHeight: 24

    color: ma.containsMouse ? 
        (danger ? c.red : (filled ? c.accent : c.bg2)) : 
        (filled ? c.accent : c.bg1)
    
    border { width: 1; color: ma.containsMouse ? (danger ? c.red : c.accent) : c.bg3 }
    Behavior on color { ColorAnimation { duration: 80 } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            visible: icon !== ""
            text: root.icon
            font { family: gwnce.name; pixelSize: 12 }
            color: ma.containsMouse ? (danger ? c.fg0 : (filled ? c.bg0 : c.accent)) : c.fg2
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.text
            font { pixelSize: 11; family: "JetBrains Mono Nerd Font" }
            color: ma.containsMouse ? (danger ? c.fg0 : (filled ? c.bg0 : c.accent)) : (filled ? c.bg0 : c.fg2)
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
