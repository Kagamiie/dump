import QtQuick
import QtQuick.Layouts
import "../../themes/"

Text {
    required property Colors c
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.WordWrap
    font { pixelSize: 10; family: "JetBrains Mono Nerd Font"; italic: true }
    color: c.fg2

    property int _idx: Math.floor(Math.random() * 10)

    readonly property var _quotes: [
        "This is the world of the recycled vessel, created to avoid the destruction of all.",
        "The Black Scrawl. A lost destiny. A white book. A false truth.",
        "The dragon's corpse brought death to the world.",
        "The sky falls with the dragon. The world ends this day.",
        "All is paid. All is sacrifice.",
        "Every beam of light is an invitation to death.",
        "Foolish human. Foolish human. Foolish vessel.",
        "Do not bring back the light. Do not bring back the vessel.",
        "The song of man has been drowned out.",
        "The puppet priest collects the accursed prayers."
    ]

    Timer {
        interval: 300000
        repeat: true
        running: true
        onTriggered: parent._idx = (parent._idx + 1) % parent._quotes.length
    }

    text: "\"" + _quotes[_idx] + "\""
}
