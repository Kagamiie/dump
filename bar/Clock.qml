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
    property string _dateLabel:      ""

    // Build date string once, then use function
    function _buildDateLabel() {
        const d = new Date()
        const months = ["January","February","March","April","May","June",
                        "July","August","September","October","November","December"]
        const day = d.getDate()
        const dayNum = day % 10
        const lastTwoDigits = day % 100

        let suffix = "th"
        if (lastTwoDigits < 4 || lastTwoDigits > 20) {
            suffix = dayNum === 1 ? "st" : dayNum === 2 ? "nd" : dayNum === 3 ? "rd" : "th"
        }

        _dateLabel = months[d.getMonth()] + " " + day + suffix
    }

    Component.onCompleted: _buildDateLabel()

    // Midnight timer - reset date at midnight
    Timer {
        id: _midnightTimer
        interval: {
            const now = new Date()
            const midnight = new Date(now)
            midnight.setDate(midnight.getDate() + 1)
            midnight.setHours(0, 0, 0, 0)
            return midnight - now
        }
        repeat: false
        running: true
        onTriggered: {
            clockRoot._buildDateLabel()
            interval = 86400000
            repeat = true
        }
    }

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

        // Date/Time display
        Row {
            id: dateTimeRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            HoverHandler { onHoveredChanged: clockRoot.hoveredDateTime = hovered }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                color: clockRoot.hoveredDateTime ? c.accent : c.fg0
                font { pixelSize: 12; family: "JetBrains Mono Nerd Font" }
                text: clockRoot._dateLabel
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                color: clockRoot.hoveredDateTime ? c.accent : c.fg0
                font { pixelSize: 12; bold: true; family: "JetBrains Mono Nerd Font" }
                text: clk.hours.toString().padStart(2,"0") + ":" +
                      clk.minutes.toString().padStart(2,"0")
            }
        }

        Rectangle {
            width: 1; height: 14; color: c.bg3
            anchors.verticalCenter: parent.verticalCenter
        }

        // Weather display
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
