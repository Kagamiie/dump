import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import Quickshell.Io
import "../../themes/"

PanelWindow {
    id: root
    required property Colors c
    required property bool dnd

    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    anchors { right: true; bottom: true }

    implicitWidth:  notifCol.implicitWidth  > 0 ? notifCol.implicitWidth  + 16 : 1
    implicitHeight: notifCol.implicitHeight > 0 ? notifCol.implicitHeight + 16 : 1

    property Component toastComponent: Component { Toast {} }

    // Cleanup de base
    Timer {
        interval: 60000; repeat: true; running: true
        onTriggered: {
            const keys = Object.keys(server.activeNotifs)
            for (const k of keys) {
                const obj = server.activeNotifs[k]
                if (!obj || obj._dismissing) {
                    delete server.activeNotifs[k]
                    if (obj) {
                        try { obj.destroy() } catch(e) {}
                    }
                }
            }
        }
    }

    // Limite de notifications
    function _enforceMaxNotifications() {
        const keys = Object.keys(server.activeNotifs)
        if (keys.length > server.maxNotifications) {
            // Supprimer les plus anciennes
            const toDelete = keys.slice(0, keys.length - server.maxNotifications)
            for (const k of toDelete) {
                const obj = server.activeNotifs[k]
                if (obj && !obj._dismissing) {
                    delete server.activeNotifs[k]
                    try { obj.destroy() } catch(e) {}
                }
            }
        }
    }

    Process {
        id: saveProc
        property string cmd: ""
        command: ["sh", "-c", cmd]
    }

    Process {
        id: cancelProc
        property string cmd: ""
        command: ["sh", "-c", cmd]
    }

    Process {
        id: openProc
        property string cmd: ""
        command: ["sh", "-c", cmd]
    }

    function buildActions(notif) {
        const file    = notif.hints["x-file"] ?? ""
        const appName = notif.appName ?? ""

        if (appName.toLowerCase().includes("vesktop") ||
            appName.toLowerCase().includes("discord")) {
            return notif.actions.map(a => ({
                id:     a.identifier,
                text:   a.text,
                invoke: () => {
                    openProc.cmd = "vesktop"
                    openProc.running = true
                    try { a.invoke() } catch(e) {
                        console.warn("Daemon: discord action invoke failed:", e)
                    }
                }
            }))
        }

        if (appName.toLowerCase().includes("blueman")) {
            return notif.actions.map(a => ({
                id:     a.identifier,
                text:   a.text,
                invoke: () => {
                    try { a.invoke() } catch(e) {
                        console.warn("Daemon: blueman action invoke failed:", e)
                    }
                }
            }))
        }

        return notif.actions.map(a => {
            const id   = a.identifier
            const text = a.text
            return {
                id, text,
                invoke: () => {
                    if (id === "save" && file !== "") {
                        const dest = (Quickshell.env("HOME") ?? "/home/user") +
                                     "/Documents/Medias/screenshots/" +
                                     file.split("/").pop()
                        saveProc.cmd = "cp '" + file + "' '" + dest + "'"
                        saveProc.running = true
                    } else if (id === "cancel" && file !== "") {
                        cancelProc.cmd = "rm -f '" + file + "'"
                        cancelProc.running = true
                    }
                    try { a.invoke() } catch(e) {
                        console.warn("Daemon: action invoke failed:", e)
                    }
                }
            }
        })
    }

    NotificationServer {
        id: server
        property var activeNotifs: ({})
        readonly property int maxNotifications: 20
        actionsSupported: true

        onNotification: notif => {
            if (root.dnd) {
                try { notif.expire() } catch(e) {
                    console.warn("Daemon: failed to expire DND notification:", e)
                }
                return
            }

            if (root.toastComponent.status !== Component.Ready) {
                console.error("Daemon: Toast component error:", root.toastComponent.errorString())
                return
            }

            const appName = notif.appName ?? ""
            const pid = notif.hints["sender-pid"]
            const key = pid
                ? String(pid) + "::" + appName
                : "nopid::" + appName.replace(/::/g, "__")

            const existing = server.activeNotifs[key]
            if (existing && !existing._dismissing) {
                // Stack: update la notification existante
                existing.notifSummary = notif.summary ?? ""
                existing.notifBody    = notif.body    ?? ""
                existing.notifAppIcon = notif.appIcon ?? ""
                existing.notifImage   = notif.image   ?? ""
                existing.notifActions = root.buildActions(notif)
                existing.notifCount   = (existing.notifCount ?? 1) + 1
                existing.resetTimer()
                try { notif.expire() } catch(e) {
                    console.warn("Daemon: failed to expire stacked notification:", e)
                }
                return
            }

            // Créer nouvelle notification
            const obj = root.toastComponent.createObject(notifCol, {
                c:            root.c,
                notifSummary: notif.summary  ?? "",
                notifBody:    notif.body     ?? "",
                notifAppName: appName,
                notifAppIcon: notif.appIcon  ?? "",
                notifImage:   notif.image    ?? "",
                notifTimeout: (notif.expireTimeout > 0 && notif.expireTimeout < 30000)
                              ? notif.expireTimeout / 1000 : 5,
                notifActions: root.buildActions(notif),
                notifCount:   1
            })

            if (!obj) {
                console.error("Daemon: failed to create Toast object")
                return
            }

            server.activeNotifs[key] = obj

            obj.dismissed.connect(function() {
                if (server.activeNotifs[key] === obj) {
                    delete server.activeNotifs[key]
                }
                try { notif.expire() } catch(e) {
                    console.warn("Daemon: failed to expire dismissed notification:", e)
                }

                Qt.callLater(() => {
                    try { obj.destroy() } catch(e) {
                        console.warn("Daemon: failed to destroy toast:", e)
                    }
                })
            })

            // Enforce limite après création
            root._enforceMaxNotifications()
        }
    }

    ColumnLayout {
        id: notifCol
        anchors {
            right:        parent.right
            bottom:       parent.bottom
            rightMargin:  8
            bottomMargin: 8
        }
        spacing: 8
    }
}
