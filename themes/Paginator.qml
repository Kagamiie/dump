import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property int    currentPage
    required property int    pageCount
    required property Colors c

    signal prev()
    signal next()

    implicitHeight: 28
    visible: pageCount > 1

    Rectangle {
        anchors.fill: parent
        color: c.bg2

        RowLayout {
            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
            spacing: 0

            Text {
                text: (root.currentPage + 1) + " / " + root.pageCount
                font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                color: root.c.fg2
                Layout.fillWidth: true
            }

            Row {
                spacing: 4

                Repeater {
                    model: [
                        { text: "‹", enabled: root.currentPage > 0,
                          action: () => root.prev() },
                        { text: "›", enabled: root.currentPage < root.pageCount - 1,
                          action: () => root.next() }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        width: 22; height: 18
                        color:   navMa.containsMouse ? root.c.bg3 : "transparent"
                        border { width: 1; color: modelData.enabled ? root.c.bg3 : "transparent" }
                        opacity: modelData.enabled ? 1.0 : 0.3

                        Text {
                            anchors.centerIn: parent
                            text: modelData.text
                            font { pixelSize: 13; family: "JetBrains Mono Nerd Font" }
                            color: root.c.fg2
                        }

                        MouseArea {
                            id: navMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (modelData.enabled) modelData.action() }
                        }
                    }
                }
            }
        }
    }
}
