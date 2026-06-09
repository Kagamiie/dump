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

    // Subscribe to audio changes
    property var subscribeProc: Process {
        command: ["pactl", "subscribe"]
        running: true

        onRunningChanged: {
            if (!running) {
                console.warn("AudioService: pactl subscribe died, restarting in 3s")
                _subscribeRestartTimer.restart()
            }
        }

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                if (line.includes("sink") || line.includes("server")) sinkProc.running = true
                if (line.includes("source")) sourceProc.running = true
            }
        }
    }

    property var _subscribeRestartTimer: Timer {
        interval: 3000
        repeat: false
        onTriggered: subscribeProc.running = true
    }

    // Parse output: volume%, mute state, device name
    function _parseSinkSource(text, isSink) {
        const lines = text.trim().split("\n")
        if (lines.length < 3) return

        const volPercent = Math.min(100, parseInt(lines[0]) || 0)
        const isMute = lines[1].includes("yes")
        const deviceName = lines[2]

        if (isSink) {
            root.volume = volPercent
            root.muted = isMute
            root.label = deviceName.includes("Speaker") ? "Speakers"
                       : deviceName.includes("Headphone") ? "Headphones"
                       : "Audio Out"
        } else {
            root.micVol = volPercent
            root.micMuted = isMute
            root.micLabel = deviceName.includes("Mic") ? "Microphone"
                          : deviceName.includes("Camera") ? "Camera Mic"
                          : "Audio In"
        }
    }

    // Get speaker/output device status
    property var sinkProc: Process {
        running: true
        command: ["sh", "-c",
            "pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oP '\\d+(?=%)' | head -1 && " +
            "pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null && " +
            "pactl get-default-sink 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: root._parseSinkSource(this.text, true)
        }
    }

    // Get microphone/input device status
    property var sourceProc: Process {
        command: ["sh", "-c",
            "pactl get-source-volume @DEFAULT_SOURCE@ 2>/dev/null | grep -oP '\\d+(?=%)' | head -1 && " +
            "pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null && " +
            "pactl get-default-source 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: root._parseSinkSource(this.text, false)
        }
    }
}
