import QtQuick
import QtQuick.Layouts
import "../../themes/"

Item {
    id: root
    required property Colors c

    required property string notifSummary
    required property string notifBody
    required property string notifAppName
    required property string notifAppIcon
    required property real notifTimeout
    required property var notifActions
    required property string notifImage

    property int stackIndex: 0
    signal dismissed

    implicitWidth: 320
    implicitHeight: card.implicitHeight

    property bool hovered: false
    required property int notifCount

    function resetTimer() {
        progressAnim.stop()
        progressFill.width = 0
        progressAnim.start()
    }

    NumberAnimation {
        id: progressAnim
        target: progressFill
        property: "width"
        from: 0
        to: progressBar.width
        duration: notifTimeout * 1000
        running: true
        onFinished: root.dismissed()
    }

    onHoveredChanged: hovered ? progressAnim.pause() : progressAnim.resume()

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited:  root.hovered = false
        onClicked: root.dismissed()
        propagateComposedEvents: true
    }

    Rectangle {
        id: card
        width: 320
        implicitWidth: 320
        implicitHeight: mainCol.implicitHeight
        color: c.bg0
        border.width: 1
        border.color: c.bg3

        ColumnLayout {
            id: mainCol
            width: 320
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Item {
                    width: 60
                    height: 60

                    Image {
                        anchors.centerIn: parent
                        width: 36; height: 36
                        source: {
                            if (notifImage !== "")
                                return notifImage
                            if (notifAppIcon.startsWith("file://"))
                                return decodeURIComponent(notifAppIcon)
                            if (notifAppIcon !== "")
                                return "image://icon/" + notifAppIcon.toLowerCase()
                            return ""
                        }
                        visible: notifImage !== "" || notifAppIcon !== ""
                        fillMode: Image.PreserveAspectFit
                    }

                    Image {
                        anchors.centerIn: parent
                        width: 32; height: 32
                        source: Qt.resolvedUrl("../../assets/notif/default.png")
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                        visible: notifImage === "" && notifAppIcon === ""
                    }

                    Rectangle {
                        visible: notifCount > 1
                        anchors { right: parent.right; bottom: parent.bottom; rightMargin: 4; bottomMargin: 4 }
                        width: 18; height: 18
                        radius: 9
                        color: c.accent

                        Text {
                            anchors.centerIn: parent
                            text: notifCount > 9 ? "9+" : notifCount
                            font.pixelSize: 9
                            font.bold: true
                            font.family: "JetBrains Mono Nerd Font"
                            color: c.bg0
                        }
                    }
                }

                Rectangle {
                    width: 1
                    Layout.fillHeight: true
                    color: c.bg3
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        height: 32
                        color: c.bg1

                        Rectangle {
                            anchors { top: parent.top; left: parent.left; right: parent.right }
                            height: 1
                            color: c.bg3
                        }
                        Rectangle {
                            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                            width: 1
                            color: c.bg3
                        }

                        Text {
                            anchors.centerIn: parent
                            width: parent.width - 16
                            text: notifSummary !== "" ? notifSummary : notifAppName
                            font.pixelSize: 11
                            font.family: "JetBrains Mono Nerd Font"
                            font.italic: true
                            color: c.fg0
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 1
                            color: c.bg3
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.margins: 10
                        text: notifBody
                        font.pixelSize: 11
                        font.family: "JetBrains Mono Nerd Font"
                        color: c.fg1
                        wrapMode: Text.WrapAnywhere
                        visible: notifBody !== ""
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        visible: notifActions.length > 0

                        Rectangle { Layout.fillWidth: true; height: 1; color: c.bg3 }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Repeater {
                                model: notifActions
                                delegate: Rectangle {
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    height: 26
                                    color: actMa.containsMouse ? c.bg2 : "transparent"

                                    Rectangle {
                                        visible: index > 0
                                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                                        width: 1
                                        color: c.bg3
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.text
                                        font.pixelSize: 10
                                        font.family: "JetBrains Mono Nerd Font"
                                        color: actMa.containsMouse ? c.accent : c.fg2
                                    }

                                    MouseArea {
                                        id: actMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: { modelData.invoke(); root.dismissed() }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: progressBar
                        Layout.fillWidth: true
                        height: 3
                        color: c.bg1

                        Rectangle {
                            id: progressFill
                            height: parent.height
                            width: 0
                            color: c.accent
                        }
                    }
                }
            }
        }
    }
}
