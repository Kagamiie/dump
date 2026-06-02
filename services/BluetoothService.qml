pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property var btList: []
    property var btScanList: []
    property bool btScanning: false

    signal listRefreshed()

    function pair(mac) {
        btPairProc.mac = mac
        btPairProc.running = true
    }

    function scan() {
        btScanning = true
        btScanList = []
        btScanStartProc.running = true
    }

    function refreshList() {
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

    property var pollTimer: Timer {
        interval: 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: btListProc.running = true
    }

    property var btScanTimer: Timer {
        interval: 8000
        repeat: false
        onTriggered: btScanPollProc.running = true
    }

    property var btScanStartProc: Process {
        id: btScanStartProc
        command: ["bluetoothctl", "scan", "on"]
        onExited: btScanTimer.restart()
    }

    property var btScanStopProc: Process {
        id: btScanStopProc
        command: ["bluetoothctl", "scan", "off"]
    }

    property var btScanPollProc: Process {
        id: btScanPollProc
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

                if (buf.some(d => d.mac === mac)) return

                buf.push({
                    mac,
                    name: parts[1].trim(),
                    connected: parts[2] === "1",
                    paired: parts[3] === "1"
                })
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
        id: btListProc
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

                const name = parts[1].trim()
                if (!name) return

                buf.push({
                    mac: parts[0].trim(),
                    name,
                    connected: parts[2].trim() === "1"
                })
            }
        }

        onRunningChanged: {
            if (running) buf.buf = []
            else {
                root.btList = stdout.buf.slice()
                root.listRefreshed()
            }
        }
    }

    property var btConnectProc: Process {
        id: btConnectProc
        property string mac: ""
        command: ["bluetoothctl", "connect", mac]
        onExited: btListProc.running = true
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
        property string commandStr: ""

        command: {
            if (commandStr) {
                return ["bash", "-c", commandStr]
            }
            return []
        }

        onMacChanged: {
            commandStr = "bluetoothctl pair " + mac + " && bluetoothctl trust " + mac
        }

        onExited: {
            btPairConnectProc.mac = mac
            btPairConnectProc.running = true
        }
    }

    property var btPairConnectProc: Process {
        id: btPairConnectProc
        property string mac: ""
        command: ["bluetoothctl", "connect", mac]
        onExited: btListProc.running = true
    }
}
