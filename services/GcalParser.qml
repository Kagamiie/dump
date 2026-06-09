import QtQuick

QtObject {
    function parseLine(line) {
        if (!line || !line.trim()) return null

        const parts = line.split("\t")
        if (parts.length < 10) return null
        if (parts[2].trim() === "start_time") return null

        // Helper sécurisé
        const safeTrim = (str) => (str && typeof str === 'string') ? str.trim() : ""
        const safeExtract = (str, delimiter, idx) => {
            const trimmed = safeTrim(str)
            if (!trimmed) return ""
            const split = trimmed.split(delimiter)
            return safeTrim(split[idx] ?? "")
        }

        const courseCode = safeExtract(parts[0], null, 0) // juste trim
        const courseName = safeExtract(parts[1], null, 0)

        return {
            date:       safeTrim(parts[1]),
            start:      safeTrim(parts[2]),
            end:        safeTrim(parts[4]),
            courseCode: courseCode,
            courseName: courseName,
            salle: parts.length > 10 ? safeExtract(parts[10], " - ", 0) : "",
            prof:  parts.length > 11 ? safeExtract(parts[11], ";", 0) : ""
        }
    }
}
