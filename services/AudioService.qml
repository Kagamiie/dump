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
                if (line.includes("sink") || line.includes("server")) sinkProc.running = true
                if (line.includes("source"))                          sourceProc.running = true
            }
        }
    }

    property var sinkProc: Process {
        id: sinkProc
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

    property var sourceProc: Process {
        id: sourceProc
        command: ["sh", "-c",
            "pactl get-source-volume @DEFAULT_SOURCE@ | grep -oP '\\d+(?=%)' | head -1; " +
            "pactl get-source-mute @DEFAULT_SOURCE@; pactl get-default-source"]
        stdout: SplitParser {
            splitMarker: "\n"
            property int lineN: 0
            onRead: line => {
                if (!line.trim()) return
                if (lineN === 0)      root.micVol   = parseInt(line.trim()) || 0
                else if (lineN === 1) root.micMuted  = line.includes("yes")
                else if (lineN === 2) root.micLabel  = line.includes("Mic")    ? "Microphone"
                                                     : line.includes("Camera") ? "Camera Mic" : "Audio In"
                lineN++
            }
        }
        onRunningChanged: { if (running) stdout.lineN = 0 }
    }
}
