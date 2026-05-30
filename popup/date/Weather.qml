import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../themes/"

Item {
    required property Colors c
    required property Glyphs g
    implicitHeight: weatherData === null ? loadingText.implicitHeight : card.implicitHeight

    property var weatherData: null
    property bool showHourly: true

    property string tempC:       weatherData ? weatherData.current_condition[0].temp_C            : ""
    property string feelsLike:   weatherData ? weatherData.current_condition[0].FeelsLikeC        : ""
    property string humidity:    weatherData ? weatherData.current_condition[0].humidity           : ""
    property string windspeed:   weatherData ? weatherData.current_condition[0].windspeedKmph      : ""
    property string description: weatherData ? weatherData.current_condition[0].weatherDesc[0].value.trim() : ""
    property string weatherCode: weatherData ? weatherData.current_condition[0].weatherCode        : "113"
    property string maxTemp:     weatherData ? weatherData.weather[0].maxtempC                     : ""
    property string minTemp:     weatherData ? weatherData.weather[0].mintempC                     : ""
    property var hourly:         weatherData ? weatherData.weather[0].hourly.slice(0, 7)           : []
    property var nextDays:       weatherData ? weatherData.weather.slice(1, 3)                     : []

    function weatherIcon(code, hour) {
        return g.weatherGlyph(code, parseInt(hour) / 100 >= 6 && parseInt(hour) / 100 < 21)
    }

    Timer {
        interval: 7200000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: fetchProc.running = true
    }

    Process {
        id: fetchProc
        command: ["curl", "-s", "-A", "Mozilla/5.0", "https://wttr.in/?format=j1"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { weatherData = JSON.parse(this.text) }
                catch (e) { console.log("weather error:", e) }
            }
        }
        onRunningChanged: { if (running) weatherData = null }
    }

    Text {
        id: loadingText
        visible: weatherData === null
        width: parent.width
        text: "Loading weather..."
        color: c.fg2
        font.pixelSize: 11
        font.family: "JetBrains Mono Nerd Font"
        horizontalAlignment: Text.AlignHCenter
    }

    Rectangle {
        id: card
        visible: weatherData !== null
        width: parent.width
        implicitHeight: cardCol.implicitHeight
        color: c.bg1
        border.width: 1
        border.color: c.bg3
        radius: 2
        clip: true

        ColumnLayout {
            id: cardCol
            anchors { left: parent.left; right: parent.right }
            spacing: 0

            Item {
                Layout.fillWidth: true
                implicitHeight: statusCol.implicitHeight + 24

                Text {
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                        leftMargin: 20
                        topMargin: 20
                    }

                    text: g.weatherGlyph(weatherCode, new Date().getHours() >= 6 && new Date().getHours() < 21)
                    font.family: gwnce.name
                    font.pixelSize: 150
                    color: c.bg3
                    z: 0
                }

                RowLayout {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        leftMargin: 12
                        rightMargin: 12
                        topMargin: 12
                    }

                    z: 1
                    spacing: 8

                    ColumnLayout {
                        id: statusCol
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            text: description

                            font.pixelSize: 14
                            font.bold: true
                            font.family: "JetBrains Mono Nerd Font"
                            color: c.fg0

                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                        }

                        Text {
                            text: "Humidity: " + humidity + "%"

                            font.pixelSize: 10
                            font.family: "JetBrains Mono Nerd Font"
                            color: c.fg2
                        }
                    }

                    ColumnLayout {
                        spacing: 1

                        Text {
                            text: tempC + "°C"

                            font.pixelSize: 20
                            font.bold: true
                            font.family: "JetBrains Mono Nerd Font"
                            color: c.fg0

                            Layout.alignment: Qt.AlignRight
                        }

                        Text {
                            text: feelsLike + "°C"

                            font.pixelSize: 10
                            font.family: "JetBrains Mono Nerd Font"
                            color: c.fg2

                            Layout.alignment: Qt.AlignRight
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.rightMargin: 12
                Layout.topMargin: 4
                Layout.bottomMargin: 20
                spacing: 4

                Item { Layout.fillWidth: true }

                Repeater {
                    model: [{ label: "By Hour", active: showHourly }, { label: "By Day", active: !showHourly }]
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: 56; height: 18
                        color: modelData.active ? c.bg3 : "transparent"
                        radius: 2
                        border.width: 1
                        border.color: c.bg3
                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            font.pixelSize: 9
                            font.family: "JetBrains Mono Nerd Font"
                            color: modelData.active ? c.fg0 : c.fg2
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: showHourly = index === 0
                        }
                    }
                }
            }

            Row {
                visible: showHourly
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                Layout.bottomMargin: 10
                spacing: 0
                Layout.alignment: Qt.AlignHCenter

                Repeater {
                    model: hourly
                    delegate: Item {
                        required property var modelData
                        width: (268 - 16) / 7
                        height: 72

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 0

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: (parseInt(modelData.time) / 100).toString().padStart(2, "0") + "h"
                                font.pixelSize: 10
                                font.family: "JetBrains Mono Nerd Font"
                                color: c.fg2
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: weatherIcon(modelData.weatherCode, modelData.time)
                                font.family: gwnce.name
                                font.pixelSize: 26
                                color: c.fg0
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.tempC + "°"
                                font.pixelSize: 11
                                font.family: "JetBrains Mono Nerd Font"
                                color: c.fg0
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.chanceofrain + "%"
                                font.pixelSize: 9
                                font.family: "JetBrains Mono Nerd Font"
                                color: parseInt(modelData.chanceofrain) > 30 ? c.bccent : c.fg2
                            }
                        }
                    }
                }
            }

            Item {
                visible: !showHourly
                Layout.fillWidth: true
                height: 64
                Layout.bottomMargin: 10

                Row {
                    anchors.centerIn: parent
                    spacing: 14

                    Repeater {
                        model: nextDays
                        delegate: RowLayout {
                            required property var modelData
                            spacing: 3

                            Text {
                                text: weatherIcon(modelData.hourly[4].weatherCode, "1200")
                                font.family: gwnce.name
                                font.pixelSize: 50
                                color: c.fg0
                                Layout.alignment: Qt.AlignVCenter
                            }

                            ColumnLayout {
                                spacing: 0
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    text: ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"][new Date(modelData.date).getDay()]
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.family: "JetBrains Mono Nerd Font"
                                    color: c.fg0
                                }
                                Repeater {
                                    model: [
                                        { label: "T:", value: modelData.maxtempC + "/" + modelData.mintempC + "°C", color: c.red },
                                        { label: "H:", value: modelData.hourly[4].humidity + "%",      color: c.accent },
                                        { label: "R:", value: modelData.hourly[4].chanceofrain + "%",  color: c.bccent }
                                    ]
                                    delegate: RowLayout {
                                        required property var modelData
                                        spacing: 4
                                        Text {
                                            text: modelData.label
                                            font.pixelSize: 10
                                            font.family: "JetBrains Mono Nerd Font"
                                            color: modelData.color
                                        }
                                        Text {
                                            text: modelData.value
                                            font.pixelSize: 10
                                            font.family: "JetBrains Mono Nerd Font"
                                            color: c.fg0
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
