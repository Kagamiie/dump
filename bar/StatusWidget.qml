import QtQuick
import Quickshell.Io
import "../themes/"
import "../services/"

Item {
    required property Colors c
    required property Glyphs g
    implicitHeight: 24
    implicitWidth: box.implicitWidth

    property int    volume:  AudioService.volume
    property bool   muted:   AudioService.muted
    property int    percent: 0
    property string status:  "Unknown"
    property string _batPath: ""

    onVolumeChanged: volumeOsd.show(volume, muted)
    onMutedChanged:  volumeOsd.show(volume, muted)

    Process {
        id: _batDiscoverProc
        command: ["sh", "-c",
            "ls /sys/class/power_supply/ 2>/dev/null | grep -E '^BAT' | head -1"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                const name = line.trim()
                if (name) {
                    _batPath = "/sys/class/power_supply/" + name
                    // Relancer immédiatement après avoir découvert le path
                    Qt.callLater(() => {
                        batProc.running = true
                        _batPollTimer.running = true
                    })
                }
            }
        }
    }

    Timer {
        id: _batPollTimer
        interval: 30000
        repeat: true
        running: false
        triggeredOnStart: false
        onTriggered: {
            if (_batPath !== "") {
                batProc.running = true
            }
        }
    }

    Process {
        id: batProc
        // Directement utiliser _batPath au lieu d'une propriété intermédiaire
        command: ["bash", "-c",
            "[ -f \"$1/capacity\" ] && " +
            "{ echo \"$(cat \"$1/capacity\") $(cat \"$1/status\")\"; } || " +
            "echo '0 Unknown'",
            "--", _batPath]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                const parts = line.trim().split(" ")
                if (parts.length >= 2) {
                    percent = parseInt(parts[0]) || 0
                    status  = parts[1]
                } else if (parts[0] === "0") {
                    percent = 0
                    status = "Unknown"
                }
            }
        }

        onExited: code => {
            if (code !== 0 && _batPath !== "") {
                console.warn("StatusWidget: battery read failed, code:", code)
            }
        }
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
            anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 12 }
            spacing: 6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                font { family: gwnce.name; pixelSize: 14 }
                color: (muted || volume === 0) ? c.red : c.fg0
                text: (muted || volume === 0) ? g.audioMuted
                    : volume < 50            ? g.audioDecrease
                    :                          g.audioIncrease
            }

            Item { width: 4; height: 1 }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                font { family: gwnce.name; pixelSize: 16 }
                color: percent <= 20 ? c.red : c.fg0
                text: status === "Charging" ? g.batCharging
                    : status === "Full"     ? g.batFull
                    : status === "Unknown"  ? g.batUnknown
                    : percent >= 70         ? g.batHigh
                    : percent >= 40         ? g.batNormal
                    : percent >= 20         ? g.batLow
                    : percent > 0           ? g.batCritical
                    :                         g.batNone
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                font { family: "JetBrains Mono Nerd Font"; pixelSize: 10 }
                color: percent <= 20 ? c.red : c.fg3

                visible: _batPath !== ""
                text: percent + "%"
            }
        }
    }
}
