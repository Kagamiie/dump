pragma Singleton
import QtQuick
import Quickshell

QtObject {
    readonly property string wallpapersDir: Quickshell.env("HOME") + "/Documents/Medias/Wallpapers"
    readonly property string avatarPath:    Quickshell.env("HOME") + "/Documents/Medias/avatars/89704351.png"
}
