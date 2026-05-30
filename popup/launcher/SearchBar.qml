import QtQuick
import QtQuick.Layouts
import "../../themes/"

Rectangle {
    required property var root
    required property var panel
    height: 52
    color: "transparent"

    property alias searchInput: searchInput

    RowLayout {
        anchors { fill: parent; leftMargin: 18; rightMargin: 18 }
        spacing: 12

        Text {
            id: spinnerIcon
            text: root.nixLoading && root.mode === 1 ? "⟳" : g.utilsMagnifier
            font.family: root.nixLoading && root.mode === 1
                ? "JetBrains Mono Nerd Font" : gwnce.name
            font.pixelSize: 18
            color: searchInput.text !== "" ? root.c.accent : root.c.fg2
            Behavior on color { ColorAnimation { duration: 120 } }

            RotationAnimation on rotation {
                id: spinAnim
                running: root.nixLoading && root.mode === 1
                loops: Animation.Infinite
                from: 0; to: 360; duration: 800
                onRunningChanged: if (!running) spinnerIcon.rotation = 0
            }
        }

        TextInput {
            id: searchInput
            Layout.fillWidth: true
            verticalAlignment: TextInput.AlignVCenter
            color: root.c.fg0
            font { pixelSize: 15; family: "JetBrains Mono Nerd Font" }
            selectionColor: root.c.accent + "55"
            selectedTextColor: root.c.fg0

            onTextChanged: {
                if (root.mode === 0) root.query    = text
                else                 root.nixQuery = text
            }

            Text {
                visible: searchInput.text === ""
                text: root.mode === 0 ? "Search applications..." : "Search nixpkgs..."
                color: root.c.bg4
                font: searchInput.font
                anchors.verticalCenter: parent.verticalCenter
            }

            Keys.onEscapePressed: root.visible = false
            Keys.onTabPressed:    root.switchMode(root.mode === 0 ? 1 : 0)
            Keys.onReturnPressed: {
                if (root.mode === 0) {
                    if (root.pageItems.length > 0) {
                        const localIdx = root.selectedIndex - root.currentPage * root.perPage
                        logic.launch(root.pageItems[Math.max(0, localIdx)])
                    }
                } else {
                    if (root.nixResults.length > 0)
                        logic.copyAttr(root.nixResults[root.nixSelected].attr)
                }
            }
            Keys.onRightPressed: {
                if (root.mode === 0) root.selectIndex(root.selectedIndex + 1)
                else if (root.nixSelected < root.nixResults.length - 1) root.nixSelected++
            }
            Keys.onLeftPressed: {
                if (root.mode === 0) root.selectIndex(root.selectedIndex - 1)
                else if (root.nixSelected > 0) root.nixSelected--
            }
            Keys.onDownPressed: {
                if (root.mode === 0) root.selectIndex(root.selectedIndex + root.cols)
                else if (root.nixSelected < root.nixResults.length - 1) root.nixSelected++
            }
            Keys.onUpPressed: {
                if (root.mode === 0) root.selectIndex(root.selectedIndex - root.cols)
                else if (root.nixSelected > 0) root.nixSelected--
            }
        }

        // Mode pills
        Row {
            spacing: 6
            Repeater {
                model: [{ label: "Apps", icon: "⊞" }, { label: "Nixpkgs", icon: "❄" }]
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: pillRow.implicitWidth + 14
                    height: 22
                    color:  root.mode === index ? root.c.accent : root.c.bg2
                    border { width: 1; color: root.mode === index ? root.c.accent : root.c.bg3 }
                    Row {
                        id: pillRow
                        anchors.centerIn: parent
                        spacing: 5
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.icon
                            font { family: "JetBrains Mono Nerd Font"; pixelSize: 10 }
                            color: root.mode === index ? root.c.bg0 : root.c.fg2
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label
                            font { family: "JetBrains Mono Nerd Font"; pixelSize: 10 }
                            color: root.mode === index ? root.c.bg0 : root.c.fg2
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.switchMode(index)
                    }
                }
            }
        }

        Text {
            visible: root.mode === 0 && root.pageCount > 1
            text: (root.currentPage + 1) + " / " + root.pageCount
            font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
            color: root.c.bg4
        }
        Text {
            visible: root.mode === 0 && searchInput.text !== ""
            text: root.filtered.length + " results"
            font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
            color: root.c.bg4
        }
        Text {
            visible: root.mode === 1 && root.nixStatus !== ""
            text: root.nixStatus
            font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
            color: root.c.bg4
        }
    }
}
