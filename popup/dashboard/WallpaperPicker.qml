import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../themes/"

ColumnLayout {
    required property Colors c
    required property Glyphs g
    spacing: 8

    property var    wallpapers:       []
    property string _activeWallPath:  ""
    property string _pendingWallPath: ""
    property int    wallPage:         0

    property int pageCount: Math.ceil(wallpapers.length / 9)

    onWallpapersChanged: wallPage = 0

    Component.onCompleted: _listProc.running = true

    Process {
        id: _listProc
        command: ["find", Config.wallpapersDir, "-maxdepth", "1", "-type", "f",
                  "(", "-iname", "*.jpg",  "-o", "-iname", "*.jpeg",
                  "-o", "-iname", "*.png", "-o", "-iname", "*.webp", ")",
                  "-print0"]
        stdout: SplitParser {
            splitMarker: "\0"
            property var buf: []
            onRead: line => { if (line.trim()) buf.push(line.trim()) }
        }
        onRunningChanged: { if (running) stdout.buf = [] }
        onExited: {
            const sorted = stdout.buf.slice().sort()
            wallpapers = sorted
        }
    }

    Process {
        id: _killProc
        command: ["pkill", "-x", "swaybg"]

        onExited: {
            if (_pendingWallPath !== "") {
                _launchProc.wallPath  = _pendingWallPath
                _activeWallPath       = _pendingWallPath
                _pendingWallPath      = ""
                _launchProc.running   = true
            }
        }
    }

    Process {
        id: _launchProc
        property string wallPath: ""
        command: ["swaybg", "-i", wallPath, "-m", "fill"]
        onRunningChanged: {
            if (!running && wallPath !== "") {
                console.warn("WallpaperPicker: swaybg exited unexpectedly for", wallPath)
            }
        }
    }

    function setWallpaper(path) {
        if (path === _activeWallPath) return
        _pendingWallPath = path
        _killProc.running = false
        Qt.callLater(() => _killProc.running = true)
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
        pageCount:   pageCount
        onPrev: wallPage--
        onNext: wallPage++
    }
}
