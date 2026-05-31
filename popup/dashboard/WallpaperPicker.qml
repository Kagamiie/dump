import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../themes/"

ColumnLayout {
    required property Colors c
    required property Glyphs g
    spacing: 8

    property var    wallpapers: []
    property string current:    ""
    property int    wallPage:   0

    property int pageCount: Math.ceil(wallpapers.length / 9)

    onWallpapersChanged: wallPage = 0

    Component.onCompleted: listProc.running = true

    Process {
        id: listProc
        command: ["bash", "-c", "find /home/ks/Documents/Medias/Wallpapers -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) | sort"]
        stdout: SplitParser {
            splitMarker: "\n"
            property var buf: []
            onRead: line => { if (line.trim()) buf.push(line.trim()) }
        }
        onRunningChanged: {
            if (running) stdout.buf = []
            else         wallpapers = stdout.buf.slice()
        }
    }

    Process {
        id: setWallProc
        property string pendingPath: ""
        property string activePath:  ""

        command: ["swaybg", "-i", activePath, "-m", "fill"]

        onExited: {
            // Si un autre wallpaper a été demandé pendant qu'on tournait
            if (pendingPath !== "" && pendingPath !== activePath) {
                activePath  = pendingPath
                pendingPath = ""
                running     = true
            }
        }
    }

    function setWallpaper(path) {
        if (path === setWallProc.activePath) return
        if (setWallProc.running) {
            // Process occupé → mettre en file d'attente
            setWallProc.pendingPath = path
        } else {
            setWallProc.activePath  = path
            setWallProc.pendingPath = ""
            setWallProc.running     = true
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
                    listProc.running = false
                    Qt.callLater(() => listProc.running = true)
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

                property bool isActive: modelData === current

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
                    onClicked: {
                        current = modelData
                        setWallpaper(modelData)
                    }
                }
            }
        }
    }

    Rectangle {
        visible: pageCount > 1
        Layout.fillWidth: true
        height: 28
        color: c.bg2
        border { width: 1; color: c.bg3 }

        RowLayout {
            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }

            Text {
                text: (wallPage + 1) + " / " + pageCount
                font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                color: c.fg2
                Layout.fillWidth: true
            }

            Row {
                spacing: 4

                Repeater {
                    model: [
                        { text: "‹", enabled: wallPage > 0,             action: () => wallPage-- },
                        { text: "›", enabled: wallPage < pageCount - 1, action: () => wallPage++ }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        width: 22; height: 18
                        color: pgMa.containsMouse ? c.bg3 : "transparent"
                        border { width: 1; color: modelData.enabled ? c.bg3 : "transparent" }
                        opacity: modelData.enabled ? 1 : 0.3

                        Text {
                            anchors.centerIn: parent
                            text: modelData.text
                            font { pixelSize: 13; family: "JetBrains Mono Nerd Font" }
                            color: c.fg2
                        }

                        MouseArea {
                            id: pgMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (modelData.enabled) modelData.action() }
                        }
                    }
                }
            }
        }
    }
}
