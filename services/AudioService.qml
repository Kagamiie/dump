pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property int    volume:   0
    property bool   muted:    false
    property string label:    "Audio"
    property int    micVol:   0
    property bool   micMuted: false
    property string micLabel: "Microphone"

    property var subscribeProc: Process {
        command: ["pactl", "subscribe"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                if (line.includes("sink") || line.includes("server")) volProc.running = true
                if (line.includes("source"))                          micProc.running = true
            }
        }
    }

    property var volProc: Process {
        id: volProc
        running: true
        command: ["sh", "-c",
            "pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\\d+(?=%)' | head -1; " +
            "pactl get-sink-mute @DEFAULT_SINK@; pactl get-default-sink"]
        stdout: SplitParser {
            splitMarker: "\n"
            property int lineN: 0
            onRead: line => {
                if (!line.trim()) return
                if (lineN === 0)      root.volume = parseInt(line.trim()) || 0
                else if (lineN === 1) root.muted  = line.includes("yes")
                else if (lineN === 2) root.label  = line.includes("Speaker")   ? "Speakers"
                                                  : line.includes("Headphone") ? "Headphones" : "Audio Out"
                lineN++
            }
        }
        onRunningChanged: { if (running) stdout.lineN = 0 }
    }

    property var micProc: Process {
        id: micProc
        command: ["sh", "-c",
            "pactl get-source-volume @DEFAULT_SOURCE@ | grep -oP '\\d+(?=%)' | head -1; " +
            "pactl get-source-mute @DEFAULT_SOURCE@; pactl get-default-source"]
        stdout: SplitParser {
            splitMarker: "\n"
            property int lineN: 0
            onRead: line => {
                if (!line.trim()) return
                if (lineN === 0)      micValue = parseInt(line.trim())
                else if (lineN === 1) micMuted  = line.includes("yes")
                else if (lineN === 2) micLabel = line.includes("Mic") ? "Microphone" : line.includes("Camera") ? "Camera Mic" : "Audio In"
                lineN++
            }
        }
        onRunningChanged: { if (running) stdout.lineN = 0 }
    }
}
