import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "./bar/"
import "./themes/"
import "./popup/"
import "./popup/dashboard"
import "./popup/date"
import "./popup/notification"
import "./popup/glyphs"
import "./popup/launcher"

ShellRoot {
    id: root

    property Colors c: Colors {}
    property Glyphs g: Glyphs {}
    property bool dnd: false

    FontLoader { id: gwnce; source: "/home/ks/.local/share/fonts/gwnce.ttf" }

    QtObject {
        id: rightPanels
        function closeAll() {
            datePanel.hide()
            dashboard.hide()
            systrayMenu.visible = false
        }
    }

    IpcHandler {
        target: "shell"
        function launcher() { launcherroot.toggle() }
        function glyphs()   { glyphPreview.toggle() }
        function dnd()      { root.dnd = !root.dnd }
    }

    LauncherRoot  { id: launcherroot; c: root.c }
    GlyphsPreview { id: glyphPreview; c: root.c }
    Daemon        { id: notifDaemon;  c: root.c; dnd: root.dnd }
    DatePanel     { id: datePanel;    c: root.c; g: root.g }
    SystrayMenu   { id: systrayMenu;  c: root.c }
    Dashboard     { id: dashboard;    c: root.c; g: root.g; shellRoot: root }
    VolumeOSD     { id: volumeOsd;    c: root.c; g: root.g }

    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: 38
            color: "transparent"
            exclusiveZone: height

            Bar {
                anchors.fill: parent
                screen: win.screen
                c: root.c
                g: root.g
                appLauncher: launcher
            }
        }
    }
}
