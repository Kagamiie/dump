import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../themes/"
import "./networkComp/"

Column {
    id: root
    required property Colors c
    required property Glyphs g
    spacing: 8

    property string netIcon:       g.networkNone
    property string netName:       "No connection"
    property bool   showNetList:   false
    property bool   showBtList:    false
    property var    netList:       []
    property var    btList:        []
    property string pendingSsid:   ""
    property bool   showPassInput: false
    property var    savedProfiles: ({})
    property string netSsid:       ""
    property bool   useWifi:       false
    property bool   btScanning:    false
    property var    btScanList:    []
    property string wifiIface:     ""
    property string ethIface:      ""

    Process {
        id: btConnectProc
        property string mac: ""
        command: ["bluetoothctl", "connect", mac]
        onExited: Qt.callLater(() => {
            Qt.createQmlObject(`import QtQuick
                Timer { interval: 1500; running: true; repeat: false; onTriggered: btListProc.running = true }
            `, root)
        })
    }

    Process {
        id: btDisconnectProc
        property string mac: ""
        command: ["bluetoothctl", "disconnect", mac]
        onExited: { btListProc.running = true }
    }

    Process {
        id: btUnpairProc
        property string mac: ""
        command: ["bluetoothctl", "remove", mac]
        onExited: { btListProc.running = true }
    }

    Process {
        id: btPairProc
        property string mac: ""
        command: ["sh", "-c", "bluetoothctl pair " + mac + " && bluetoothctl connect " + mac]
        onExited: { btListProc.running = true }
    }

    Timer { interval: 20000; repeat: true; running: true; triggeredOnStart: true
            onTriggered: { netProc.running = true; ssidProc.running = true } }

    // Ajouter juste après ce Timer :
    Process {
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                if (!line.trim()) return
                netProc.running  = true
                ssidProc.running = true
                if (line.includes("wifi") || line.includes("wireless"))
                    wifiListProc.running = true
            }
        }
    }

    Timer { interval: 10000; repeat: true; running: true; triggeredOnStart: true
            onTriggered: btListProc.running = true }

    Component.onCompleted: { ifaceProc.running = true; savedProc.running = true; btListProc.running = true }

    Process {
        id: ifaceProc
        command: ["sh", "-c",
            "nmcli -t -f DEVICE,TYPE device | awk -F: '$2==\"wifi\"{print $1}' | head -1; " +
            "nmcli -t -f DEVICE,TYPE device | awk -F: '$2==\"ethernet\"{print $1}' | head -1"
        ]
        stdout: SplitParser {
            splitMarker: "\n"
            property int lineN: 0
            onRead: line => {
                if (lineN === 0) wifiIface = line.trim()
                else             ethIface  = line.trim()
                lineN++
            }
        }
        onRunningChanged: { if (running) stdout.lineN = 0 }
    }

    Process {
        id: ssidProc
        command: ["sh", "-c", "iwgetid -r 2>/dev/null || nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2"]
        stdout: StdioCollector {
            onStreamFinished: netSsid = this.text.trim()
        }
    }

    Process {
        id: savedProc
        command: ["bash", "-c",
            "nmcli -t -f NAME,TYPE connection show | grep ':802-11-wireless$' | cut -d: -f1 | " +
            "while read name; do " +
            "  ssid=$(nmcli -g 802-11-wireless.ssid connection show \"$name\" 2>/dev/null); " +
            "  echo \"$ssid:$name\"; " +
            "done"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                const parts = line.trim().split(":")
                if (parts.length >= 2 && parts[0].trim())
                    savedProfiles[parts[0].trim()] = parts[1].trim()
            }
        }
    }

    Process {
        id: netProc
        command: ["sh", "-c", "ip route get 1.1.1.1 2>/dev/null | grep -oP 'dev \\K\\S+' | head -1"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                const iface = line.trim()
                if (!iface) { netIcon = g.networkNone; netName = "No connection"; return }
                if (iface.startsWith("w")) { netIcon = g.wifiHigh;    netName = iface; useWifi = true  }
                else                       { netIcon = g.wiredNormal; netName = iface; useWifi = false }
            }
        }
    }

    Process {
        id: wifiListProc
        command: ["sh", "-c", "nmcli -t -f SSID,SIGNAL,ACTIVE dev wifi list 2>/dev/null"]
        stdout: SplitParser {
            splitMarker: "\n"
            property var buf: ({})
            onRead: line => {
                const parts  = line.split(":")
                if (parts.length < 3) return
                const ssid   = parts[0].trim()
                const signal = parseInt(parts[1]) || 0
                const active = parts[2].trim() === "yes"
                if (!ssid) return
                if (!buf[ssid] || signal > buf[ssid].signal)
                    buf[ssid] = { ssid, signal, active }
            }
        }
        onRunningChanged: {
            if (running) {
                stdout.buf = ({})
            } else {
                const arr = Object.values(stdout.buf)
                arr.sort((a, b) => a.active ? -1 : b.active ? 1 : b.signal - a.signal)
                netList = arr
            }
        }
    }

    Process {
        id: btListProc
        command: ["bash", "-c", `
            connected_macs=$(bluetoothctl devices Connected 2>/dev/null | awk '{print $2}')
            bluetoothctl devices Paired 2>/dev/null | while read _ mac rest; do
                name=$(bluetoothctl info "$mac" 2>/dev/null | grep "Name:" | sed 's/.*Name: //')
                [ -z "$name" ] && continue
                is_connected=0
                echo "$connected_macs" | grep -q "$mac" && is_connected=1
                echo "$mac|$name|$is_connected"
            done
        `]
        stdout: SplitParser {
            splitMarker: "\n"
            property var buf: []
            onRead: line => {
                const parts = line.trim().split("|")
                const name  = parts.length >= 3 ? parts[1].trim() : ""
                if (name) buf.push({ mac: parts[0].trim(), name, connected: parts[2].trim() === "1" })
            }
        }
        onRunningChanged: {
            if (running) {
                stdout.buf = []
            } else {
                btList = stdout.buf.slice()
            }
        }
    }

    Process {
        id: connectProc
        property string cmd: ""
        command: ["sh", "-c", cmd]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                if (line.startsWith("EXIT:") && line.trim() !== "EXIT:0") {
                    if (savedProfiles[pendingSsid]) {
                        deleteProc.cmd = "nmcli connection delete '" + savedProfiles[pendingSsid] + "'"
                        deleteProc.running = true
                    }
                    showPassInput = true
                    Qt.callLater(() => passInput.focusInput())
                }
            }
        }
        onExited: { savedProc.running = true; Qt.callLater(() => { netProc.running = true }) }
    }

    Process { id: deleteProc; property string cmd: ""; command: ["sh", "-c", cmd] }

    Process {
        id: switchToEthProc
        property string cmd: ""
        command: ["sh", "-c", cmd]
        onExited: { netProc.running = true }
    }

    Process {
        id: switchToWifiProc
        property string cmd: ""
        command: ["sh", "-c", cmd]
        onExited: { netProc.running = true; ssidProc.running = true; wifiListProc.running = true }
    }

    Process {
        id: btScanStartProc
        command: ["bash", "-c", "bluetoothctl scan on >/dev/null 2>&1 &"]
        onExited: btScanTimer.start()
    }

    Process {
        id: btScanStopProc
        command: ["bash", "-c", "bluetoothctl scan off >/dev/null 2>&1"]
    }

    Process {
        id: btScanPollProc
        command: ["bash", "-c", `
            bluetoothctl devices Paired 2>/dev/null | awk '{print $2}' > /tmp/qs_paired_macs
            bluetoothctl devices 2>/dev/null | while read _ mac rest; do
                info=$(bluetoothctl info "$mac" 2>/dev/null)
                name=$(echo "$info" | grep "Name:" | sed 's/.*Name: //')
                [ -z "$name" ] && continue
                connected=$(echo "$info" | grep -c "Connected: yes")
                paired=0
                grep -qx "$mac" /tmp/qs_paired_macs && paired=1
                echo "$mac|$name|$connected|$paired"
            done
            rm -f /tmp/qs_paired_macs
        `]
        stdout: SplitParser {
            splitMarker: "\n"
            property var buf: []
            onRead: line => {
                const parts = line.trim().split("|")
                if (parts.length !== 4) return
                const mac = parts[0].trim()
                if (buf.some(d => d.mac === mac)) return
                buf.push({ mac, name: parts[1].trim(), connected: parts[2] === "1", paired: parts[3] === "1" })
            }
        }
        onRunningChanged: { if (running) stdout.buf = [] }
        onExited: {
            btScanning = false
            btScanList = stdout.buf.slice()
            btScanStopProc.running = true
        }
    }

    Timer {
        id: btScanTimer
        interval: 8000
        repeat: false
        onTriggered: btScanPollProc.running = true
    }


    PassInput {
        id: passInput
        visible: showPassInput
        width: parent.width
        c: root.c; g: root.g
        pendingSsid: root.pendingSsid
        onConnect: (ssid, pass) => {
            const del = savedProfiles[ssid]
                ? "nmcli connection delete '" + savedProfiles[ssid] + "' 2>/dev/null; " : ""
            connectProc.cmd = del + "nmcli dev wifi connect '" + ssid + "' password '" + pass + "'"
            connectProc.running = true
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
                        text: netIcon; font { family: gwnce.name; pixelSize: 16 }
                        color: netName === "No connection" ? c.red : c.fg0
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
                        text: netName === "No connection" ? "No connection"
                            : useWifi ? (netSsid !== "" ? netSsid : netName)
                            : "Wired"
                        font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                        color: netName === "No connection" ? c.red : c.fg1
                        elide: Text.ElideRight; Layout.fillWidth: true
                    }
                }
            }

            MouseArea {
                id: netMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                    showNetList = !showNetList; showBtList = false; showPassInput = false
                    if (showNetList) wifiListProc.running = true
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
                        text: btList.filter(d => d.connected).length > 0
                              ? btList.filter(d => d.connected).map(d => d.name).join(", ")
                              : "No device connected"
                        font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                        color: c.fg1; elide: Text.ElideRight; Layout.fillWidth: true
                    }
                }
            }

            MouseArea {
                id: btMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                    showBtList = !showBtList; showNetList = false; showPassInput = false
                    if (showBtList) btListProc.running = true
                }
            }
        }
    }

    NetMenu {
        visible: showNetList
        width: parent.width
        c: root.c; g: root.g
        netList: root.netList
        netSsid: root.netSsid
        useWifi: root.useWifi
        savedProfiles: root.savedProfiles
        onConnectSsid: ssid => {
            if (ssid.trim() === netSsid.trim()) { showNetList = false; return }
            pendingSsid = ssid
            if (savedProfiles[ssid]) {
                connectProc.cmd = "nmcli connection up '" + savedProfiles[ssid] + "' 2>&1; echo EXIT:$?"
                connectProc.running = true
                showNetList = false
            } else {
                showPassInput = true; showNetList = false
                Qt.callLater(() => passInput.focusInput())
            }
        }
        onSwitchToWifi: {
            useWifi = true
            switchToWifiProc.cmd = "nmcli device disconnect " + ethIface + " 2>/dev/null; nmcli device connect " + wifiIface
            switchToWifiProc.running = true
            wifiListProc.running = true
        }
        onSwitchToEth: {
            useWifi = false
            switchToEthProc.cmd = "nmcli device disconnect " + wifiIface + " 2>/dev/null; nmcli device connect " + ethIface
            switchToEthProc.running = true
        }
    }

    BtMenu {
        visible: showBtList
        width: parent.width
        c: root.c; g: root.g
        btList: root.btList
        btScanList: root.btScanList
        btScanning: root.btScanning
        onConnectDevice:    mac => { btConnectProc.mac    = mac; btConnectProc.running    = true }
        onDisconnectDevice: mac => { btDisconnectProc.mac = mac; btDisconnectProc.running = true }
        onUnpair:           mac => { btUnpairProc.mac     = mac; btUnpairProc.running     = true }
        onPair:             mac => { btPairProc.mac        = mac; btPairProc.running        = true }
        onScan: {
            btScanning = true
            btScanList = []
            btScanStartProc.running = true
        }
    }
}
