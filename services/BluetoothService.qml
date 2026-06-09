pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property var btList: []
    property var btScanList: []
    property bool btScanning: false

    signal listRefreshed()

    function refreshList() {
        if (btListProc.running) return
        btListProc.running = true
    }

    function connectDevice(mac) {
        _runCommand(["bluetoothctl", "connect", mac])
    }

    function disconnectDevice(mac) {
        _runCommand(["bluetoothctl", "disconnect", mac])
    }

    function unpair(mac) {
        _runCommand(["bluetoothctl", "remove", mac])
    }

    function pair(mac) {
        _runCommand(["bluetoothctl", "pair", mac])
        Qt.callLater(() => _runCommand(["bluetoothctl", "trust", mac]))
    }

    function scan() {
        btScanning = true
        btScanList = []
        _runCommand(["bluetoothctl", "scan", "on"])
        btScanTimer.restart()
    }

    function _runCommand(cmd) {
        _proc.command = cmd
        _proc.running = false
        Qt.callLater(() => _proc.running = true)
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

    property var _proc: Process {
        onExited: root.refreshList()
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
                buf.push({ mac, name, connected })
            }
        }

        onRunningChanged: {
            if (running) {
                stdout.buf = []
            } else {
                root.btList = stdout.buf.slice()
                root.listRefreshed()
            }
        }
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
                const device = {
                    mac,
                    name: parts[1].trim(),
                    connected: parts[2] === "1",
                    paired: parts[3] === "1"
                }

                buf.push(device)
            }
        }

        onRunningChanged: { if (running) stdout.buf = [] }

        onExited: {
            root.btScanning = false
            const seen = {}
            root.btScanList = stdout.buf.filter(d => {
                if (seen[d.mac]) return false
                seen[d.mac] = true
                return true
            })
            _runCommand(["bluetoothctl", "scan", "off"])
        }
    }
}
