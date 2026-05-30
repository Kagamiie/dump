import QtQuick
import QtQuick.Layouts
import "../../themes/"

Item {
    required property var root
    implicitHeight: currentChild.height

    // Prompt state
    Rectangle {
        id: promptState
        visible: root.nixQuery.length < 2
        width: parent.width; height: 100; color: "transparent"
        ColumnLayout {
            anchors.centerIn: parent; spacing: 8
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "❄"; font { family: "JetBrains Mono Nerd Font"; pixelSize: 28 }
                color: root.c.bg3
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Type to search nixpkgs..."
                font { pixelSize: 11; family: "JetBrains Mono Nerd Font" }
                color: root.c.bg4
            }
        }
    }

    // Loading state
    Rectangle {
        id: loadingState
        visible: root.nixQuery.length >= 2 && root.nixLoading
        width: parent.width; height: 100; color: "transparent"
        ColumnLayout {
            anchors.centerIn: parent; spacing: 8
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "❄"; font { family: "JetBrains Mono Nerd Font"; pixelSize: 28 }
                color: root.c.accent
                RotationAnimation on rotation {
                    running: root.nixLoading
                    loops: Animation.Infinite
                    from: 0; to: 360; duration: 1200
                }
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Searching nixpkgs..."
                font { pixelSize: 11; family: "JetBrains Mono Nerd Font" }
                color: root.c.fg2
            }
        }
    }

    // Results list
    Flickable {
        id: resultsList
        visible: root.nixQuery.length >= 2 && !root.nixLoading && root.nixResults.length > 0
        width: parent.width
        height: Math.min(nixCol.implicitHeight, 340)
        contentHeight: nixCol.implicitHeight
        clip: true

        onContentYChanged: {}

        Connections {
            target: root
            function onNixSelectedChanged() {
                const item = nixCol.children[root.nixSelected]
                if (!item) return
                const y = item.y
                const h = item.height
                if (y < resultsList.contentY)
                    resultsList.contentY = y
                else if (y + h > resultsList.contentY + resultsList.height)
                    resultsList.contentY = y + h - resultsList.height
            }
        }

        Column {
            id: nixCol
            width: parent.width

            Repeater {
                model: root.nixResults
                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width: nixCol.width
                    height: nixItemCol.implicitHeight + 16
                    color: root.nixSelected === index ? root.c.bg2 : "transparent"
                    Behavior on color { ColorAnimation { duration: 80 } }

                    Rectangle {
                        visible: root.nixSelected === index
                        width: 2; height: parent.height
                        anchors.left: parent.left
                        color: root.c.accent
                    }
                    Rectangle {
                        visible: index > 0
                        anchors { top: parent.top; left: parent.left; right: parent.right }
                        height: 1; color: root.c.bg3; opacity: 0.4
                    }

                    ColumnLayout {
                        id: nixItemCol
                        anchors {
                            left: parent.left; right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin:  root.nixSelected === index ? 20 : 18
                            rightMargin: 18
                        }
                        spacing: 4

                        RowLayout {
                            spacing: 8
                            Text {
                                text: modelData.attr
                                font { family: "JetBrains Mono Nerd Font"; pixelSize: 13; bold: true }
                                color: root.nixSelected === index ? root.c.fg0 : root.c.fg1
                                Behavior on color { ColorAnimation { duration: 80 } }
                            }
                            Text {
                                text: modelData.version
                                font { family: "JetBrains Mono Nerd Font"; pixelSize: 10 }
                                color: root.c.accent
                            }
                            Rectangle {
                                visible: modelData.broken
                                width: brk.implicitWidth + 8; height: 15
                                color: root.c.red + "22"
                                border { width: 1; color: root.c.red + "55" }
                                Text {
                                    id: brk; anchors.centerIn: parent
                                    text: "broken"
                                    font { family: "JetBrains Mono Nerd Font"; pixelSize: 9 }
                                    color: root.c.red
                                }
                            }
                            Rectangle {
                                visible: modelData.unfree
                                width: unf.implicitWidth + 8; height: 15
                                color: root.c.bccent + "22"
                                border { width: 1; color: root.c.bccent + "55" }
                                Text {
                                    id: unf; anchors.centerIn: parent
                                    text: "unfree"
                                    font { family: "JetBrains Mono Nerd Font"; pixelSize: 9 }
                                    color: root.c.bccent
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.desc
                            font { family: "JetBrains Mono Nerd Font"; pixelSize: 10 }
                            color: root.c.fg2
                            elide: Text.ElideRight
                            wrapMode: Text.WrapAnywhere
                            maximumLineCount: 2
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.nixSelected = index
                        onClicked: logic.copyAttr(modelData.attr)
                    }
                }
            }
        }
    }

    // No results state
    Rectangle {
        id: noResultsState
        visible: root.nixQuery.length >= 2 && !root.nixLoading && root.nixResults.length === 0 && root.nixStatus !== ""
        width: parent.width; height: 100; color: "transparent"
        ColumnLayout {
            anchors.centerIn: parent; spacing: 8
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "❄"; font { family: "JetBrains Mono Nerd Font"; pixelSize: 28 }
                color: root.c.bg3
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "No packages found for \"" + root.nixQuery + "\""
                font { pixelSize: 11; family: "JetBrains Mono Nerd Font" }
                color: root.c.bg4
            }
        }
    }

    readonly property var currentChild:
        root.nixResults.length > 0 ? resultsList :
        root.nixLoading             ? loadingState :
        root.nixQuery.length >= 2   ? noResultsState : promptState
}
