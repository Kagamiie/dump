import QtQuick

QtObject {
    function parseLine(line) {
        if (!line.trim()) return null
        const parts = line.split("\t")
        if (parts.length < 10 || parts[2].trim() === "start_time") return null

        const rawTitle   = parts[9].trim().split(";")[0].trim()
        const dashIdx    = rawTitle.indexOf(" - ")
        const courseCode = dashIdx !== -1 ? rawTitle.substring(0, dashIdx).trim() : rawTitle
        const courseName = dashIdx !== -1 ? rawTitle.substring(dashIdx + 3).trim() : ""

        return {
            date:       parts[1].trim(),
            start:      parts[2].trim(),
            end:        parts[4].trim(),
            courseCode,
            courseName,
            salle: parts.length > 10 ? parts[10].trim().split(" - ")[0].trim() : "",
            prof:  parts.length > 11 ? parts[11].trim().split(";")[0].trim()   : ""
        }
    }
}
