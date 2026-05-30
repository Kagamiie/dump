import QtQuick
import QtQuick.Layouts
import "../../themes/"

Rectangle {
    required property var root
    height: 34
    color: root.c.bg1

    RowLayout {
        anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
        spacing: 0

        Row {
            spacing: 14
            Repeater {
                model: root.mode === 0
                    ? [{ key: "↵", label: "launch" }, { key: "↑↓←→", label: "navigate" },
                       { key: "Tab", label: "nixpkgs" }, { key: "Esc", label: "close" }]
                    : [{ key: "↵", label: "copy attr" }, { key: "↑↓", label: "navigate" },
                       { key: "Tab", label: "apps" }, { key: "Esc", label: "close" }]
                delegate: Row {
                    required property var modelData
                    spacing: 5
                    Rectangle {
                        width: kLbl.implicitWidth + 8; height: 16; radius: 2
                        color: root.c.bg2
                        border { width: 1; color: root.c.bg3 }
                        Text {
                            id: kLbl
                            anchors.centerIn: parent
                            text: modelData.key
                            font { pixelSize: 9; family: "JetBrains Mono Nerd Font" }
                            color: root.c.fg2
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label
                        font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                        color: root.c.bg4
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        Row {
            visible: root.mode === 0 && root.pageCount > 1
            spacing: 5
            Repeater {
                model: root.pageCount
                delegate: Rectangle {
                    required property int index
                    width:  root.currentPage === index ? 16 : 6
                    height: 6; radius: 3
                    color:  root.currentPage === index ? root.c.accent : root.c.bg3
                    Behavior on width { SmoothedAnimation { velocity: 60 } }
                    Behavior on color { ColorAnimation { duration: 120 } }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.currentPage = index
                            root.selectedIndex = index * root.perPage
                        }
                    }
                }
            }
        }

        Item { width: 8 }

        Text {
            text: root.mode === 0 ? root.apps.length + " apps" : "nixos unstable"
            font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
            color: root.c.bg4
        }
    }
}
