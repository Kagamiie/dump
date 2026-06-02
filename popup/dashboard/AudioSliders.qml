import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../themes/"
import "../../services/"
import "../../components/"

ColumnLayout {
    required property Colors c
    required property Glyphs g
    spacing: 8

    property int    volValue:    AudioService.volume
    property bool   volMuted:    AudioService.muted
    property string volLabel:    AudioService.label
    property int    micValue:    AudioService.micVol
    property bool   micMuted:    AudioService.micMuted
    property string micLabel:    AudioService.micLabel
    property int    brightValue: 50

    Process {
        id: brightGetProc
        command: ["sh", "-c", "brightnessctl -m | awk -F, '{print $4}' | tr -d '%'"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => { if (line.trim()) brightValue = parseInt(line.trim()) }
        }
    }

    Process { id: setVolProc;   property string cmd: ""; command: ["sh", "-c", cmd] }
    Process { id: setMicProc;   property string cmd: ""; command: ["sh", "-c", cmd] }
    Process { id: setBrightProc; property string cmd: ""; command: ["sh", "-c", cmd] }

    SliderControl {
        c: parent.c; g: parent.g
        icon: (volMuted || volValue === 0) ? g.audioMuted : volValue < 50 ? g.audioDecrease : g.audioIncrease
        label: volLabel; value: volValue; isMuted: volMuted
        Layout.fillWidth: true
        onIconClicked: { setVolProc.cmd = "pactl set-sink-mute @DEFAULT_SINK@ toggle"; setVolProc.running = true }
        onMoved: val => { setVolProc.cmd = "pactl set-sink-volume @DEFAULT_SINK@ " + val + "%"; setVolProc.running = true }
    }

    SliderControl {
        c: parent.c; g: parent.g
        icon: (micMuted || micValue === 0) ? g.micMuted : micValue < 50 ? g.micDecrease : g.micIncrease
        label: micLabel; value: micValue; isMuted: micMuted
        Layout.fillWidth: true
        onIconClicked: { setMicProc.cmd = "pactl set-source-mute @DEFAULT_SOURCE@ toggle"; setMicProc.running = true }
        onMoved: val => { setMicProc.cmd = "pactl set-source-volume @DEFAULT_SOURCE@ " + val + "%"; setMicProc.running = true }
    }

    SliderControl {
        c: parent.c; g: parent.g
        icon: g.layoutTile
        label: "Brightness"; value: brightValue; isMuted: false
        Layout.fillWidth: true
        onMoved: val => {
            setBrightProc.cmd = "brightnessctl set " + val + "%"
            setBrightProc.running = true
            brightValue = val
        }
    }
}
