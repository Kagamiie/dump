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
        netProc.running  = true
        ssidProc.running = true
    }

    function refreshWifiList() {
        wifiListProc.running = true
    }

    function refreshSaved() {
        savedProc.running = true
    }

    function connectKnown(profileName) {
        connectKnownProc.profileName = profileName
        connectKnownProc.running     = true
    }

    function connectNew(ssid, pass) {
        connectNewProc.ssid    = ssid
        connectNewProc.pass    = pass
        connectNewProc.running = false
        Qt.callLater(() => connectNewProc.running = true)
    }

    function deleteProfile(profileName) {
        deleteKnownProc.profileName = profileName
        deleteKnownProc.running     = true
    }

    function switchToWifi() {
        if (ethIface === "" || wifiIface === "") return
        _disconnectForWifiProc.iface = ethIface
        _disconnectForWifiProc.running = false
        Qt.callLater(() => _disconnectForWifiProc.running = true)
    }

    function switchToEth() {
        if (wifiIface === "" || ethIface === "") return
        _disconnectForEthProc.iface = wifiIface
        _disconnectForEthProc.running = false
        Qt.callLater(() => _disconnectForEthProc.running = true)
    }

    property var _init: Timer {
        interval: 0; repeat: false; running: true
        onTriggered: {
            ifaceProc.running  = true
            savedProc.running  = true
            netProc.running    = true
            ssidProc.running   = true
        }
    }

    property var _pollFallback: Timer {
        interval: 30000
        repeat: true
        running: !_nmcliMonitor.running
        onTriggered: { netProc.running = true; ssidProc.running = true }
    }

    property var _nmcliMonitor: Process {
        id: _nmcliMonitor
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
        onRunningChanged: {
            if (!running) {
                console.warn("NetworkService: nmcli monitor died, restarting in 3s")
                _monitorRestartTimer.restart()
            }
        }
    }

    property var _monitorRestartTimer: Timer {
        id: _monitorRestartTimer
        interval: 3000; repeat: false
        onTriggered: _nmcliMonitor.running = true
    }

    property var ifaceProc: Process {
        id: ifaceProc
        command: ["sh", "-c",
            "nmcli -t -f DEVICE,TYPE device | awk -F: '$2==\"wifi\"{print $1}' | head -1; " +
            "nmcli -t -f DEVICE,TYPE device | awk -F: '$2==\"ethernet\"{print $1}' | head -1"
        ]
        stdout: SplitParser {
            splitMarker: "\n"
            property int lineN: 0
            onRead: line => {
                if (lineN === 0) root.wifiIface = line.trim()
                else             root.ethIface  = line.trim()
                lineN++
            }
        }
        onRunningChanged: { if (running) stdout.lineN = 0 }
    }

    property var ssidProc: Process {
        id: ssidProc
        command: ["sh", "-c",
            "iwgetid -r 2>/dev/null || nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2"]
        stdout: StdioCollector {
            onStreamFinished: root.netSsid = this.text.trim()
        }
    }

    property var savedProc: Process {
        id: savedProc
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

    property var netProc: Process {
        id: netProc
        command: ["sh", "-c",
            "ip route get 1.1.1.1 2>/dev/null | grep -oP 'dev \\K\\S+' | head -1"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                const iface = line.trim()
                if (!iface) {
                    root.netName = "No connection"
                    root.useWifi = false
                    return
                }
                root.netName = iface
                root.useWifi = iface.startsWith("w")
            }
        }
    }

    property var wifiListProc: Process {
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
                root.netList = arr
            }
        }
    }

    property var connectKnownProc: Process {
        id: connectKnownProc
        property string profileName: ""
        command: ["nmcli", "connection", "up", profileName]
        onExited: code => {
            savedProc.running = true
            netProc.running   = true
            if (code !== 0) root.connectionFailed(profileName)
            else            root.connectionSuccess()
        }
    }

    property var connectNewProc: Process {
        id: connectNewProc
        property string ssid: ""
        property string pass: ""
        command: ["nmcli", "dev", "wifi", "connect", ssid, "password", pass]
        onExited: code => {
            savedProc.running = true
            netProc.running   = true
            if (code !== 0) root.connectionFailed(ssid)
            else            root.connectionSuccess()
        }
    }

    property var deleteKnownProc: Process {
        id: deleteKnownProc
        property string profileName: ""
        command: ["nmcli", "connection", "delete", profileName]
    }

    property var _disconnectForWifiProc: Process {
        property string iface: ""
        command: ["nmcli", "device", "disconnect", iface]
        onExited: _connectWifiProc.running = true
    }

    property var _connectWifiProc: Process {
        command: ["nmcli", "device", "connect", root.wifiIface]
        onExited: {
            netProc.running      = true
            ssidProc.running     = true
            wifiListProc.running = true
        }
    }

    property var _disconnectForEthProc: Process {
        property string iface: ""
        command: ["nmcli", "device", "disconnect", iface]
        onExited: _connectEthProc.running = true
    }

    property var _connectEthProc: Process {
        command: ["nmcli", "device", "connect", root.ethIface]
        onExited: netProc.running = true
    }
}
