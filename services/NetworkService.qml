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

    property bool switching: false

    signal connectionFailed(string ssid)
    signal connectionSuccess()

    property var switchTimeout: Timer {
        interval: 45000
        repeat: false

        onTriggered: {
            if (root.switching) {
                console.error("NetworkService: switch timeout!")
                root.switching = false
                switchProc.running = false
            }
        }
    }

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
        _cmdProc.emitSignal = true
        _cmdProc.identifier = profileName
        _cmdProc.cmd = ["nmcli", "--wait", "30", "connection", "up", profileName]
        _cmdProc.running = true
    }

    function connectNew(ssid, pass) {
        _cmdProc.emitSignal = true
        _cmdProc.identifier = ssid
        _cmdProc.cmd = ["nmcli", "--wait", "30", "dev", "wifi", "connect", ssid, "password", pass]
        _cmdProc.running = true
    }

    function deleteProfile(profileName) {
        _cmdProc.emitSignal = false
        _cmdProc.cmd = ["nmcli", "--wait", "30", "connection", "delete", profileName]
        _cmdProc.running = true
    }

    function switchToWifi() {
        if (!wifiIface || !ethIface || switching) return
        switching = true
        switchTimeout.start()

        switchProc.cmd =
            "nmcli --wait 30 device disconnect " + ethIface + " && " +
            "sleep 1 && " +
            "nmcli --wait 30 device connect " + wifiIface
        switchProc.running = true
    }

    function switchToEth() {
        if (!wifiIface || !ethIface || switching) return
        switching = true
        switchTimeout.start()

        switchProc.cmd =
            "nmcli --wait 30 device disconnect " + wifiIface + " && " +
            "sleep 1 && " +
            "nmcli --wait 30 device connect " + ethIface
        switchProc.running = true
    }

    property var switchProc: Process {
        property string cmd: ""
        command: ["sh", "-c", cmd]

        onExited: code => {
            switchTimeout.stop()
            switching = false

            if (code !== 0) {
                console.error("NetworkService: switch failed with code", code)
                return
            }

            refresh()
            refreshWifiList()
        }
    }

    property var _init: Timer {
        interval: 0
        repeat: false
        running: true
        onTriggered: {
            ifaceProc.running = true
            savedProc.running = true
            refresh()
        }
    }

    property var _pollFallback: Timer {
        interval: 30000
        repeat: true
        running: !_nmcliMonitor.running
        onTriggered: refresh()
    }

    property var _nmcliMonitor: Process {
        command: ["nmcli", "monitor"]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                if (!line.trim() || root.switching) return
                root.refresh()
                if (line.includes("wifi") || line.includes("wireless"))
                    root.wifiListProc.running = true
            }
        }

        onRunningChanged: {
            if (!running)
                _monitorRestartTimer.restart()
        }
    }

    property var _monitorRestartTimer: Timer {
        interval: 3000
        repeat: false
        onTriggered: _nmcliMonitor.running = true
    }

    property var ifaceProc: Process {
        command: ["sh", "-c",
            "nmcli -t -f DEVICE,TYPE device | awk -F: '$2==\"wifi\"{print $1}' | head -1; " +
            "nmcli -t -f DEVICE,TYPE device | awk -F: '$2==\"ethernet\"{print $1}' | head -1"
        ]

        stdout: SplitParser {
            splitMarker: "\n"
            property int lineN: 0

            onRead: line => {
                if (lineN === 0)
                    root.wifiIface = line.trim()
                else
                    root.ethIface = line.trim()

                lineN++
            }
        }

        onRunningChanged: {
            if (running)
                stdout.lineN = 0
        }
    }

    property var ssidProc: Process {
        command: ["sh", "-c",
            "iwgetid -r 2>/dev/null || " +
            "nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2"
        ]

        stdout: StdioCollector {
            onStreamFinished: root.netSsid = this.text.trim()
        }
    }

    property var savedProc: Process {
        command: ["bash", "-c",
            "nmcli -t -f NAME,TYPE connection show | " +
            "grep ':802-11-wireless$' | cut -d: -f1 | " +
            "while read name; do " +
            "ssid=$(nmcli -g 802-11-wireless.ssid connection show \"$name\" 2>/dev/null); " +
            "[ -n \"$ssid\" ] && echo \"$ssid:$name\"; " +
            "done"
        ]

        stdout: SplitParser {
            splitMarker: "\n"
            property var buf: ({})

            onRead: line => {
                const idx = line.indexOf(":")
                if (idx < 1) return

                const ssid = line.substring(0, idx).trim()
                const name = line.substring(idx + 1).trim()

                if (ssid && name)
                    buf[ssid] = name
            }
        }

        onRunningChanged: {
            if (running)
                stdout.buf = ({})
        }

        onExited: {
            root.savedProfiles = Object.assign({}, stdout.buf)
        }
    }

    property var netProc: Process {
        command: ["sh", "-c",
            "ip route get 1.1.1.1 2>/dev/null | grep -oP 'dev \\K\\S+' | head -1"
        ]

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: line => {
                const iface = line.trim()
                root.netName = iface || "No connection"

                if (!iface) {
                    root.useWifi = false
                    return
                }

                root.useWifi = iface === root.wifiIface || iface.startsWith("wl")
            }
        }
    }

    property var wifiListProc: Process {
        command: ["sh", "-c",
            "nmcli -t -f SSID,SIGNAL,ACTIVE dev wifi list 2>/dev/null"
        ]

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
            if (running) {
                stdout.buf = ({})
            } else {
                const arr = Object.values(stdout.buf)
                arr.sort((a, b) =>
                    a.active ? -1 :
                    b.active ? 1 :
                    b.signal - a.signal
                )
                root.netList = arr
            }
        }
    }

    property var _cmdProc: Process {
        property var cmd: []
        property bool emitSignal: false
        property string identifier: ""

        command: cmd

        onExited: code => {
            savedProc.running = true
            netProc.running = true

            if (emitSignal) {
                if (code !== 0)
                    root.connectionFailed(identifier)
                else
                    root.connectionSuccess()
            }
        }
    }
}
