import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../../themes/"

Item {
    required property Colors c
    required property Glyphs g
    height: 102

    property int playerIndex: 0
    property var player: null

    Component.onCompleted: updatePlayer()

    Timer {
        interval: 1000; repeat: true
        running: player?.isPlaying ?? false
        onTriggered: progressBar.forceUpdate()
    }

    function cyclePlayer() {
        if (!Mpris.players?.values.length) return
        playerIndex = (playerIndex + 1) % Mpris.players.values.length
        player = Mpris.players.values[playerIndex]
    }

    function updatePlayer() {
        const vals = Mpris.players?.values
        if (!vals?.length) { player = null; return }
        player = vals.find(p => p.isPlaying) ?? vals[0] ?? null
    }

    Connections {
        target: Mpris.players
        function onRowsInserted() { updatePlayer() }
        function onRowsRemoved()  { updatePlayer() }
    }

    Repeater {
        model: Mpris.players
        delegate: Item {
            required property var modelData
            Connections {
                target: modelData
                function onIsPlayingChanged()  { updatePlayer() }
                function onTrackTitleChanged() { updatePlayer() }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 1
        border.color: c.bg3
        z: 2
    }

    Rectangle {
        anchors { fill: parent; margins: 1 }
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
                GradientStop { position: 0.12; color: "#F01b1b1b" }
                GradientStop { position: 0.35; color: "#D01b1b1b" }
                GradientStop { position: 0.65; color: "#A01b1b1b" }
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
                    spacing: 6

                    Text {
                        text: g.changeSource
                        font { family: gwnce.name; pixelSize: 12 }
                        color: c.fg1
                        MouseArea {
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
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
                        color: c.fg1; elide: Text.ElideRight; Layout.maximumWidth: 100
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: player?.trackTitle ?? "Nothing Playing"
                    font { pixelSize: 12; bold: true; family: "JetBrains Mono Nerd Font" }
                    color: c.fg0; elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: "by " + (player?.trackArtist ?? "Unknown")
                    font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                    color: c.fg1; elide: Text.ElideRight
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: {
                            if (!player) return "00:00 / 00:00"
                            const fmt = s => Math.floor(s/60).toString().padStart(2,"0") + ":" + (s%60).toString().padStart(2,"0")
                            return fmt(Math.floor(player.position ?? 0)) + " / " + fmt(Math.floor(player.length ?? 0))
                        }
                        font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                        color: c.fg1
                    }

                    Item { Layout.fillWidth: true }

                    Repeater {
                        model: [
                            { icon: g.mediaPrevious, action: () => player?.previous() },
                            { icon: player?.isPlaying ? g.mediaPause : g.mediaPlay,
                              action: () => player?.togglePlaying() },
                            { icon: g.mediaNext,     action: () => player?.next() }
                        ]
                        delegate: Text {
                            required property var modelData
                            text: modelData.icon

                            font { family: gwnce.name; pixelSize: 14 }
                            color: ctrlMa.containsMouse ? c.accent : c.fg0
                            leftPadding: 8

                            MouseArea {
                                id: ctrlMa; anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.action()
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 4; color: c.bg2

                Rectangle {
                    width: player && (player.length ?? 0) > 0 ? parent.width * (player.position ?? 0) / player.length : 0
                    height: parent.height; color: c.accent
                    Behavior on width { SmoothedAnimation { velocity: 20 } }
                }
            }
        }
    }
}
