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
        id: fetchProc
        command: ["bash", "-c",
            "timeout 10 curl -s -m 10 --max-time 10 " +
            "-A 'Mozilla/5.0 (X11; Linux x86_64)' " +
            "'https://wttr.in/?format=j1' 2>/dev/null"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (!this.text || !this.text.trim()) {
                    console.warn("WeatherService: empty response, keeping cached data")
                    return
                }

                try {
                    const parsed = JSON.parse(this.text)

                    if (!parsed.current_condition || !Array.isArray(parsed.current_condition) ||
                        parsed.current_condition.length === 0) {
                        console.warn("WeatherService: invalid weather data structure")
                        return
                    }

                    root.data = parsed
                    const cur = parsed.current_condition[0]
                    const h = new Date().getHours()
                    root.icon = root._g.weatherGlyph(cur.weatherCode, h >= 6 && h < 21)
                    root.tempC = cur.temp_C + "°C"
                } catch(e) {
                    console.warn("WeatherService: failed to parse weather data:", e.toString())
                }
            }
        }

        onExited: code => {
            if (code === 124) {
                console.warn("WeatherService: curl timeout")
            } else if (code === 7) {
                console.warn("WeatherService: curl connection failed (network unreachable?)")
            } else if (code !== 0) {
                console.warn("WeatherService: curl exited with code", code)
            }
        }
    }
}
