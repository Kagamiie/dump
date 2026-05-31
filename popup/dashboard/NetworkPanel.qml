import QtQuick
import QtQuick.Layouts
import "../../themes/"
import "../../services/"
import "./networkComp/"

Column {
    id: root
    required property Colors c
    required property Glyphs g
    spacing: 8

    property bool   showNetList:   false
    property bool   showBtList:    false
    property bool   showPassInput: false
    property string pendingSsid:   ""
    property var net: NetworkService
    property var bt:  BluetoothService

    Component.onCompleted: {
        NetworkService.refreshWifiList()
        NetworkService.refreshSaved()
    }

    Connections {
        target: NetworkService
        function onConnectionFailed(ssid) {
            pendingSsid = ssid
            if (NetworkService.savedProfiles[ssid]) {
                NetworkService.deleteProfile(NetworkService.savedProfiles[ssid])
            }
            showPassInput = true
            Qt.callLater(() => passInput.focusInput())
        }
        function onConnectionSuccess() {
            showNetList   = false
            showPassInput = false
        }
    }

    PassInput {
        id: passInput
        visible: showPassInput
        width: parent.width
        c: root.c; g: root.g
        pendingSsid: root.pendingSsid
        onConnect: (ssid, pass) => {
            if (NetworkService.savedProfiles[ssid]) {
                NetworkService.deleteProfile(NetworkService.savedProfiles[ssid])
            }
            NetworkService.connectNew(ssid, pass)
            showPassInput = false
        }
        onCancel: showPassInput = false
    }

    Row {
        width: parent.width
        spacing: 8

        Rectangle {
            width: (parent.width - 8) / 2; height: 52
            color: c.bg1
            border { width: 1; color: netMa.containsMouse || showNetList ? c.accent : c.bg3 }

            RowLayout {
                anchors { fill: parent; margins: 8 }
                spacing: 6

                Rectangle {
                    width: 28; height: 28; color: c.bg2
                    Text {
                        anchors.centerIn: parent
                        text: net.netName === "No connection" ? g.networkNone
                            : net.useWifi                    ? g.wifiHigh
                            :                                  g.wiredNormal
                        font { family: gwnce.name; pixelSize: 16 }
                        color: net.netName === "No connection" ? c.red : c.fg0
                    }
                }

                ColumnLayout {
                    spacing: 2; Layout.fillWidth: true
                    Text {
                        text: "Network"
                        font { pixelSize: 11; family: "JetBrains Mono Nerd Font" }
                        color: c.fg0
                    }
                    Text {
                        text: net.netName === "No connection" ? "No connection"
                            : net.useWifi ? (net.netSsid !== "" ? net.netSsid : net.netName)
                            : "Wired"
                        font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                        color: net.netName === "No connection" ? c.red : c.fg1
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            MouseArea {
                id: netMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    showNetList    = !showNetList
                    showBtList     = false
                    showPassInput  = false
                    if (showNetList) NetworkService.refreshWifiList()
                }
            }
        }

        Rectangle {
            width: (parent.width - 8) / 2; height: 52
            color: c.bg1
            border { width: 1; color: btMa.containsMouse || showBtList ? c.accent : c.bg3 }

            RowLayout {
                anchors { fill: parent; margins: 8 }
                spacing: 6

                Rectangle {
                    width: 28; height: 28; color: c.bg2
                    Text {
                        anchors.centerIn: parent
                        text: g.bluezOn
                        font { family: gwnce.name; pixelSize: 16 }
                        color: c.fg0
                    }
                }

                ColumnLayout {
                    spacing: 2; Layout.fillWidth: true
                    Text {
                        text: "Bluetooth"
                        font { pixelSize: 11; family: "JetBrains Mono Nerd Font" }
                        color: c.fg0
                    }
                    Text {
                        text: {
                            const connected = bt.btList.filter(d => d.connected)
                            return connected.length > 0
                                ? connected.map(d => d.name).join(", ")
                                : "No device connected"
                        }
                        font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                        color: c.fg1
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            MouseArea {
                id: btMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    showBtList    = !showBtList
                    showNetList   = false
                    showPassInput = false
                    if (showBtList) BluetoothService.refreshList()
                }
            }
        }
    }

    NetMenu {
        visible: showNetList
        width: parent.width
        c: root.c; g: root.g
        netList:       net.netList
        netSsid:       net.netSsid
        useWifi:       net.useWifi
        savedProfiles: net.savedProfiles
        onConnectSsid: ssid => {
            if (ssid.trim() === net.netSsid.trim()) { showNetList = false; return }
            pendingSsid = ssid
            if (net.savedProfiles[ssid]) {
                NetworkService.connectKnown(net.savedProfiles[ssid])
                showNetList = false
            } else {
                showPassInput = true
                showNetList   = false
                Qt.callLater(() => passInput.focusInput())
            }
        }
        onSwitchToWifi: NetworkService.switchToWifi()
        onSwitchToEth:  NetworkService.switchToEth()
    }

    BtMenu {
        visible: showBtList
        width: parent.width
        c: root.c; g: root.g
        btList:     bt.btList
        btScanList: bt.btScanList
        btScanning: bt.btScanning
        onConnectDevice:    mac => BluetoothService.connectDevice(mac)
        onDisconnectDevice: mac => BluetoothService.disconnectDevice(mac)
        onUnpair:           mac => BluetoothService.unpair(mac)
        onPair:             mac => BluetoothService.pair(mac)
        onScan:             BluetoothService.scan()
    }
}
