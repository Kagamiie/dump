import QtQuick
import Quickshell.Io

Item {
    required property var root
    visible: false

    Component.onCompleted: _loadApps.running = true

    property var _loadApps: Process {
        command: ["bash", "-c",
            "IFS=: read -ra dirs <<< \"$XDG_DATA_DIRS\"; " +
            "for dir in \"${dirs[@]}\"; do [ -d \"$dir/applications\" ] || continue; " +
            "for f in \"$dir\"/applications/*.desktop; do [ -f \"$f\" ] || continue; " +
            "n=$(grep -m1 '^Name=' \"$f\" | cut -d= -f2-); " +
            "e=$(grep -m1 '^Exec=' \"$f\" | cut -d= -f2- | sed 's/ *%[a-zA-Z]//g'); " +
            "i=$(grep -m1 '^Icon=' \"$f\" | cut -d= -f2-); " +
            "nd=$(grep -m1 '^NoDisplay=' \"$f\" | cut -d= -f2-); " +
            "[ \"$nd\" != 'true' ] && [ -n \"$n\" ] && [ -n \"$e\" ] && echo \"$n|$e|$i\"; " +
            "done; done | sort -u"]
        stdout: SplitParser {
            splitMarker: "\n"
            property var buf: []
            onRead: line => {
                const parts = line.split("|")
                if (parts.length >= 2 && parts[0].trim())
                    buf.push({ name: parts[0].trim(), exec: parts[1].trim(), icon: parts[2]?.trim() ?? "" })
            }
        }
        onRunningChanged: { if (running) stdout.buf = [] }
        onExited: {
            root.apps = stdout.buf.slice()
            updateFilter()
        }
    }

    function updateFilter() {
        const q = root.query.toLowerCase()
        if (!q) {
            root.filtered = root.apps
            return
        }

        root.filtered = root.apps.filter(a => a.name.toLowerCase().includes(q))
    }

    property var _nixTimer: Timer {
        interval: 500
        repeat: false
        onTriggered: _executeNixSearch()
    }

    function _executeNixSearch() {
        if (root.nixQuery.length < 2) return
        root.nixLoading = true
        nixProc.q = root.nixQuery
        nixProc.running = false
        Qt.callLater(() => nixProc.running = true)
    }

    property var _nixProc: Process {
        id: nixProc
        property string q: ""
        command: ["timeout", "10", "nix", "search", "nixpkgs", q, "--json",
                  "--extra-experimental-features", "nix-command flakes"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.nixLoading = false
                try {
                    const data = JSON.parse(this.text)
                    const entries = Object.entries(data)
                    root.nixResults = entries.map(([key, v]) => ({
                        attr: key.replace("legacyPackages.x86_64-linux.", ""),
                        version: v.version ?? "",
                        desc: v.description ?? "No description",
                        broken: false,
                        unfree: false
                    })).slice(0, 30)
                    root.nixStatus = root.nixResults.length > 0
                        ? root.nixResults.length + " result" + (root.nixResults.length > 1 ? "s" : "")
                        : "No results"
                } catch(e) {
                    console.warn("LauncherLogic: nix parse error:", e)
                    root.nixStatus = "No results"
                    root.nixResults = []
                }
            }
        }
    }

    property var _clipProc: Process { property string t: ""; command: ["wl-copy", "--", t] }
    property var _notifProc: Process { property string m: ""; command: ["notify-send", "-t", "2000", "nixpkgs", m] }
    property var _launchProc: Process { property string cmd: ""; command: ["sh", "-c", cmd + " &"] }

    function copyAttr(attr) {
        _clipProc.t = attr
        _clipProc.running = false
        Qt.callLater(() => _clipProc.running = true)
        _notifProc.m = "Copied: " + attr
        _notifProc.running = false
        Qt.callLater(() => _notifProc.running = true)
        root.visible = false
    }

    function launch(app) {
        _launchProc.cmd = app.exec
        _launchProc.running = true
        root.visible = false
    }

    Connections {
        target: root

        function onQueryChanged() { updateFilter() }

        function onNixQueryChanged() {
            root.nixSelected = 0
            if (root.nixQuery.length < 2) {
                root.nixResults = []
                root.nixStatus = ""
                root.nixLoading = false
                return
            }
            _nixTimer.restart()
        }
    }
}
