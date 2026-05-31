import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../themes/"

Item {
    Process {
        id: openUrl
        property string cmd: ""
        command: ["sh", "-c", cmd]
    }
    required property Colors c
    implicitWidth: 268
    implicitHeight: calCol.implicitHeight

    property int displayYear:  new Date().getFullYear()
    property int displayMonth: new Date().getMonth() + 1

    function prevMonth() {
        if (displayMonth === 1) { displayMonth = 12; displayYear-- }
        else displayMonth--
    }
    function nextMonth() {
        if (displayMonth === 12) { displayMonth = 1; displayYear++ }
        else displayMonth++
    }
    function resetToday() {
        displayYear  = new Date().getFullYear()
        displayMonth = new Date().getMonth() + 1
    }

    function buildDays() {
        const today    = new Date()
        const first    = new Date(displayYear, displayMonth - 1, 1)
        let startWday  = (first.getDay() + 6) % 7  // lundi = 0
        const lastDay  = new Date(displayYear, displayMonth, 0).getDate()
        const prevLast = new Date(displayYear, displayMonth - 1, 0).getDate()
        const totalRows = Math.ceil((startWday + lastDay) / 7)
        const cells     = totalRows * 7
        const days      = []

        for (let i = 0; i < cells; i++) {
            const offset = i - startWday
            let day, other, realDate

            if (offset < 0) {
                day      = prevLast + offset + 1
                other    = true
                realDate = new Date(displayYear, displayMonth - 2, day)
            } else if (offset < lastDay) {
                day      = offset + 1
                other    = false
                realDate = new Date(displayYear, displayMonth - 1, day)
            } else {
                day      = offset - lastDay + 1
                other    = true
                realDate = new Date(displayYear, displayMonth, day)
            }

            const isToday = realDate.getFullYear() === today.getFullYear() &&
                            realDate.getMonth()    === today.getMonth()    &&
                            realDate.getDate()     === today.getDate()

            days.push({
                day,
                isToday,
                isOtherMonth: other,
                realYear:  realDate.getFullYear(),
                realMonth: realDate.getMonth() + 1,
                realDay:   realDate.getDate()
            })
        }
        return days
    }

    readonly property var days: buildDays()

    ColumnLayout {
        id: calCol
        anchors { left: parent.left; right: parent.right }
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: innerCol.implicitHeight
            color: c.bg0
            border.width: 1
            border.color: c.bg3

            ColumnLayout {
                id: innerCol
                anchors { left: parent.left; right: parent.right }
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    color: c.bg1

                    Rectangle {
                        anchors { top: parent.top; left: parent.left; right: parent.right }
                        height: 1; color: c.bg3
                    }
                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width: 1; color: c.bg3
                    }
                    Rectangle {
                        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                        width: 1; color: c.bg3
                    }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 10 }
                        spacing: 0

                        Text {
                            Layout.fillWidth: true
                            text: {
                                const months = ["January","February","March","April","May","June",
                                                "July","August","September","October","November","December"]
                                return months[displayMonth - 1] + " " + displayYear
                            }
                            font { pixelSize: 11; family: "JetBrains Mono Nerd Font" }
                            color: monthMa.containsMouse ? c.accent : c.fg0

                            MouseArea {
                                id: monthMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: resetToday()
                            }
                        }

                        Repeater {
                            model: ["◀", "▶"]
                            delegate: Item {
                                width: 28; height: 32
                                required property string modelData
                                required property int    index

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                                    color: navMa.containsMouse ? c.accent : c.fg2
                                }

                                MouseArea {
                                    id: navMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: index === 0 ? prevMonth() : nextMonth()
                                }

                                Rectangle {
                                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                                    width: 1; color: c.bg3
                                }
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: c.bg3 }

                Row {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8

                    Repeater {
                        model: ["Mo","Tu","We","Th","Fr","Sa","Su"]
                        delegate: Item {
                            width: (268 - 16) / 7
                            height: 20
                            required property string modelData
                            required property int    index

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                                color: index >= 5 ? c.red : c.bg4
                            }
                        }
                    }
                }

                Grid {
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                    Layout.bottomMargin: 8
                    columns: 7
                    property real cellW: (268 - 16 - spacing * 6) / 7

                    Repeater {
                        model: days
                        delegate: Rectangle {
                            required property var modelData
                            width:  parent.cellW
                            height: parent.cellW
                            color:  modelData.isToday      ? c.accent
                                  : modelData.isOtherMonth ? c.bg2
                                  : c.bg1

                            Text {
                                anchors.centerIn: parent
                                text: modelData.day
                                font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                                color: modelData.isToday      ? c.bg0
                                     : modelData.isOtherMonth ? c.bg4
                                     : c.fg0
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const y  = modelData.realYear
                                    const m  = modelData.realMonth.toString().padStart(2, "0")
                                    const d  = modelData.realDay.toString().padStart(2, "0")
                                    openUrl.cmd = "xdg-open 'https://calendar.google.com/calendar/r/day/" + y + "/" + m + "/" + d + "'"
                                    openUrl.running = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
