import QtQuick
import QtQuick.Layouts
import "../../../themes/"

Rectangle {
    id: root

    required property Colors c
    required property Glyphs g

    property var    netList:      []
    property string netSsid:      ""
    property bool   useWifi:      true
    property var    savedProfiles: ({})

    signal connectSsid(string ssid)
    signal switchToWifi()
    signal switchToEth()

    property int pageSize: 8
    property int netPage:  0

    property var pagedNetList: {
        const start = netPage * pageSize
        return netList.slice(start, start + pageSize)
    }
    property int netPageCount: Math.ceil(netList.length / pageSize)

    onNetListChanged: netPage = 0

    height: visible ? netMenuCol.implicitHeight  : 0
    color:  c.bg1
    border { width: 1; color: c.bg3 }
    clip: true

    Column {
        id: netMenuCol
        width: parent.width

        Rectangle {
            width: parent.width
            height: 34
            color: c.bg2

            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 1
                color: c.bg3
            }
            Rectangle {
                anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
                width: 1
                color: c.bg3
            }
            Rectangle {
                anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
                width: 1
                color: c.bg3
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                spacing: 8

                Text {
                    text: "Connection type"
                    font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                    color: c.fg2
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 84; height: 22
                    color: c.bg0
                    border { width: 1; color: c.bg3 }

                    Row {
                        anchors.fill: parent

                        Repeater {
                            model: [
                                { label: "WiFi", icon: g.wifiHigh,    active: root.useWifi  },
                                { label: "ETH",  icon: g.wiredNormal, active: !root.useWifi }
                            ]
                            delegate: Row {
                                required property var modelData
                                required property int index

                                Rectangle {
                                    visible: index === 1
                                    width: 1; height: 22
                                    color: c.bg3
                                }

                                Rectangle {
                                    width: index === 0 ? 42 : 41
                                    height: 22
                                    color: modelData.active ? c.accent : "transparent"

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.icon
                                            font { family: gwnce.name; pixelSize: 11 }
                                            color: modelData.active ? c.bg0 : c.fg2
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.label
                                            font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                                            color: modelData.active ? c.bg0 : c.fg2
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (index === 0 && !root.useWifi) root.switchToWifi()
                                            if (index === 1 &&  root.useWifi) root.switchToEth()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Repeater {
            model: root.useWifi ? root.pagedNetList : []
            delegate: Rectangle {
                required property var modelData
                required property int index

                width: parent.width
                height: 32
                clip: true

                Rectangle { width: 1; height: parent.height; color: c.bg3; anchors.left: parent.left }
                Rectangle { width: 1; height: parent.height; color: c.bg3; anchors.right: parent.right }

                color: netItemMa.containsMouse || modelData.ssid.trim() === root.netSsid.trim() ? c.bg2 : "transparent"

                Rectangle {
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: 1; color: c.bg3; opacity: 0.4
                }

                RowLayout {
                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                    spacing: 8

                    Text {
                        text: modelData.signal > 66 ? g.wifiHigh
                            : modelData.signal > 33 ? g.wifiNormal : g.wifiLow
                        font { family: gwnce.name; pixelSize: 13 }
                        color: modelData.ssid.trim() === root.netSsid.trim() ? c.accent : c.fg2
                    }
                    Text {
                        text: modelData.ssid
                        font { pixelSize: 11; family: "JetBrains Mono Nerd Font" }
                        color: modelData.ssid.trim() === root.netSsid.trim() ? c.accent : c.fg0
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: root.savedProfiles[modelData.ssid] ? "★" : ""
                        font.pixelSize: 10
                        color: c.accent
                    }
                    Text {
                        text: modelData.signal + "%"
                        font { pixelSize: 9; family: "JetBrains Mono Nerd Font" }
                        color: c.fg2
                    }
                    Text {
                        visible: modelData.ssid.trim() === root.netSsid.trim()
                        text: "✓"
                        font { pixelSize: 11; family: "JetBrains Mono Nerd Font" }
                        color: c.accent
                    }
                }

                MouseArea {
                    id: netItemMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.connectSsid(modelData.ssid)
                }
            }
        }

        Rectangle {
            visible: root.useWifi && root.netPageCount > 1
            width: parent.width
            height: 32
            color: c.bg2

            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 1
                color: c.bg3
            }
            Rectangle {
                anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
                width: 1
                color: c.bg3
            }
            Rectangle {
                anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
                width: 1
                color: c.bg3
            }

            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 1
                color: c.bg3
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }

                Text {
                    text: (root.netPage + 1) + " / " + root.netPageCount
                    font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                    color: c.fg2
                    Layout.fillWidth: true
                }

                Row {
                    spacing: 4

                    Rectangle {
                        width: 22; height: 18
                        color: prevNetMa.containsMouse ? c.bg3 : "transparent"

                        border { width: 1; color: root.netPage > 0 ? c.bg3 : "transparent" }
                        opacity: root.netPage > 0 ? 1 : 0.3

                        Text {
                            anchors.centerIn: parent
                            text: "‹"
                            font { pixelSize: 13; family: "JetBrains Mono Nerd Font" }
                            color: c.fg2
                        }

                        MouseArea {
                            id: prevNetMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (root.netPage > 0) root.netPage-- }
                        }
                    }

                    Rectangle {
                        width: 22; height: 18
                        color: nextNetMa.containsMouse ? c.bg3 : "transparent"
                        border { width: 1; color: root.netPage < root.netPageCount - 1 ? c.bg3 : "transparent" }
                        opacity: root.netPage < root.netPageCount - 1 ? 1 : 0.3

                        Text {
                            anchors.centerIn: parent
                            text: "›"
                            font { pixelSize: 13; family: "JetBrains Mono Nerd Font" }
                            color: c.fg2
                        }

                        MouseArea {
                            id: nextNetMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (root.netPage < root.netPageCount - 1) root.netPage++ }
                        }
                    }
                }
            }
        }

        Rectangle {
            visible: !root.useWifi
            width: parent.width
            height: 32
            color: "transparent"

            Text {
                anchors.centerIn: parent
                text: "Ethernet active — WiFi disabled"
                font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                color: c.fg2
            }
        }
    }
}
