import QtQuick
import QtQuick.Layouts
import "../../../themes/"

Rectangle {
    id: root
    required property Colors c
    required property Glyphs g

    property var  btList:     []
    property var  btScanList: []
    property bool btScanning: false
    property var newDevices: []

    signal pair(string mac)
    signal unpair(string mac)
    signal connectDevice(string mac)
    signal disconnectDevice(string mac)
    signal scan()

    property int pageSize:      8
    property int pairedPage:    0
    property int scanPage:      0

    property var pagedPaired: {
        const start = pairedPage * pageSize
        return btList.slice(start, start + pageSize)
    }
    property var pagedScan: {
        const start = scanPage * pageSize
        return newDevices.slice(start, start + pageSize)
    }

    property int pairedPageCount: Math.ceil(btList.length / pageSize)
    property int scanPageCount:   Math.ceil(newDevices.length / pageSize)

    onBtScanListChanged: updateNewDevices()
    onBtListChanged:     updateNewDevices()

    function updateNewDevices() {
        newDevices = btScanList.filter(d => !btList.some(b => b.mac === d.mac) && !d.paired)
        scanPage = 0
    }

    height: visible ? btListCol.implicitHeight : 0
    color: c.bg1
    border { width: 1; color: c.bg3 }
    clip: true

    Column {
        id: btListCol
        width: parent.width

        Rectangle {
            width: parent.width
            height: 28
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
                anchors { fill: parent; leftMargin: 12; rightMargin: 8 }
                spacing: 6

                Text {
                    text: "Paired devices"
                    font { pixelSize: 10; bold: true; family: "JetBrains Mono Nerd Font" }
                    color: c.fg2
                    Layout.fillWidth: true
                }

                BtButton {
                    c: root.c
                    label: root.btScanning ? "Scanning..." : "Scan"
                    onClicked: { if (!root.btScanning) root.scan() }
                }
            }
        }

        Text {
            visible: root.btList.length === 0
            width: parent.width
            height: 32
            text: "No paired devices"
            font { pixelSize: 11; family: "JetBrains Mono Nerd Font" }
            color: c.fg2
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Repeater {
            model: root.pagedPaired
            delegate: Rectangle {
                required property var modelData
                required property int index

                property bool rowHovered: false

                width: parent.width
                height: 32
                color: rowHovered ? c.bg2 : "transparent"

                Rectangle { width: 1; height: parent.height; color: c.bg3; anchors.left: parent.left }
                Rectangle { width: 1; height: parent.height; color: c.bg3; anchors.right: parent.right }

                HoverHandler { onHoveredChanged: rowHovered = hovered }

                Rectangle {
                    visible: index > 0
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: 1; color: c.bg3; opacity: 0.4
                }

                MouseArea {
                    id: delegateMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.connected) root.disconnectDevice(modelData.mac)
                        else root.connectDevice(modelData.mac)
                    }
                }

                RowLayout {
                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                    spacing: 8

                    Text {
                        text: g.bluezOn
                        font { family: gwnce.name; pixelSize: 13 }
                        color: modelData.connected ? c.accent : c.fg2
                    }

                    Text {
                        text: modelData.name
                        font { pixelSize: 11; family: "JetBrains Mono Nerd Font" }
                        color: modelData.connected ? c.accent : c.fg0
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        visible: rowHovered
                        width: 18; height: 18
                        color: unpairMa.containsMouse ? c.bg2 : "transparent"
                        border { width: 1; color: unpairMa.containsMouse ? c.red : c.bg3 }

                        Text {
                            anchors.centerIn: parent
                            text: g.titleClose
                            font { family: gwnce.name; pixelSize: 10 }
                            color: unpairMa.containsMouse ? c.red : c.fg2
                        }

                        MouseArea {
                            id: unpairMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.unpair(modelData.mac)
                        }
                    }

                    Text {
                        text: modelData.connected ? "✓" : "○"
                        font { pixelSize: 11; family: "JetBrains Mono Nerd Font" }
                        color: modelData.connected ? c.accent : c.fg2
                    }
                }
            }
        }

        Rectangle {
            visible: root.pairedPageCount > 1
            width: parent.width
            height: 28
            color: c.bg2

            RowLayout {
                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }

                Text {
                    text: (root.pairedPage + 1) + " / " + root.pairedPageCount
                    font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                    color: c.fg2
                    Layout.fillWidth: true
                }

                Row {
                    spacing: 4

                    Rectangle {
                        width: 22; height: 18
                        color: prevPairedMa.containsMouse ? c.bg3 : "transparent"
                        border { width: 1; color: root.pairedPage > 0 ? c.bg3 : "transparent" }
                        opacity: root.pairedPage > 0 ? 1 : 0.3

                        Text {
                            anchors.centerIn: parent
                            text: "‹"
                            font { pixelSize: 13; family: "JetBrains Mono Nerd Font" }
                            color: c.fg2
                        }

                        MouseArea {
                            id: prevPairedMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (root.pairedPage > 0) root.pairedPage-- }
                        }
                    }

                    Rectangle {
                        width: 22; height: 18
                        color: nextPairedMa.containsMouse ? c.bg3 : "transparent"
                        border { width: 1; color: root.pairedPage < root.pairedPageCount - 1 ? c.bg3 : "transparent" }
                        opacity: root.pairedPage < root.pairedPageCount - 1 ? 1 : 0.3

                        Text {
                            anchors.centerIn: parent
                            text: "›"
                            font { pixelSize: 13; family: "JetBrains Mono Nerd Font" }
                            color: c.fg2
                        }

                        MouseArea {
                            id: nextPairedMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (root.pairedPage < root.pairedPageCount - 1) root.pairedPage++ }
                        }
                    }
                }
            }
        }

        Rectangle {
            visible: root.newDevices.length > 0
            width: parent.width
            height: 24
            color: c.bg2

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

            Text {
                anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 12 }
                text: "New devices"
                font { pixelSize: 10; bold: true; family: "JetBrains Mono Nerd Font" }
                color: c.fg2
            }
        }

        Repeater {
            model: root.pagedScan
            delegate: Rectangle {
                required property var modelData
                required property int index

                width: parent.width
                height: 32
                color: newItemMa.containsMouse ? c.bg2 : "transparent"

                Rectangle {
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: 1; color: c.bg3; opacity: 0.4
                }

                RowLayout {
                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                    spacing: 8

                    Text {
                        text: g.bluezScanning
                        font { family: gwnce.name; pixelSize: 13 }
                        color: c.fg2
                    }

                    Text {
                        text: modelData.name
                        font { pixelSize: 11; family: "JetBrains Mono Nerd Font" }
                        color: modelData.connected ? c.accent : c.fg0
                        Layout.fillWidth: true
                        elide: Text.ElideRight

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.connected) root.disconnectDevice(modelData.mac)
                                else root.connectDevice(modelData.mac)
                            }
                        }
                    }

                    BtButton { c: root.c; label: "Pair"; onClicked: root.pair(modelData.mac) }
                }

                MouseArea {
                    id: newItemMa
                    anchors.fill: parent
                    hoverEnabled: true
                    propagateComposedEvents: true
                    onClicked: mouse => mouse.accepted = false
                }
            }
        }

        Rectangle {
            visible: root.scanPageCount > 1
            width: parent.width
            height: 28
            color: c.bg2

            RowLayout {
                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }

                Text {
                    text: (root.scanPage + 1) + " / " + root.scanPageCount
                    font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                    color: c.fg2
                    Layout.fillWidth: true
                }

                Row {
                    spacing: 4

                    Rectangle {
                        width: 22; height: 18
                        color: prevScanMa.containsMouse ? c.bg3 : "transparent"
                        border { width: 1; color: root.scanPage > 0 ? c.bg3 : "transparent" }
                        opacity: root.scanPage > 0 ? 1 : 0.3

                        Text {
                            anchors.centerIn: parent
                            text: "‹"
                            font { pixelSize: 13; family: "JetBrains Mono Nerd Font" }
                            color: c.fg2
                        }

                        MouseArea {
                            id: prevScanMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (root.scanPage > 0) root.scanPage-- }
                        }
                    }

                    Rectangle {
                        width: 22; height: 18
                        color: nextScanMa.containsMouse ? c.bg3 : "transparent"
                        border { width: 1; color: root.scanPage < root.scanPageCount - 1 ? c.bg3 : "transparent" }
                        opacity: root.scanPage < root.scanPageCount - 1 ? 1 : 0.3

                        Text {
                            anchors.centerIn: parent
                            text: "›"
                            font { pixelSize: 13; family: "JetBrains Mono Nerd Font" }
                            color: c.fg2
                        }

                        MouseArea {
                            id: nextScanMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (root.scanPage < root.scanPageCount - 1) root.scanPage++ }
                        }
                    }
                }
            }
        }
    }
}
