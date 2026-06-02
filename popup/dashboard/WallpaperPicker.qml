import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../themes/"

ColumnLayout {
    required property Colors c
    required property Glyphs g
    spacing: 8

    property var    wallpapers:      []
    property string _activeWallPath: ""
    property int    wallPage:        0

    property int _wallPageCount: Math.ceil(wallpapers.length / 9)

    onWallpapersChanged: wallPage = 0

    Component.onCompleted: _listProc.running = true

    Process {
        id: _listProc
        command: ["find", Quickshell.env("HOME") ?? "/home/user", "-path", "*/.cache", "-prune", "-o",
                  "-maxdepth", "3", "-type", "f",
                  "(", "-iname", "*.jpg",  "-o", "-iname", "*.jpeg",
                  "-o", "-iname", "*.png", "-o", "-iname", "*.webp", ")", "-print"]
        stdout: SplitParser {
            splitMarker: "\n"
            property var buf: []
            onRead: line => {
                const t = line.trim()
                if (t) buf.push(t)
            }
        }
        onRunningChanged: { if (running) stdout.buf = [] }
        onExited: code => {
            if (code !== 0) {
                console.warn("WallpaperPicker: find failed with code", code)
                return
            }
            wallpapers = stdout.buf.slice().sort()
        }
    }

    property int _daemonFailCount: 0

    property var _daemonBackoffTimer: Timer {
        id: _daemonBackoffTimer
        repeat: false
        onTriggered: _daemonProc.running = true
    }

    Process {
        id: _daemonProc
        command: ["bash", "-c",
            "PIPE=\"${XDG_RUNTIME_DIR:-/tmp}/qs_wall_pipe_$$\"; " +  // Include PID
            "trap 'pkill -x swaybg 2>/dev/null; rm -f \"$PIPE\"' EXIT; " +
            "[ -e \"$PIPE\" ] && { echo >&2 'FIFO already exists'; exit 1; }; " +
            "mkfifo \"$PIPE\" || { echo >&2 'Failed to create FIFO'; exit 1; }; " +
            "while IFS= read -r path < \"$PIPE\"; do " +
            "  [ -z \"$path\" ] && continue; " +
            "  pkill -x swaybg 2>/dev/null; " +
            "  sleep 0.1; " +
            "  swaybg -i \"$path\" -m fill & " +
            "done"
        ]
        running: true

        onRunningChanged: {
            if (running) {
                _daemonFailCount = 0
                return
            }
            if (_daemonFailCount >= 5) {
                console.error("WallpaperPicker: daemon failed 5 times, giving up")
                return
            }
            _daemonFailCount++
            const delay = Math.min(30000, 500 * Math.pow(2, _daemonFailCount))
            console.warn("WallpaperPicker: daemon died, restart #" + _daemonFailCount
                         + " in " + delay + "ms")
            _daemonBackoffTimer.interval = delay
            _daemonBackoffTimer.restart()
        }
    }

    property string _pendingPath: ""

    Process {
        id: _writeProc
        property string path: ""
        command: ["bash", "-c",
            "printf '%s\\n' \"$1\" > \"${XDG_RUNTIME_DIR:-/tmp}/qs_wall_pipe_$$\"",
            "--", path]

        onExited: code => {
            if (code !== 0)
                console.warn("WallpaperPicker: pipe write failed, code:", code)
            if (_pendingPath !== "") {
                path = _pendingPath
                _pendingPath = ""
                running = true
            }
        }
    }

    function setWallpaper(wallPath) {
        if (wallPath === _activeWallPath) return
        _activeWallPath = wallPath
        if (_writeProc.running) {
            _pendingPath = wallPath
        } else {
            _writeProc.path = wallPath
            _writeProc.running = true
        }
    }

    RowLayout {
        Layout.fillWidth: true

        Text {
            text: wallpapers.length + " wallpapers"
            font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
            color: c.fg2
            Layout.fillWidth: true
        }

        Rectangle {
            width: 20; height: 20
            color: refreshMa.containsMouse ? c.bg3 : "transparent"
            border { width: 1; color: refreshMa.containsMouse ? c.bg3 : "transparent" }

            Text {
                anchors.centerIn: parent
                text: "↺"
                font { pixelSize: 13; family: "JetBrains Mono Nerd Font" }
                color: c.fg2
            }
            MouseArea {
                id: refreshMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    _listProc.running = false
                    Qt.callLater(() => _listProc.running = true)
                }
            }
        }
    }

    Grid {
        Layout.fillWidth: true
        columns: 3
        spacing: 4
        property real cellW: (320 - 8) / 3

        Repeater {
            model: wallpapers.slice(wallPage * 9, wallPage * 9 + 9)
            delegate: Rectangle {
                required property string modelData
                required property int    index

                property bool isActive: modelData === _activeWallPath

                width: parent.cellW; height: parent.cellW * 9 / 16
                color: c.bg2
                border { width: 1; color: isActive ? c.accent : c.bg3 }
                clip: true

                Image {
                    anchors.fill: parent
                    source: "file://" + modelData
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 160
                    sourceSize.height: 90
                }

                Rectangle {
                    visible: isActive
                    anchors { right: parent.right; bottom: parent.bottom; margins: 3 }
                    width: 14; height: 14
                    color: c.accent
                    Text {
                        anchors.centerIn: parent
                        text: "✓"
                        font { pixelSize: 8; family: "JetBrains Mono Nerd Font" }
                        color: c.bg0
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: setWallpaper(modelData)
                }
            }
        }
    }

    Paginator {
        Layout.fillWidth: true
        c: parent.c
        currentPage: wallPage
        pageCount:   _wallPageCount
        onPrev: wallPage--
        onNext: wallPage++
    }
}
