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
            "pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\\d+(?=%)' | head -1 && " +
            "pactl get-sink-mute @DEFAULT_SINK@ && " +
            "pactl get-default-sink"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n")
                if (lines.length < 3) return
                root.volume = parseInt(lines[0]) || 0
                root.muted  = lines[1].includes("yes")
                const sink  = lines[2]
                root.label  = sink.includes("Speaker")   ? "Speakers"
                            : sink.includes("Headphone") ? "Headphones"
                            : "Audio Out"
            }
        }
    }

    property var sourceProc: Process {
        id: sourceProc
        command: ["sh", "-c",
            "pactl get-source-volume @DEFAULT_SOURCE@ | grep -oP '\\d+(?=%)' | head -1 && " +
            "pactl get-source-mute @DEFAULT_SOURCE@ && " +
            "pactl get-default-source"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n")
                if (lines.length < 3) return
                root.micVol   = parseInt(lines[0]) || 0
                root.micMuted = lines[1].includes("yes")
                const src     = lines[2]
                root.micLabel = src.includes("Mic")    ? "Microphone"
                              : src.includes("Camera") ? "Camera Mic"
                              : "Audio In"
            }
        }
    }
}
