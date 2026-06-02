pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property string netIcon:       ""
    property string netName:       "No connection"
    property string netSsid:       ""
    property bool   useWifi:       false
    property var    netList:       []
    property var    savedProfiles: ({})
    property string wifiIface:     ""
    property string ethIface:      ""

    signal connectionFailed(string ssid)
    signal connectionSuccess()

    function refresh() {
        netProc.running = true
        ssidProc.running = true
    }

    function refreshWifiList() {
        wifiListProc.running = true
    }

    function refreshSaved() {
        savedProc.running = true
    }

    function connectKnown(profileName) {
        _runCommand(["nmcli", "connection", "up", profileName], true, profileName)
    }

    function connectNew(ssid, pass) {
        _runCommand(["nmcli", "dev", "wifi", "connect", ssid, "password", pass], true, ssid)
    }

    function deleteProfile(profileName) {
        _runCommand(["nmcli", "connection", "delete", profileName], false, "")
    }

    function switchToWifi() {
        if (ethIface === "" || wifiIface === "") return
        _runCommand(["nmcli", "device", "disconnect", ethIface], false, "")
        Qt.callLater(() => _runCommand(["nmcli", "device", "connect", wifiIface], false, ""))
    }

    function switchToEth() {
        if (wifiIface === "" || ethIface === "") return
        _runCommand(["nmcli", "device", "disconnect", wifiIface], false, "")
        Qt.callLater(() => _runCommand(["nmcli", "device", "connect", ethIface], false, ""))
    }

    function _runCommand(cmd, emitSignal, identifier) {
        _cmdProc.cmd = cmd
        _cmdProc.emitSignal = emitSignal
        _cmdProc.identifier = identifier
        _cmdProc.running = false
        Qt.callLater(() => _cmdProc.running = true)
    }

    // Initialization
    property var _init: Timer {
        interval: 0; repeat: false; running: true
        onTriggered: {
            ifaceProc.running = true
            savedProc.running = true
            refresh()
        }
    }

    // Network change monitor
    property var _pollFallback: Timer {
        interval: 30000; repeat: true
        running: !_nmcliMonitor.running
        onTriggered: refresh()
    }

    property var _nmcliMonitor: Process {
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                if (!line.trim()) return
                refresh()
                if (line.includes("wifi") || line.includes("wireless"))
                    wifiListProc.running = true
            }
        }
        onRunningChanged: {
            if (!running) {
                console.warn("NetworkService: nmcli monitor died, restarting in 3s")
                _monitorRestartTimer.restart()
            }
        }
    }

    property var _monitorRestartTimer: Timer {
        interval: 3000; repeat: false
        onTriggered: _nmcliMonitor.running = true
    }

    // Find network interfaces
    property var ifaceProc: Process {
        command: ["sh", "-c",
            "nmcli -t -f DEVICE,TYPE device | awk -F: '$2==\"wifi\"{print $1}' | head -1; " +
            "nmcli -t -f DEVICE,TYPE device | awk -F: '$2==\"ethernet\"{print $1}' | head -1"]
        stdout: SplitParser {
            splitMarker: "\n"
            property int lineN: 0
            onRead: line => {
                if (lineN === 0) root.wifiIface = line.trim()
                else root.ethIface = line.trim()
                lineN++
            }
        }
        onRunningChanged: { if (running) stdout.lineN = 0 }
    }

    // Get current SSID
    property var ssidProc: Process {
        command: ["sh", "-c",
            "iwgetid -r 2>/dev/null || nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2"]
        stdout: StdioCollector {
            onStreamFinished: root.netSsid = this.text.trim()
        }
    }

    // Get saved profiles
    property var savedProc: Process {
        command: ["bash", "-c",
            "nmcli -t -f NAME,TYPE connection show | grep ':802-11-wireless$' | cut -d: -f1 | " +
            "while read name; do " +
            "  ssid=$(nmcli -g 802-11-wireless.ssid connection show \"$name\" 2>/dev/null); " +
            "  [ -n \"$ssid\" ] && echo \"$ssid:$name\"; " +
            "done"]
        stdout: SplitParser {
            splitMarker: "\n"
            property var buf: ({})
            onRead: line => {
                const idx = line.indexOf(":")
                if (idx < 1) return
                const ssid = line.substring(0, idx).trim()
                const name = line.substring(idx + 1).trim()
                if (ssid && name) buf[ssid] = name
            }
        }
        onRunningChanged: { if (running) stdout.buf = ({}) }
        onExited: { root.savedProfiles = Object.assign({}, stdout.buf) }
    }

    // Check current network connection
    property var netProc: Process {
        command: ["sh", "-c",
            "ip route get 1.1.1.1 2>/dev/null | grep -oP 'dev \\K\\S+' | head -1"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                const iface = line.trim()
                root.netName = iface || "No connection"
                root.useWifi = iface.startsWith("w") || false
            }
        }
    }

    // List WiFi networks
    property var wifiListProc: Process {
        command: ["sh", "-c", "nmcli -t -f SSID,SIGNAL,ACTIVE dev wifi list 2>/dev/null"]
        stdout: SplitParser {
            splitMarker: "\n"
            property var buf: ({})
            onRead: line => {
                const parts = line.split(":")
                if (parts.length < 3) return
                const ssid = parts[0].trim()
                const signal = parseInt(parts[1]) || 0
                const active = parts[2].trim() === "yes"
                if (!ssid) return
                if (!buf[ssid] || signal > buf[ssid].signal)
                    buf[ssid] = { ssid, signal, active }
            }
        }
        onRunningChanged: {
            if (running) stdout.buf = ({})
            else {
                const arr = Object.values(stdout.buf)
                arr.sort((a, b) => a.active ? -1 : b.active ? 1 : b.signal - a.signal)
                root.netList = arr
            }
        }
    }

    // Generic command runner (replaces multiple Process)
    property var _cmdProc: Process {
        property var cmd: []
        property bool emitSignal: false
        property string identifier: ""

        command: cmd
        onExited: code => {
            savedProc.running = true
            netProc.running = true
            if (emitSignal) {
                if (code !== 0) root.connectionFailed(identifier)
                else root.connectionSuccess()
            }
        }
    }
}
