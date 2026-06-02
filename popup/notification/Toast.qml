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
    required property real   notifTimeout
    required property var    notifActions
    required property string notifImage
    required property int    notifCount

    signal dismissed

    implicitWidth:  320
    implicitHeight: card.implicitHeight

    property bool _hovered:    false
    property bool _dismissing: false

    function _dismiss() {
        if (_dismissing) return
        _dismissing = true

        progressAnim.stop()
        progressFill.width = 0

        dismissed()
    }

    function resetTimer() {
        progressAnim.stop()
        progressFill.width = 0
        progressAnim.start()
    }

    Component.onCompleted: {
        progressAnim.start()
    }

    NumberAnimation {
        id: progressAnim
        target: progressFill
        property: "width"
        from: 0
        to: 320
        duration: notifTimeout * 1000
        running: false
        onFinished: {
            if (!root._dismissing) {
                root._dismiss()
            }
        }
    }

    on_HoveredChanged: _hovered ? progressAnim.pause() : progressAnim.resume()

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root._hovered = true
        onExited:  root._hovered = false
        onClicked: {
            if (!root._dismissing) {
                root._dismiss()
            }
        }
        propagateComposedEvents: true
    }

    Rectangle {
        id: card
        width: 320
        implicitWidth:  320
        implicitHeight: mainCol.implicitHeight
        color:        root.c ? root.c.bg0 : "#1b1b1b"
        border.width: 1
        border.color: root.c ? root.c.bg3 : "#3c3c3c"

        ColumnLayout {
            id: mainCol
            width: 320
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Item {
                    width: 60; height: 60

                    Image {
                        anchors.centerIn: parent
                        width: 36; height: 36
                        source: {
                            let imageSource = ""

                            if (root.notifImage.startsWith("https://")) {
                                imageSource = root.notifImage
                            }

                            else if (root.notifAppIcon.startsWith("/usr/share/icons/") ||
                                     root.notifAppIcon.startsWith("/usr/share/pixmaps/")) {
                                imageSource = "file://" + root.notifAppIcon
                            }

                            else if (root.notifAppIcon && !root.notifAppIcon.startsWith("/")) {
                                imageSource = "image://icon/" + root.notifAppIcon.toLowerCase()
                            }

                            return imageSource
                        }
                        visible: source !== ""
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }

                    Image {
                        anchors.centerIn: parent
                        width: 32; height: 32
                        source: Qt.resolvedUrl("../../assets/notif/default.png")
                        fillMode: Image.PreserveAspectFit
                        smooth: true; mipmap: true
                        visible: parent.children[0].source === ""
                    }

                    Rectangle {
                        visible: notifCount > 1
                        anchors { right: parent.right; bottom: parent.bottom; rightMargin: 4; bottomMargin: 4 }
                        width: 18; height: 18; radius: 9
                        color: root.c ? root.c.accent : "#a588d0"

                        Text {
                            anchors.centerIn: parent
                            text: notifCount > 9 ? "9+" : notifCount
                            font { pixelSize: 9; bold: true; family: "JetBrains Mono Nerd Font" }
                            color: root.c ? root.c.bg0 : "#1b1b1b"
                        }
                    }
                }

                Rectangle {
                    width: 1
                    Layout.fillHeight: true
                    color: root.c ? root.c.bg3 : "#3c3c3c"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        height: 32
                        color: root.c ? root.c.bg1 : "#222222"

                        Rectangle {
                            anchors { top: parent.top; left: parent.left; right: parent.right }
                            height: 1
                            color: root.c ? root.c.bg3 : "#3c3c3c"
                        }
                        Rectangle {
                            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                            width: 1
                            color: root.c ? root.c.bg3 : "#3c3c3c"
                        }

                        Text {
                            anchors.centerIn: parent
                            width: parent.width - 16
                            text: notifSummary !== "" ? notifSummary : notifAppName
                            font { pixelSize: 11; family: "JetBrains Mono Nerd Font"; italic: true }
                            color: root.c ? root.c.fg0 : "#eeeeee"
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width; height: 1
                            color: root.c ? root.c.bg3 : "#3c3c3c"
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.margins: 10
                        text: notifBody.length > 500 ? notifBody.substring(0, 500) + "..." : notifBody
                        font { pixelSize: 11; family: "JetBrains Mono Nerd Font" }
                        color: root.c ? root.c.fg1 : "#d4d4d4"
                        wrapMode: Text.WrapAnywhere
                        visible: notifBody !== ""
                        maximumLineCount: 5
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        visible: notifActions.length > 0

                        Rectangle {
                            Layout.fillWidth: true; height: 1
                            color: root.c ? root.c.bg3 : "#3c3c3c"
                        }

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
                                    color: actMa.containsMouse
                                        ? (root.c ? root.c.bg2 : "#2e2e2e")
                                        : "transparent"

                                    Rectangle {
                                        visible: index > 0
                                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                                        width: 1
                                        color: root.c ? root.c.bg3 : "#3c3c3c"
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.text
                                        font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                                        color: actMa.containsMouse
                                            ? (root.c ? root.c.accent : "#a588d0")
                                            : (root.c ? root.c.fg2   : "#ababab")
                                    }

                                    MouseArea {
                                        id: actMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (!root._dismissing) {
                                                modelData.invoke()
                                                root._dismiss()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: progressBar
                        Layout.fillWidth: true
                        height: 3
                        color: root.c ? root.c.bg1 : "#222222"

                        Rectangle {
                            id: progressFill
                            height: parent.height
                            width: 0
                            color: root.c ? root.c.accent : "#a588d0"
                        }
                    }
                }
            }
        }
    }
}
