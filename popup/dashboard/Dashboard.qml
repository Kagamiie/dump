import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../themes/"

PanelWindow {
    id: root
    required property Colors c
    required property Glyphs g
    required property var shellRoot

    visible: false
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    anchors { top: true; left: true; right: true; bottom: true }

    function toggle() { visible = !visible }
    function show()   { visible = true }
    function hide()   { visible = false }

    function showAt(anchor) {
        const pos = anchor.mapToGlobal(0, anchor.height)
        offsetX = pos.x - 352 + anchor.width
        offsetY = pos.y - 20
        visible = true
    }

    MouseArea { anchors.fill: parent; onClicked: root.visible = false }

    property int offsetX: 800
    property int offsetY: 44
    property int activeTab: 0

    Rectangle {
        x: offsetX; y: offsetY
        width: 352
        height: mainCol.implicitHeight + 2
        color: c.bg0
        border { width: 1; color: c.bg3 }

        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            id: mainCol
            anchors { left: parent.left; right: parent.right; top: parent.top }
            spacing: 0

            UserCard { Layout.fillWidth: true; c: root.c; g: root.g }
            Rectangle { Layout.fillWidth: true; height: 1; color: c.bg3 }

            // Tab bar
            Rectangle {
                Layout.fillWidth: true
                height: 32
                color: c.bg1

                Row {
                    anchors.fill: parent

                    Repeater {
                        id: tabsRepeater
                        model: [
                            { label: "Overview", icon: root.g.utilsHamburger },
                            { label: "Wallpaper", icon: root.g.layoutFloating },
                            { label: "Schedule",  icon: root.g.layoutTile }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            width: 352 / 3
                            height: 32
                            color: root.activeTab === index ? c.bg2 : tabMa.containsMouse ? c.bg2 : "transparent"

                            Rectangle {
                                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                                height: 2
                                color: root.activeTab === index ? c.accent : "transparent"
                            }

                            // LEFT border (Overview only)
                            Rectangle {
                                visible: index === 0
                                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                                width: 1
                                color: c.bg3
                            }

                            // RIGHT border (Schedule only)
                            Rectangle {
                                visible: index === tabsRepeater.count - 1
                                anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                                width: 1
                                color: c.bg3
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.icon
                                    font { family: gwnce.name; pixelSize: 12 }
                                    color: root.activeTab === index ? c.accent : c.fg2
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.label
                                    font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                                    color: root.activeTab === index ? c.accent : c.fg2
                                }
                            }

                            MouseArea {
                                id: tabMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activeTab = index
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 32
                color: c.bg1

                // LEFT border (Overview only)
                Rectangle {
                    visible: index === 0
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: 1
                    color: c.bg3
                }

                // RIGHT border (Schedule only)
                Rectangle {
                    visible: index === tabsRepeater.count - 1
                    anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                    width: 1
                    color: c.bg3
                }

                // TOP border (all tabs)
                Rectangle {
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    height: 1
                    color: c.bg3
                }

                RowLayout {
                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                    spacing: 8

                    Text {
                        text: g.nightClear
                        font { family: gwnce.name; pixelSize: 13 }
                        color: c.fg2
                    }
                    Text {
                        text: "Do Not Disturb"
                        font { pixelSize: 11; family: "JetBrains Mono Nerd Font" }
                        color: c.fg0
                        Layout.fillWidth: true
                    }
                    Rectangle {
                        id: dndTrack
                        width: 32; height: 18; radius: 0
                        color: dndThumb.x > 4 ? c.accent : c.bg3
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Rectangle {
                            id: dndThumb
                            width: 14; height: 14; radius: 0
                            anchors.verticalCenter: parent.verticalCenter
                            x: shellRoot.dnd ? 16 : 2
                            color: c.fg3
                            Behavior on x { SmoothedAnimation { velocity: 80 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: shellRoot.dnd = !shellRoot.dnd
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: c.bg3 }

            // Tab content
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: 16
                spacing: 16
                visible: root.activeTab === 0

                NetworkPanel { Layout.fillWidth: true; c: root.c; g: root.g }
                Rectangle    { Layout.fillWidth: true; height: 1; color: c.bg3 }
                MediaPlayer  { Layout.fillWidth: true; c: root.c; g: root.g }
                AudioSliders { Layout.fillWidth: true; c: root.c; g: root.g }
                Rectangle    { Layout.fillWidth: true; height: 1; color: c.bg3 }
                Quote        { Layout.fillWidth: true; c: root.c }
            }

            WallpaperPicker {
                Layout.fillWidth: true
                Layout.margins: 16
                visible: root.activeTab === 1
                c: root.c; g: root.g
            }

            WeekSchedule {
                Layout.fillWidth: true
                Layout.margins: 16
                visible: root.activeTab === 2
                c: root.c
            }
        }
    }
}
