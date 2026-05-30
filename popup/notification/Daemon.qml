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

    anchors {
        right: true
        bottom: true
    }

    implicitWidth: notifCol.implicitWidth > 0 ? notifCol.implicitWidth + 16 : 1
    implicitHeight: notifCol.implicitHeight > 0 ? notifCol.implicitHeight + 16 : 1

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

    NotificationServer {
        id: server
        actionsSupported: true
        property var activeNotifs: ({})

        onNotification: notif => {
            if (root.dnd) { try { notif.expire() } catch(_) {} return }

            const comp = Qt.createComponent("Toast.qml")
            if (comp.status !== Component.Ready) return

            const file    = notif.hints["x-file"] ?? ""
            const appName = notif.appName ?? ""
            const key     = appName + "|" + (notif.hints["sender-pid"] ?? "")

            let actions = notif.actions.map(a => {
                const id   = a.identifier
                const text = a.text
                return {
                    id, text,
                    invoke: () => {
                        if (id === "save" && file !== "") {
                            const dest = (Quickshell.env("HOME") ?? "/home/user") + "/Documents/Medias/screenshots/" + file.split("/").pop()
                            saveProc.cmd = "cp '" + file + "' '" + dest + "'"
                            saveProc.running = true
                        } else if (id === "cancel" && file !== "") {
                            cancelProc.cmd = "rm -f '" + file + "'"
                            cancelProc.running = true
                        }
                        try { a.invoke() } catch(_) {}
                    }
                }
            })

            if (appName.toLowerCase().includes("vesktop") ||
                appName.toLowerCase().includes("discord")) {
                actions = notif.actions.map(a => {
                    const id   = a.identifier
                    const text = a.text
                    return {
                        id, text,
                        invoke: () => {
                            openProc.cmd = "vesktop"
                            openProc.running = true
                            try { a.invoke() } catch(_) {}
                        }
                    }
                })
            }

            if (appName.toLowerCase().includes("blueman")) {
                actions = notif.actions.map(a => {
                    const id   = a.identifier
                    const text = a.text
                    return {
                        id, text,
                        invoke: () => {
                            a.invoke()
                        }
                    }
                })
            }

            const existing = activeNotifs[key]
            if (existing && !existing.destroyed) {
                existing.notifSummary = notif.summary ?? ""
                existing.notifBody    = notif.body    ?? ""
                existing.notifAppIcon = notif.appIcon ?? ""
                existing.notifImage   = notif.image   ?? ""
                existing.notifActions = actions
                existing.notifCount   = (existing.notifCount ?? 1) + 1
                existing.resetTimer()
                try { notif.expire() } catch(_) {}
                return
            }

            const obj = comp.createObject(notifCol, {
                c:            root.c,
                notifSummary: notif.summary  ?? "",
                notifBody:    notif.body     ?? "",
                notifAppName: appName,
                notifAppIcon: notif.appIcon  ?? "",
                notifImage:   notif.image    ?? "",
                notifTimeout: notif.expireTimeout > 0 && notif.expireTimeout < 30000
                              ? notif.expireTimeout / 1000 : 5,
                notifActions: actions,
                notifCount:   1
            })

            if (!obj) return

            activeNotifs[key] = obj

            obj.dismissed.connect(() => {
                delete activeNotifs[key]
                try { notif.expire() } catch(_) {}
                obj.destroy()
            })
        }
    }

    ColumnLayout {
        id: notifCol
        anchors {
            right: parent.right
            bottom: parent.bottom
            rightMargin: 8
            bottomMargin: 8
        }
        spacing: 8
    }
}
