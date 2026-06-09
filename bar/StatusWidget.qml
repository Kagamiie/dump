import QtQuick
import Quickshell.Io
import "../themes/"
import "../services/"

Item {
    required property Colors c
    required property Glyphs g

    implicitHeight: 24
    implicitWidth: box.implicitWidth

    property int volume: AudioService.volume
    property bool muted: AudioService.muted

    property int percent: 0
    property string status: "Unknown"
    property string _batPath: ""

    onVolumeChanged: volumeOsd.show(volume, muted)
    onMutedChanged: volumeOsd.show(volume, muted)

    // Discover battery device
    Process {
        running: true
        command: [
            "sh", "-c",
            "ls /sys/class/power_supply/ 2>/dev/null | grep '^BAT' | head -n 1"
        ]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                const name = line.trim()
                if (!name || _batPath !== "") return
                _batPath = "/sys/class/power_supply/" + name
                _batPollTimer.start()
                _readBattery()
            }
        }
    }

    // Poll battery periodically
    Timer {
        id: _batPollTimer
        interval: 120000
        repeat: true
        running: false
        onTriggered: _readBattery()
    }

    // Read battery status
    property var _batProc: Process {
        command: _batPath === "" ? [] : [
            "bash", "-c",
            "cat \"$1/capacity\"; cat \"$1/status\"",
            "--", _batPath
        ]

        stdout: SplitParser {
            splitMarker: "\n"

            property int _cap: 0
            property string _st: "Unknown"

            onRead: line => {
                const v = line.trim()

                if (v === "Charging" || v === "Full" || v === "Discharging") {
                    _st = v
                } else {
                    const n = parseInt(v)
                    if (!isNaN(n))
                        _cap = n
                }
            }
        }

        onExited: {
            percent = stdout._cap
            status = stdout._st

            stdout._cap = 0
            stdout._st = "Unknown"
        }
    }

    function _readBattery() {
        if (_batPath !== "" && !_batProc.running)
            _batProc.running = true
    }

    Rectangle {
        id: box
        anchors.centerIn: parent
        height: 24
        color: c.bg1
        border { width: 1; color: c.bg3 }
        implicitWidth: row.implicitWidth + 24

        Row {
            id: row
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                leftMargin: 12
            }
            spacing: 6

            Text {
                font { family: gwnce.name; pixelSize: 14 }
                color: (muted || volume === 0) ? c.red : c.fg0
                text: (muted || volume === 0)
                        ? g.audioMuted
                        : volume < 50 ? g.audioDecrease : g.audioIncrease
            }

            Text {
                font { family: gwnce.name; pixelSize: 16 }
                color: percent <= 20 ? c.red : c.fg0

                text:
                    status === "Charging" ? g.batCharging :
                    status === "Full" ? g.batFull :
                    status === "Unknown" ? g.batUnknown :
                    percent >= 70 ? g.batHigh :
                    percent >= 40 ? g.batNormal :
                    percent >= 20 ? g.batLow :
                    percent > 0 ? g.batCritical :
                    g.batNone
            }

            Text {
                visible: _batPath !== ""
                font { family: "JetBrains Mono Nerd Font"; pixelSize: 10 }
                color: percent <= 20 ? c.red : c.fg3
                text: percent + "%"
            }
        }
    }
}
