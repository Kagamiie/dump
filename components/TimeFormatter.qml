pragma Singleton
import QtQuick

QtObject {
    function formatSeconds(seconds, showHours = false) {
        const sec = Math.floor(seconds)
        const hours = Math.floor(sec / 3600)
        const minutes = Math.floor((sec % 3600) / 60)
        const secs = sec % 60

        if (showHours || hours > 0) {
            return hours.toString().padStart(2, "0") + ":" +
                   minutes.toString().padStart(2, "0") + ":" +
                   secs.toString().padStart(2, "0")
        } else {
            return minutes.toString().padStart(2, "0") + ":" +
                   secs.toString().padStart(2, "0")
        }
    }
}
