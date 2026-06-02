import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../themes/"

ColumnLayout {
    required property Colors c
    required property Glyphs g
    spacing: 8

    property var wallpapers: []
    property string _activeWallPath: ""
    property int wallPage: 0

    property var pageModel: []

    property var _queue: []
    property bool _writing: false

    property int _bgPid: 0

    function updatePage() {
        pageModel = wallpapers.slice(wallPage * 9, wallPage * 9 + 9)
    }

    onWallpapersChanged: {
        wallPage = 0
        updatePage()
    }

    onWallPageChanged: updatePage()

    Component.onCompleted: _listProc.running = true

    Process {
        id: _listProc
        command: [
            "find", Config.wallpapersDir,
            "-maxdepth", "1",
            "-type", "f",
            "(", "-iname", "*.jpg", "-o",
                  "-iname", "*.jpeg", "-o",
                  "-iname", "*.png", "-o",
                  "-iname", "*.webp", ")"
        ]

        stdout: SplitParser {
            splitMarker: "\n"
            property var buf: []

            onRead: line => {
                const t = line.trim()
                if (t) buf.push(t)
            }
        }

        onRunningChanged: {
            if (running) stdout.buf = []
        }

        onExited: {
            wallpapers = stdout.buf.slice().sort()
        }
    }

    Process {
        id: _daemon

        command: ["bash", "-c", `
            PID="";

            while true; do
            read -r path <&0

            [ -z "$path" ] && continue

            if [ -n "$PID" ]; then
                kill "$PID" 2>/dev/null
            fi

            swaybg -i "$path" -m fill &
            PID=$!
            done
        `]

        running: true
    }

    function setWallpaper(path) {
        if (path === _activeWallPath) return
        _activeWallPath = path

        _queue.push(path)
        if (!_writing)
            _writeNext()
    }

    function _writeNext() {
        if (_queue.length === 0) {
            _writing = false
            return
        }

        _writing = true
        const path = _queue.shift()

        _daemon.write(path + "\n")
        _writeNext()
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
                onClicked: _listProc.running = true
            }
        }
    }

    Grid {
        Layout.fillWidth: true
        columns: 3
        spacing: 4

        property real cellW: (320 - 8) / 3

        Repeater {
            model: pageModel

            delegate: Rectangle {
                required property string modelData

                property bool isActive: modelData === _activeWallPath

                width: parent.cellW
                height: parent.cellW * 9 / 16

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
        pageCount: Math.ceil(wallpapers.length / 9)
        onPrev: wallPage--
        onNext: wallPage++
    }
}
