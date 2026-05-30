pragma Singleton
import QtQuick
import Quickshell.Io
import "../themes/"

QtObject {
    id: root

    property var    data:   null
    property string icon:   ""
    property string tempC:  ""

    property var _g: Glyphs {}

    property var _timer: Timer {
        interval: 7200000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: root._fetchProc.running = true
    }

    property var _fetchProc: Process {
        command: ["curl", "-s", "-A", "Mozilla/5.0", "https://wttr.in/?format=j1"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.data = JSON.parse(this.text)
                    const cur = root.data.current_condition[0]
                    const h   = new Date().getHours()
                    root.icon  = root._g.weatherGlyph(cur.weatherCode, h >= 6 && h < 21)
                    root.tempC = cur.temp_C + "°C"
                } catch(_) {}
            }
        }
    }
}
