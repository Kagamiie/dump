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

    property int _subscribeRestartAttempts: 0
    property int _maxSubscribeRestarts: 5

    property var subscribeProc: Process {
        command: ["pactl", "subscribe"]
        running: true
        onRunningChanged: {
            if (!running) {
                _subscribeRestartAttempts++

                if (_subscribeRestartAttempts > _maxSubscribeRestarts) {
                    console.error("AudioService: pactl subscribe failed too many times, giving up")
                    return
                }

                // Backoff exponentiel: 2s, 4s, 8s, 16s, 32s
                const delay = Math.min(60000, 1000 * Math.pow(2, _subscribeRestartAttempts))
                console.warn(`AudioService: pactl subscribe died, restarting (attempt ${_subscribeRestartAttempts}/${_maxSubscribeRestarts}) in ${delay}ms`)
                _subscribeRestartTimer.interval = delay
                _subscribeRestartTimer.start()
            } else {
                // Succès - réinitialiser le compteur
                _subscribeRestartAttempts = 0
            }
        }
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                if (line.includes("sink") || line.includes("server")) sinkProc.running = true
                if (line.includes("source"))                          sourceProc.running = true
            }
        }
    }

    property var _subscribeRestartTimer: Timer {
        id: _subscribeRestartTimer
        interval: 2000; repeat: false
        onTriggered: subscribeProc.running = true
    }

    property var sinkProc: Process {
        id: sinkProc
        running: true
        command: ["sh", "-c",
            "pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oP '\\d+(?=%)' | head -1 && " +
            "pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null && " +
            "pactl get-default-sink 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n")
                if (lines.length < 3) return
                root.volume = Math.min(100, parseInt(lines[0]) || 0)
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
            "pactl get-source-volume @DEFAULT_SOURCE@ 2>/dev/null | grep -oP '\\d+(?=%)' | head -1 && " +
            "pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null && " +
            "pactl get-default-source 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n")
                if (lines.length < 3) return
                root.micVol   = Math.min(100, parseInt(lines[0]) || 0)
                root.micMuted = lines[1].includes("yes")
                const src     = lines[2]
                root.micLabel = src.includes("Mic")    ? "Microphone"
                              : src.includes("Camera") ? "Camera Mic"
                              : "Audio In"
            }
        }
    }
}
