import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    required property var screen

    property var workspaces: []
    property var windows:    []

    function parseWorkspaces(text) {
        try {
            root.workspaces = JSON.parse(text)
                .map(ws => ({
                    id:         ws.id,
                    idx:        ws.idx ?? ws.id,
                    isFocused:  ws.is_focused ?? false,
                    hasWindows: (ws.window_count ?? 0) > 0,
                    output:     ws.output ?? ""
                }))
                .filter(ws => !root.screen || ws.output === root.screen.name)
                .sort((a, b) => a.idx - b.idx)
        } catch(e) {
            console.warn("Niri: failed to parse workspaces:", e)
        }
    }

    function parseWindows(text) {
        try {
            root.windows = JSON.parse(text)
                .map(w => ({
                    id:      w.id,
                    title:   w.title || w.app_id || "Window",
                    focused: w.is_focused ?? false,
                    col:     w.layout?.pos_in_scrolling_layout?.[0] ?? 9999
                }))
                .sort((a, b) => a.col - b.col)
        } catch(e) {
            console.warn("Niri: failed to parse windows:", e)
        }
    }

    Process {
        id: wsProc
        command: ["niri", "msg", "--json", "workspaces"]
        stdout: StdioCollector { onStreamFinished: root.parseWorkspaces(this.text) }
    }

    Process {
        id: winProc
        command: ["niri", "msg", "--json", "windows"]
        stdout: StdioCollector { onStreamFinished: root.parseWindows(this.text) }
    }

    Process {
        id: eventStream
        command: ["niri", "msg", "--json", "event-stream"]
        running: true
        onRunningChanged: {
            if (!running) {
                console.warn("Niri: event stream died, reconnecting in 2s")
                _reconnectTimer.restart()
            }
        }
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                if (!line.trim()) return
                try {
                    const key = Object.keys(JSON.parse(line))[0] ?? ""
                    if (/[Ww]orkspace/.test(key)) wsProc.running = true
                    if (/[Ww]indow/.test(key))    winProc.running = true
                } catch(e) {
                    console.warn("Niri: failed to parse event:", e)
                }
            }
        }
    }

    Timer {
        id: _reconnectTimer
        interval: 2000; repeat: false
        onTriggered: eventStream.running = true
    }

    Component.onCompleted: { wsProc.running = true; winProc.running = true }

    Process {
        id: focusWsProc
        property string wsId: ""
        command: ["niri", "msg", "action", "focus-workspace", wsId]
    }

    Process {
        id: focusWinProc
        property string winId: ""
        command: ["niri", "msg", "action", "focus-window", "--id", winId]
    }

    function focusWorkspace(id) { focusWsProc.wsId  = id.toString(); focusWsProc.running  = true }
    function focusWindow(id)    { focusWinProc.winId = id.toString(); focusWinProc.running = true }
}
