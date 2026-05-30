import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../themes/"

PanelWindow {
    id: root
    required property Colors c
    required property Glyphs g

    visible: false
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    function toggle() { visible = !visible }
    function hide()   { visible = false }

    function showAt(anchor) {
        const pos = anchor.mapToGlobal(0, anchor.height)
        offsetX = pos.x - 300 + anchor.width
        offsetY = pos.y - 20
        visible = true
    }

    anchors { top: true; left: true; right: true; bottom: true }

    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
    }

    property int offsetX: 800
    property int offsetY: 44

    Rectangle {
        x: offsetX
        y: offsetY
        width: 300
        height: mainCol.implicitHeight + 32
        color: c.bg0
        border { width: 1; color: c.bg3 }

        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            id: mainCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
            spacing: 16

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                SystemClock { id: clk; precision: SystemClock.Seconds }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: clk.hours.toString().padStart(2,"0") + ":" +
                          clk.minutes.toString().padStart(2,"0") + ":" +
                          clk.seconds.toString().padStart(2,"0")
                    font.pixelSize: 28
                    font.bold: true
                    font.family: "JetBrains Mono Nerd Font"
                    color: c.fg0
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 11
                    font.family: "JetBrains Mono Nerd Font"
                    color: c.fg2
                    text: {
                        clk.seconds
                        const d = new Date()
                        const days   = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
                        const months = ["January","February","March","April","May","June",
                                        "July","August","September","October","November","December"]
                        const day = d.getDate()
                        const suf = (day > 3 && day < 21) ? "th"
                                  : ({1:"st",2:"nd",3:"rd"}[day % 10] ?? "th")
                        return days[d.getDay()] + ", the " + day + suf + " of " + months[d.getMonth()]
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: c.bg3 }

            Calendar { Layout.fillWidth: true; c: root.c }

            Weather   { Layout.fillWidth: true; c: root.c; g: root.g }
        }
    }
}
