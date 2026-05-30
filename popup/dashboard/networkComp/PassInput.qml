import QtQuick
import QtQuick.Layouts
import "../../../themes/"

Rectangle {
    id: root
    required property Colors c
    required property Glyphs g

    property string pendingSsid: ""

    signal connect(string ssid, string password)
    signal cancel()

    height: 40
    color: c.bg1
    border.width: 1
    border.color: c.accent

    function focusInput() { passInput.forceActiveFocus() }

    RowLayout {
        anchors { fill: parent; margins: 8 }
        spacing: 8

        Text {
            text: g.wifiHigh
            font.family: gwnce.name
            font.pixelSize: 13
            color: c.fg2
        }

        Rectangle {
            Layout.fillWidth: true
            height: 24
            color: c.bg2
            border.width: 1
            border.color: passInput.activeFocus ? c.accent : c.bg3

            TextInput {
                id: passInput
                anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                verticalAlignment: TextInput.AlignVCenter
                font.pixelSize: 11
                font.family: "JetBrains Mono Nerd Font"
                color: c.fg0
                echoMode: TextInput.Password
                clip: true

                Text {
                    visible: passInput.text === ""
                    text: "Password for '" + root.pendingSsid + "'"
                    color: c.fg2
                    font: passInput.font
                    anchors.verticalCenter: parent.verticalCenter
                }

                Keys.onReturnPressed: {
                    if (text !== "") {
                        root.connect(root.pendingSsid, text)
                        text = ""
                    }
                }
                Keys.onEscapePressed: {
                    text = ""
                    root.cancel()
                }
            }
        }

        Rectangle {
            width: 24; height: 24
            color: connBtn.containsMouse ? c.accent : c.bg2
            border.width: 1
            border.color: c.bg3

            Text {
                anchors.centerIn: parent
                text: g.arrowRight
                font.family: gwnce.name
                font.pixelSize: 12
                color: c.fg0
            }

            MouseArea {
                id: connBtn
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (passInput.text !== "") {
                        root.connect(root.pendingSsid, passInput.text)
                        passInput.text = ""
                    }
                }
            }
        }
    }
}
