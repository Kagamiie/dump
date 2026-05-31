pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property var    btList:     []
    property var    btScanList: []
    property bool   btScanning: false

    signal listRefreshed()

    function connectDevice(mac) {
        btConnectProc.mac    = mac
        btConnectProc.running = true
    }

    function disconnectDevice(mac) {
        btDisconnectProc.mac    = mac
        btDisconnectProc.running = true
    }

    function unpair(mac) {
        btUnpairProc.mac    = mac
        btUnpairProc.running = true
    }

    function pair(mac) {
        btPairProc.mac    = mac
        btPairProc.running = true
    }

    function scan() {
        btScanning       = true
        btScanList       = []
        btScanStartProc.running = true
    }

    function refreshList() {
        btListProc.running = true
    }

    // Poll toutes les 10s
    property var _pollTimer: Timer {
        interval: 10000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: btListProc.running = true
    }

    property var btPostConnectTimer: Timer {
        id: btPostConnectTimer
        interval: 1500
        repeat: false
        onTriggered: btListProc.running = true
    }

    property var btScanTimer: Timer {
        id: btScanTimer
        interval: 8000
        repeat: false
        onTriggered: btScanPollProc.running = true
    }

    property var btConnectProc: Process {
        id: btConnectProc
        property string mac: ""
        command: ["bluetoothctl", "connect", mac]
        onExited: btPostConnectTimer.restart()
    }

    property var btDisconnectProc: Process {
        id: btDisconnectProc
        property string mac: ""
        command: ["bluetoothctl", "disconnect", mac]
        onExited: btListProc.running = true
    }

    property var btUnpairProc: Process {
        id: btUnpairProc
        property string mac: ""
        command: ["bluetoothctl", "remove", mac]
        onExited: btListProc.running = true
    }

    property var btPairProc: Process {
        id: btPairProc
        property string mac: ""
        command: ["bluetoothctl", "pair", mac]
        onExited: {
            btPairConnectProc.mac     = mac
            btPairConnectProc.running = true
        }
    }

    property var btPairConnectProc: Process {
        id: btPairConnectProc
        property string mac: ""
        command: ["bluetoothctl", "connect", mac]
        onExited: btListProc.running = true
    }

    property var btListProc: Process {
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
                if (name) buf.push({
                    mac:       parts[0].trim(),
                    name,
                    connected: parts[2].trim() === "1"
                })
            }
        }
        onRunningChanged: {
            if (running) stdout.buf = []
            else {
                root.btList = stdout.buf.slice()
                root.listRefreshed()
            }
        }
    }

    property var btScanStartProc: Process {
        id: btScanStartProc
        command: ["bash", "-c", "bluetoothctl scan on >/dev/null 2>&1 &"]
        onExited: btScanTimer.restart()
    }

    property var btScanStopProc: Process {
        id: btScanStopProc
        command: ["bash", "-c", "bluetoothctl scan off >/dev/null 2>&1"]
    }

    property var btScanPollProc: Process {
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
                buf.push({
                    mac,
                    name:      parts[1].trim(),
                    connected: parts[2] === "1",
                    paired:    parts[3] === "1"
                })
            }
        }
        onRunningChanged: { if (running) stdout.buf = [] }
        onExited: {
            root.btScanning = false
            root.btScanList = stdout.buf.slice()
            btScanStopProc.running = true
        }
    }
}
