import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../ipc/"
import "../themes/"

Item {
    id: bar
    required property var screen
    required property var appLauncher
    required property Colors c
    required property Glyphs g

    anchors.fill: parent

    Niri { id: ipc; screen: bar.screen }

    property string avatarSource: "file://" + Config.avatarPath

    Rectangle { anchors.fill: parent; color: c.bg0 }
    Rectangle {
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        height: 1; color: c.bg3; z: 10
    }

    RowLayout {
        anchors { fill: parent; leftMargin: 16; rightMargin: 16; bottomMargin: 2 }
        spacing: 0

        RowLayout {
            spacing: 0
            Layout.fillWidth: false
            Workspaces { screen: bar.screen; c: bar.c; ipc: ipc }
            Item { width: 8 }

            SearchBtn { c: bar.c; g: bar.g; launcher: bar.appLauncher }
            Item { width: 8 }
        }

        Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: c.bg3 }

        Item {
            Layout.fillWidth: true
            height: parent.height
            Rectangle { anchors.fill: parent; color: c.bg1 + "80" }
            Windows {
                anchors {
                    fill: parent
                    leftMargin: 9
                    rightMargin: 9
                }
                c: bar.c
                ipc: ipc
            }
        }

        Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: c.bg3 }

        RowLayout {
            spacing: 12
            Layout.fillWidth: false
            Layout.leftMargin: 12

            SystrayBtn   { c: bar.c; g: bar.g }
            Keyboard     { c: bar.c }
            StatusWidget { c: bar.c; g: bar.g }
            Clock        { c: bar.c; g: bar.g }

            Rectangle {
                width: 23; height: 23
                Layout.alignment: Qt.AlignVCenter
                clip: true
                Image {
                    anchors.fill: parent
                    source: bar.avatarSource
                    fillMode: Image.PreserveAspectCrop
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const wasVisible = dashboard.visible
                        rightPanels.closeAll()
                        if (!wasVisible) dashboard.showAt(parent)
                    }
                }
            }
        }
    }
}
