import QtQuick
import "../../../themes/"

Rectangle {
    required property Colors c
    property string label
    property bool   danger:      false
    property color  activeColor: danger ? c.red : c.accent
    signal clicked()

    width:  label === "Pair" ? 36 : 72
    height: 18
    color:  c.bg1
    border { width: 1; color: ma.containsMouse ? activeColor : c.bg3 }

    Text {
        anchors.centerIn: parent
        text:  parent.label
        font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
        color: ma.containsMouse ? activeColor : c.fg2
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape:  Qt.PointingHandCursor
        onClicked:    parent.clicked()
    }
}
