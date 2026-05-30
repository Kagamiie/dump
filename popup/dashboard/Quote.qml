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
    text: "\"" + [
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
    ][Math.floor(Date.now() / 60000) % 10] + "\""
}
