import QtQuick
import Quickshell
import Quickshell.Io
import "../themes/"
import "../services/"

Item {
    id: clockRoot
    required property Colors c
    required property Glyphs g
    implicitHeight: parent.height
    implicitWidth: row.implicitWidth

    property bool   hoveredDateTime: false
    property bool   hoveredWeather:  false
    property string weatherIcon:     WeatherService.icon
    property string weatherTemp:     WeatherService.tempC

    SystemClock { id: clk; precision: SystemClock.Seconds }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const wasVisible = datePanel.visible
            rightPanels.closeAll()
            if (!wasVisible) datePanel.showAt(parent)
        }
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        Row {
            id: dateTimeRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            HoverHandler { onHoveredChanged: clockRoot.hoveredDateTime = hovered }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                color: clockRoot.hoveredDateTime ? c.accent : c.fg0
                font { pixelSize: 12; family: "JetBrains Mono Nerd Font" }
                text: {
                    clk.seconds
                    const d = new Date()
                    const months = ["January","February","March","April","May","June",
                                    "July","August","September","October","November","December"]
                    const day = d.getDate()
                    const suf = (day > 3 && day < 21) ? "th" : ({1:"st",2:"nd",3:"rd"}[day % 10] ?? "th")
                    return months[d.getMonth()] + " " + day + suf
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                color: clockRoot.hoveredDateTime ? c.accent : c.fg0
                font { pixelSize: 12; bold: true; family: "JetBrains Mono Nerd Font" }
                text: clk.hours.toString().padStart(2,"0") + ":" + clk.minutes.toString().padStart(2,"0")
            }
        }

        Rectangle {
            width: 1; height: 14; color: c.bg3
            anchors.verticalCenter: parent.verticalCenter
        }

        Row {
            id: weatherRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            visible: weatherIcon !== ""

            HoverHandler { onHoveredChanged: clockRoot.hoveredWeather = hovered }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: weatherIcon
                font { family: gwnce.name; pixelSize: 14 }
                color: clockRoot.hoveredWeather ? c.accent : c.fg0
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: weatherTemp
                font { family: "JetBrains Mono Nerd Font"; pixelSize: 11 }
                color: clockRoot.hoveredWeather ? c.accent : c.fg2
            }
        }
    }
}
