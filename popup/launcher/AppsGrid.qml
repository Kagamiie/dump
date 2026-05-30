import QtQuick
import QtQuick.Layouts
import "../../themes/"

Item {
    required property var root
    required property var panel
    implicitHeight: root.filtered.length > 0
        ? grid.implicitHeight + 24
        : (root.query !== "" ? 100 : 0)

    // Grid
    Grid {
        id: grid
        visible: root.filtered.length > 0
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
        columns: root.cols
        spacing: 8

        Repeater {
            model: root.pageItems
            delegate: Rectangle {
                required property var modelData
                required property int index

                readonly property int  globalIndex: root.currentPage * root.perPage + index
                readonly property bool isSelected:  root.selectedIndex === globalIndex

                width:  (panel.width - 24 - (root.cols - 1) * 8) / root.cols
                height: 72
                color:  isSelected ? root.c.bg2 : itemMa.containsMouse ? root.c.bg1 : "transparent"
                border { width: 1; color: isSelected ? root.c.accent : root.c.bg3 }
                Behavior on color { ColorAnimation { duration: 80 } }

                ColumnLayout {
                    anchors { fill: parent; margins: 8 }
                    spacing: 6

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        width: 28; height: 28

                        Image {
                            anchors.fill: parent
                            source: modelData.icon.startsWith("/")
                                ? modelData.icon : "image://icon/" + modelData.icon
                            fillMode: Image.PreserveAspectFit
                            visible: modelData.icon !== "" && status === Image.Ready
                            smooth: true; mipmap: true
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: modelData.icon === "" || parent.children[0].status !== Image.Ready
                            text: g.utilsMagnifier
                            font { family: gwnce.name; pixelSize: 16 }
                            color: root.c.bg4
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.name
                        font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                        color: isSelected ? root.c.fg0 : root.c.fg2
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        Behavior on color { ColorAnimation { duration: 80 } }
                    }
                }

                MouseArea {
                    id: itemMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: logic.launch(modelData)
                    onEntered: root.selectedIndex = globalIndex
                }
            }
        }
    }

    // Empty state
    ColumnLayout {
        visible: root.filtered.length === 0 && root.query !== ""
        anchors.centerIn: parent
        spacing: 8
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: g.utilsMagnifier
            font { family: gwnce.name; pixelSize: 24 }
            color: root.c.bg3
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "No results for \"" + root.query + "\""
            font { pixelSize: 11; family: "JetBrains Mono Nerd Font" }
            color: root.c.bg4
        }
    }
}
