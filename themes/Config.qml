// themes/Config.qml
pragma Singleton
import QtQuick

QtObject {
    readonly property string wallpapersDir: Quickshell.env("HOME") + "/Documents/Medias/Wallpapers"
    readonly property string avatarPath:    Quickshell.env("HOME") + "/Documents/Medias/avatars/89704351.png"
}

// Bar.qml
// property string avatarSource: "file://" + Config.avatarPath

// WallpaperPicker.qml
// command: ["bash", "-c", "find " + Config.wallpapersDir + " -maxdepth 1 ..."]
