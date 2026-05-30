import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import "../../themes/"

PanelWindow {
    id: root
    required property Colors c
    visible: false
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    function toggle() {
        visible = !visible;
    }

    property Glyphs g: Glyphs {}

    property var entries: [
        // Power
        {
            group: "Power",
            name: "shutdown",
            glyph: g.powerShutdown
        },
        {
            group: "Power",
            name: "reboot",
            glyph: g.powerReboot
        },
        {
            group: "Power",
            name: "suspend",
            glyph: g.powerSuspend
        },
        {
            group: "Power",
            name: "logoff",
            glyph: g.powerLogoff
        },
        // Battery
        {
            group: "Battery",
            name: "none",
            glyph: g.batNone
        },
        {
            group: "Battery",
            name: "critical",
            glyph: g.batCritical
        },
        {
            group: "Battery",
            name: "low",
            glyph: g.batLow
        },
        {
            group: "Battery",
            name: "normal",
            glyph: g.batNormal
        },
        {
            group: "Battery",
            name: "high",
            glyph: g.batHigh
        },
        {
            group: "Battery",
            name: "full",
            glyph: g.batFull
        },
        {
            group: "Battery",
            name: "unknown",
            glyph: g.batUnknown
        },
        {
            group: "Battery",
            name: "charging",
            glyph: g.batCharging
        },
        {
            group: "Battery",
            name: "charged",
            glyph: g.batCharged
        },
        // Media
        {
            group: "Media",
            name: "music",
            glyph: g.mediaMusic
        },
        {
            group: "Media",
            name: "previous",
            glyph: g.mediaPrevious
        },
        {
            group: "Media",
            name: "next",
            glyph: g.mediaNext
        },
        {
            group: "Media",
            name: "pause",
            glyph: g.mediaPause
        },
        {
            group: "Media",
            name: "play",
            glyph: g.mediaPlay
        },
        {
            group: "Media",
            name: "shuffle",
            glyph: g.mediaShuffle
        },
        {
            group: "Media",
            name: "loop",
            glyph: g.mediaLoop
        },
        // Audio
        {
            group: "Audio",
            name: "muted",
            glyph: g.audioMuted
        },
        {
            group: "Audio",
            name: "decrease",
            glyph: g.audioDecrease
        },
        {
            group: "Audio",
            name: "increase",
            glyph: g.audioIncrease
        },
        // Microphone
        {
            group: "Microphone",
            name: "muted",
            glyph: g.micMuted
        },
        {
            group: "Microphone",
            name: "decrease",
            glyph: g.micDecrease
        },
        {
            group: "Microphone",
            name: "increase",
            glyph: g.micIncrease
        },
        // Arrows
        {
            group: "Arrows",
            name: "up",
            glyph: g.arrowUp
        },
        {
            group: "Arrows",
            name: "right",
            glyph: g.arrowRight
        },
        {
            group: "Arrows",
            name: "down",
            glyph: g.arrowDown
        },
        {
            group: "Arrows",
            name: "left",
            glyph: g.arrowLeft
        },
        // Utils
        {
            group: "Utils",
            name: "magnifier",
            glyph: g.utilsMagnifier
        },
        {
            group: "Utils",
            name: "hamburger",
            glyph: g.utilsHamburger
        },
        // Titlebar
        {
            group: "Titlebar",
            name: "pin",
            glyph: g.titlePin
        },
        {
            group: "Titlebar",
            name: "close",
            glyph: g.titleClose
        },
        {
            group: "Titlebar",
            name: "maximize",
            glyph: g.titleMaximize
        },
        {
            group: "Titlebar",
            name: "minimize",
            glyph: g.titleMinimize
        },
        // Network
        {
            group: "Network",
            name: "wifi high",
            glyph: g.wifiHigh
        },
        {
            group: "Network",
            name: "wifi normal",
            glyph: g.wifiNormal
        },
        {
            group: "Network",
            name: "wifi low",
            glyph: g.wifiLow
        },
        {
            group: "Network",
            name: "wifi none",
            glyph: g.wifiNone
        },
        {
            group: "Network",
            name: "wired normal",
            glyph: g.wiredNormal
        },
        {
            group: "Network",
            name: "wired none",
            glyph: g.wiredNone
        },
        {
            group: "Network",
            name: "none",
            glyph: g.networkNone
        },
        // Bluetooth
        {
            group: "Bluetooth",
            name: "off",
            glyph: g.bluezOff
        },
        {
            group: "Bluetooth",
            name: "scanning",
            glyph: g.bluezScanning
        },
        {
            group: "Bluetooth",
            name: "on",
            glyph: g.bluezOn
        },
        // Weather day
        {
            group: "Weather day",
            name: "clear",
            glyph: g.dayClear
        },
        {
            group: "Weather day",
            name: "partly cloudy",
            glyph: g.dayPartCloudy
        },
        {
            group: "Weather day",
            name: "cloudy",
            glyph: g.dayCloudy
        },
        {
            group: "Weather day",
            name: "light rain",
            glyph: g.dayLightRain
        },
        {
            group: "Weather day",
            name: "rain",
            glyph: g.dayRain
        },
        {
            group: "Weather day",
            name: "storm",
            glyph: g.dayStorm
        },
        {
            group: "Weather day",
            name: "snow",
            glyph: g.daySnow
        },
        {
            group: "Weather day",
            name: "fog",
            glyph: g.dayFog
        },
        // Weather night
        {
            group: "Weather night",
            name: "clear",
            glyph: g.nightClear
        },
        {
            group: "Weather night",
            name: "partly cloudy",
            glyph: g.nightPartCloudy
        },
        {
            group: "Weather night",
            name: "cloudy",
            glyph: g.nightCloudy
        },
        {
            group: "Weather night",
            name: "light rain",
            glyph: g.nightLightRain
        },
        {
            group: "Weather night",
            name: "rain",
            glyph: g.nightRain
        },
        {
            group: "Weather night",
            name: "storm",
            glyph: g.nightStorm
        },
        {
            group: "Weather night",
            name: "snow",
            glyph: g.nightSnow
        },
        {
            group: "Weather night",
            name: "fog",
            glyph: g.nightFog
        },
        // Layout
        {
            group: "Layout",
            name: "floating",
            glyph: g.layoutFloating
        },
        {
            group: "Layout",
            name: "tile",
            glyph: g.layoutTile
        },
        {
            group: "Layout",
            name: "tile left",
            glyph: g.layoutTileLeft
        },
        {
            group: "Layout",
            name: "tile bottom",
            glyph: g.layoutTileBot
        },
    ]

    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
    }

    Rectangle {
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 420
        height: Math.min(600, scroll.contentHeight + 2)
        color: c.bg0
        border.width: 1
        border.color: c.bg3
        clip: true

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        // Header
        Rectangle {
            id: header
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: 36
            color: c.bg1
            border.width: 0
            z: 2

            Rectangle {
                anchors {
                    bottom: parent.bottom
                    left: parent.left
                    right: parent.right
                }
                height: 1
                color: c.bg3
            }

            Text {
                anchors.centerIn: parent
                text: "Glyph Reference"
                font.pixelSize: 12
                font.family: "JetBrains Mono Nerd Font"
                color: c.fg0
            }

            Text {
                anchors {
                    right: parent.right
                    rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                text: g.titleClose
                font.family: gwnce.name
                font.pixelSize: 14
                color: closeMa.containsMouse ? c.red : c.fg2

                MouseArea {
                    id: closeMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.visible = false
                }
            }
        }

        // Scrollable list
        Flickable {
            id: scroll
            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            contentWidth: width
            contentHeight: listCol.implicitHeight + 16
            clip: true

            Column {
                id: listCol
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    topMargin: 8
                }

                Repeater {
                    model: {
                        const seen = [];
                        for (const e of root.entries) {
                            if (!seen.includes(e.group))
                                seen.push(e.group);
                        }
                        return seen;
                    }
                    delegate: Column {
                        required property string modelData
                        width: listCol.width

                        // Group header
                        Rectangle {
                            width: parent.width
                            height: 24
                            color: c.bg2

                            Text {
                                anchors {
                                    verticalCenter: parent.verticalCenter
                                    left: parent.left
                                    leftMargin: 12
                                }
                                text: modelData
                                font.pixelSize: 10
                                font.bold: true
                                font.family: "JetBrains Mono Nerd Font"
                                color: c.accent
                            }
                        }

                        // Entries for this group
                        Repeater {
                            model: root.entries.filter(e => e.group === modelData)
                            delegate: Rectangle {
                                required property var modelData
                                width: listCol.width
                                height: 28
                                color: rowMa.containsMouse ? c.bg2 : "transparent"

                                Rectangle {
                                    anchors {
                                        bottom: parent.bottom
                                        left: parent.left
                                        right: parent.right
                                    }
                                    height: 1
                                    color: c.bg3
                                    opacity: 0.4
                                }

                                Row {
                                    anchors {
                                        verticalCenter: parent.verticalCenter
                                        left: parent.left
                                        leftMargin: 12
                                    }
                                    spacing: 16

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.glyph
                                        font.family: gwnce.name
                                        font.pixelSize: 16
                                        color: c.fg0
                                        width: 24
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.name
                                        font.pixelSize: 11
                                        font.family: "JetBrains Mono Nerd Font"
                                        color: c.fg1
                                    }
                                }

                                MouseArea {
                                    id: rowMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
