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
        command: ["find", Config.wallpapersDir, "-maxdepth", "1", "-type", "f",
                  "(", "-iname", "*.jpg",  "-o", "-iname", "*.jpeg",
                  "-o", "-iname", "*.png", "-o", "-iname", "*.webp", ")"]
        stdout: SplitParser {
            splitMarker: "\n"
            property var buf: []
            onRead: line => { const t = line.trim(); if (t) buf.push(t) }
        }
        onRunningChanged: { if (running) stdout.buf = [] }
        onExited: { wallpapers = stdout.buf.slice().sort() }
    }

    // FIX DEFINITIF : le vrai problème était que running était déjà `false`
    // quand on tentait de le remettre à `true` — QML ne déclenche rien si
    // la valeur ne change pas (false -> false = no-op).
    //
    // Solution : on ne touche JAMAIS à running depuis QML.
    // On utilise un script bash qui tourne en boucle infinie et lit
    // les chemins depuis stdin via un named pipe (FIFO).
    // QML écrit dans le pipe — le script tue l'ancien swaybg et lance le nouveau.
    // Un seul Process QML, toujours running=true, jamais relancé.

    Process {
        id: _daemonProc
        // Démarre le daemon wallpaper : crée le pipe, boucle sur les chemins reçus
        command: ["bash", "-c",
            "PIPE=/tmp/qs_wall_pipe; " +
            "rm -f \"$PIPE\"; " +
            "mkfifo \"$PIPE\"; " +
            "trap 'pkill -x swaybg 2>/dev/null; rm -f \"$PIPE\"' EXIT; " +
            "while IFS= read -r path < \"$PIPE\"; do " +
            "  [ -z \"$path\" ] && continue; " +
            "  pkill -x swaybg 2>/dev/null; " +
            "  sleep 0.1; " +
            "  swaybg -i \"$path\" -m fill & " +
            "done"
        ]
        running: true
        onRunningChanged: {
            if (!running) {
                console.warn("WallpaperPicker: daemon died, restarting")
                Qt.callLater(() => running = true)
            }
        }
    }

    // Process qui écrit un chemin dans le pipe — court, se termine immédiatement
    Process {
        id: _writeProc
        property string path: ""
        command: ["bash", "-c", "echo '" + path + "' > /tmp/qs_wall_pipe"]
        onExited: code => {
            if (code !== 0)
                console.warn("WallpaperPicker: write to pipe failed, code", code)
        }
    }

    function setWallpaper(path) {
        if (path === _activeWallPath) return
        _activeWallPath  = path
        _writeProc.path  = path
        // FIX : forcer running true->false->true même si déjà false
        // en passant explicitement par false d'abord via Qt.callLater
        _writeProc.running = false
        Qt.callLater(() => { _writeProc.running = true })
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
