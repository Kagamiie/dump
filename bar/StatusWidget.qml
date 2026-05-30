import QtQuick
import Quickshell.Io
import "../themes/"

Item {
    required property Colors c
    required property Glyphs g
    implicitHeight: 24
    implicitWidth: box.implicitWidth

    property int volume: 0
    property bool muted: false
    property int percent: 0
    property string status: "Unknown"

    onVolumeChanged: volumeOsd.show(volume, muted)
    onMutedChanged:  volumeOsd.show(volume, muted)

    Process {
        command: ["pactl", "subscribe"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                if (line.includes("sink") || line.includes("server")) volProc.running = true
            }
        }
    }

    Process {
        id: volProc
        running: true
        command: ["sh", "-c", "pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\\d+(?=%)' | head -1; pactl get-sink-mute @DEFAULT_SINK@"]
        stdout: SplitParser {
            splitMarker: "\n"
            property bool first: true
            onRead: line => {
                if (!line.trim()) return
                if (first) { volume = parseInt(line.trim()) || 0 }
                else       { muted = line.includes("yes") }
                first = !first
            }
        }
    }

    Timer {
        interval: 30000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: batProc.running = true
    }

    Process {
        id: batProc
        command: ["sh", "-c", "echo $(cat /sys/class/power_supply/BAT0/capacity) $(cat /sys/class/power_supply/BAT0/status)"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                const parts = line.trim().split(" ")
                if (parts.length >= 2) { percent = parseInt(parts[0]); status = parts[1] }
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
                text: percent + "%"
            }
        }
    }
}
