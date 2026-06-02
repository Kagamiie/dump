import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../../themes/"

Item {
    required property Colors c
    required property Glyphs g
    height: 102

    property var player: null

    Component.onCompleted: updatePlayer()

    Timer {
        interval: 1000
        repeat: true
        running: player?.isPlaying ?? false
        onTriggered: {
            if (player) player.positionChanged()
        }
    }

    function updatePlayer() {
        const list = Mpris.players?.values ?? []
        if (!list.length) {
            player = null
            return
        }

        const playing = list.find(p => p.isPlaying)
        const next = playing ?? list[0]

        if (player === next) return
        player = next
    }

    function cyclePlayer() {
        const list = Mpris.players?.values ?? []
        if (!list.length) return

        const idx = list.indexOf(player)
        player = list[(idx + 1) % list.length]
    }

    Connections {
        target: Mpris.players

        function onRowsInserted() { updatePlayer() }
        function onRowsRemoved()  { updatePlayer() }
        function onDataChanged()   { updatePlayer() }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 1
        border.color: c.bg3
        z: 2
    }

    Rectangle {
        anchors.fill: parent
        color: c.bg1
        clip: true

        Image {
            anchors.fill: parent
            source: player?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.00; color: "#FF1b1b1b" }
                GradientStop { position: 1.00; color: "#801b1b1b" }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 12
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: g.changeSource
                        font { family: gwnce.name; pixelSize: 12 }
                        color: c.fg1
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cyclePlayer()
                        }
                    }

                    Text {
                        text: g.mediaMusic
                        font { family: gwnce.name; pixelSize: 11 }
                        color: c.fg1
                    }

                    Text {
                        text: player?.isPlaying ? "Playing" : "Paused"
                        font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                        color: c.fg1
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "via " + (player?.identity ?? "Unknown")
                        font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                        color: c.fg1
                        elide: Text.ElideRight
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: player?.trackTitle ?? "Nothing Playing"
                    font { pixelSize: 12; bold: true; family: "JetBrains Mono Nerd Font" }
                    color: c.fg0
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: "by " + (player?.trackArtist ?? "Unknown")
                    font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                    color: c.fg1
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: {
                            if (!player) return "00:00 / 00:00"

                            const fmt = s =>
                                Math.floor(s / 60).toString().padStart(2, "0") + ":" +
                                (s % 60).toString().padStart(2, "0")

                            return fmt(Math.floor(player.position ?? 0)) +
                                   " / " +
                                   fmt(Math.floor(player.length ?? 0))
                        }
                        font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                        color: c.fg1
                    }

                    Item { Layout.fillWidth: true }

                    Repeater {
                        model: 3

                        delegate: Text {
                            property int idx: index

                            text: idx === 0
                                ? g.mediaPrevious
                                : idx === 1
                                    ? (player?.isPlaying ? g.mediaPause : g.mediaPlay)
                                    : g.mediaNext

                            font { family: gwnce.name; pixelSize: 14 }
                            color: c.fg0

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    if (!player) return

                                    if (idx === 0) player.previous()
                                    else if (idx === 1) player.togglePlaying()
                                    else player.next()
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 4
                color: c.bg2

                Rectangle {
                    width: player && player.length
                        ? parent.width * (player.position ?? 0) / player.length
                        : 0

                    height: parent.height
                    color: c.accent

                    Behavior on width {
                        SmoothedAnimation { velocity: 20 }
                    }
                }
            }
        }
    }
}
