// themes/Config.qml
pragma Singleton
import QtQuick

QtObject {
    readonly property string wallpapersDir: Quickshell.env("HOME") + "/Documents/Medias/Wallpapers"
    readonly property string avatarPath:    Quickshell.env("HOME") + "/Documents/Medias/avatars/89704351.png"
}
