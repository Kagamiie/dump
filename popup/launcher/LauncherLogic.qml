import QtQuick
import Quickshell.Io

Item {
    required property var root
    visible: false

    Component.onCompleted: loadApps.running = true

    property var loadApps: Process {
        command: ["bash", "-c",
            "IFS=: read -ra dirs <<< \"$XDG_DATA_DIRS\"; " +
            "for dir in \"${dirs[@]}\"; do " +
            "[ -d \"$dir/applications\" ] || continue; " +
            "for f in \"$dir\"/applications/*.desktop; do " +
            "[ -f \"$f\" ] || continue; " +
            "n=$(grep -m1 '^Name=' \"$f\" | cut -d= -f2); " +
            "e=$(grep -m1 '^Exec=' \"$f\" | cut -d= -f2 | sed 's/ *%[a-zA-Z]//g'); " +
            "i=$(grep -m1 '^Icon=' \"$f\" | cut -d= -f2); " +
            "nd=$(grep -m1 '^NoDisplay=' \"$f\" | cut -d= -f2); " +
            "[ \"$nd\" != 'true' ] && [ -n \"$n\" ] && [ -n \"$e\" ] && echo \"$n|$e|$i\"; " +
            "done; done | sort -u"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                const parts = line.split("|")
                if (parts.length >= 2 && parts[0].trim())
                    root.apps.push({ name: parts[0].trim(), exec: parts[1].trim(), icon: parts[2]?.trim() ?? "" })
            }
        }
        onExited: { root.apps = root.apps; root.updateFilter() }
    }

    function updateFilter() {
        const q = root.query.toLowerCase()
        if (!q) { root.filtered = root.apps.slice(); return }
        const starts   = root.apps.filter(a =>  a.name.toLowerCase().startsWith(q))
        const contains = root.apps.filter(a => !a.name.toLowerCase().startsWith(q) && a.name.toLowerCase().includes(q))
        root.filtered = [...starts, ...contains]
    }

    property var nixTimer: Timer {
        id: nixTimer
        interval: 400
        onTriggered: doNixSearch()
    }

    property var nixProc: Process {
        id: nixProc
        property string q: ""
        command: ["nix", "search", "nixpkgs", nixProc.q, "--json",
                  "--extra-experimental-features", "nix-command flakes"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.nixLoading = false
                try {
                    const data = JSON.parse(this.text)
                    const entries = Object.entries(data)
                    root.nixResults = entries.map(([key, v]) => ({
                        attr:    key.replace("legacyPackages.x86_64-linux.", ""),
                        version: v.version      ?? "",
                        desc:    v.description  ?? "No description",
                        broken:  false,
                        unfree:  false
                    })).slice(0, 30)
                    root.nixStatus = root.nixResults.length > 0
                        ? root.nixResults.length + " result" + (root.nixResults.length > 1 ? "s" : "")
                        : "No results"
                } catch(e) {
                    root.nixStatus = "No results"
                    root.nixResults = []
                }
            }
        }
    }

    function doNixSearch() {
        if (root.nixQuery.length < 2) return
        root.nixLoading = true
        root.nixStatus  = ""
        root.nixResults = []
        nixProc.q = root.nixQuery
        nixProc.running = false
        Qt.callLater(() => nixProc.running = true)
    }

    property var clipProc: Process {
        property string t: ""
        command: ["sh", "-c", "echo -n '" + t + "' | wl-copy"]
    }
    property var notifProc: Process {
        property string m: ""
        command: ["notify-send", "-t", "2000", "nixpkgs", m]
    }
    property var launchProc: Process {
        property string cmd: ""
        command: ["sh", "-c", cmd + " &"]
    }

    function copyAttr(attr) {
        clipProc.t = attr
        clipProc.running = false
        Qt.callLater(() => clipProc.running = true)
        notifProc.m = "Copied: " + attr
        notifProc.running = false
        Qt.callLater(() => notifProc.running = true)
        root.visible = false
    }

    function launch(app) {
        launchProc.cmd = app.exec
        launchProc.running = true
        root.visible = false
    }

    // Wire up reactive bindings
    Connections {
        target: root
        function onQueryChanged()    { updateFilter() }
        function onNixQueryChanged() {
            root.nixSelected = 0
            if (root.nixQuery.length < 2) {
                root.nixResults = []
                root.nixStatus  = ""
                root.nixLoading = false
                return
            }
            root.nixLoading = true
            root.nixResults = []
            root.nixStatus  = ""
            nixTimer.restart()
        }
    }
}
