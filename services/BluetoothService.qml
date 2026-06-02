pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property var btList: []
    property var btScanList: []
    property bool btScanning: false
    property bool _refreshing: false

    // cache mac -> device
    property var _cache: ({})
    property var _scanCache: ({})

    signal listRefreshed()

    function refreshList() {
        if (_refreshing || btListProc.running)
            return
        btListProc.running = true
    }

    function connectDevice(mac) {
        btConnectProc.mac = mac
        btConnectProc.running = true
    }

    function disconnectDevice(mac) {
        btDisconnectProc.mac = mac
        btDisconnectProc.running = true
    }

    function unpair(mac) {
        btUnpairProc.mac = mac
        btUnpairProc.running = true
    }

    function scan() {
        btScanning = true
        btScanList = []
        _scanCache = {}
        btScanStartProc.running = true
    }

    property var pollTimer: Timer {
        interval: 20000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refreshList()
    }

    property var btScanTimer: Timer {
        interval: 10000
        repeat: false
        onTriggered: btScanPollProc.running = true
    }

    property var btScanStartProc: Process {
        command: ["bluetoothctl", "scan", "on"]
        onExited: btScanTimer.restart()
    }

    property var btScanStopProc: Process {
        command: ["bluetoothctl", "scan", "off"]
    }

    property var btScanPollProc: Process {
        command: ["bash", "-c", `
            bluetoothctl devices | while read _ mac rest; do
                info=$(bluetoothctl info "$mac" 2>/dev/null)
                name=$(echo "$info" | grep "Name:" | sed 's/.*Name: //')
                [ -z "$name" ] && continue

                connected=$(echo "$info" | grep -c "Connected: yes")
                paired=$(echo "$info" | grep -c "Paired: yes")

                echo "$mac|$name|$connected|$paired"
            done
        `]

        stdout: SplitParser {
            splitMarker: "\n"
            property var buf: []

            onRead: line => {
                const parts = line.trim().split("|")
                if (parts.length !== 4) return

                const mac = parts[0].trim()

                if (_scanCache[mac])
                    return

                const device = {
                    mac,
                    name: parts[1].trim(),
                    connected: parts[2] === "1",
                    paired: parts[3] === "1"
                }

                _scanCache[mac] = device
                buf.push(device)
            }
        }

        onRunningChanged: {
            if (running) stdout.buf = []
        }

        onExited: {
            root.btScanning = false
            root.btScanList = stdout.buf.slice()
            btScanStopProc.running = true
        }
    }

    property var btListProc: Process {
        command: ["bash", "-c", `
            connected=$(bluetoothctl devices Connected | awk '{print $2}')

            bluetoothctl devices Paired | while read _ mac rest; do
                info=$(bluetoothctl info "$mac" 2>/dev/null)
                name=$(echo "$info" | grep "Name:" | sed 's/.*Name: //')
                [ -z "$name" ] && continue

                is_connected=0
                echo "$connected" | grep -q "$mac" && is_connected=1

                echo "$mac|$name|$is_connected"
            done
        `]

        stdout: SplitParser {
            splitMarker: "\n"
            property var buf: []

            onRead: line => {
                const parts = line.trim().split("|")
                if (parts.length < 3) return

                const mac = parts[0].trim()
                const name = parts[1].trim()
                if (!name) return

                const connected = parts[2].trim() === "1"

                const prev = _cache[mac]
                if (prev && prev.name === name && prev.connected === connected) {
                    buf.push(prev)
                    return
                }

                const device = { mac, name, connected }
                _cache[mac] = device
                buf.push(device)
            }
        }

        onRunningChanged: {
            if (running) {
                _refreshing = true
                stdout.buf = []
            } else {
                root.btList = stdout.buf.slice()
                _refreshing = false
                root.listRefreshed()
            }
        }
    }

    property var btConnectProc: Process {
        property string mac: ""
        command: ["bluetoothctl", "connect", mac]
        onExited: root.refreshList()
    }

    property var btDisconnectProc: Process {
        property string mac: ""
        command: ["bluetoothctl", "disconnect", mac]
        onExited: root.refreshList()
    }

    property var btUnpairProc: Process {
        property string mac: ""
        command: ["bluetoothctl", "remove", mac]
        onExited: root.refreshList()
    }

    property var btPairProc: Process {
        property string mac: ""
        property string commandStr: ""

        command: mac ? ["bash", "-c", commandStr] : []

        onMacChanged: {
            commandStr = "bluetoothctl pair " + mac + " && bluetoothctl trust " + mac
        }

        onExited: {
            btPairConnectProc.mac = mac
            btPairConnectProc.running = true
        }
    }

    property var btPairConnectProc: Process {
        property string mac: ""
        command: ["bluetoothctl", "connect", mac]
        onExited: root.refreshList()
    }
}
