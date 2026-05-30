import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../themes/"

PanelWindow {
    id: root
    required property Colors c

    visible: false
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    anchors { top: true; left: true; right: true; bottom: true }

    property int mode: 0

    onVisibleChanged: {
        if (visible) {
            Qt.callLater(() => searchBar.searchInput.forceActiveFocus())
        }
    }

    function toggle() {
        visible = !visible
        if (visible) {
            mode = 0
            query = ""
            selectedIndex = 0
            currentPage = 0
            nixQuery = ""
            nixResults = []
            nixStatus = ""
            nixSelected = 0
            logic.updateFilter()  // add this
            Qt.callLater(() => searchInput.forceActiveFocus())  // move focus here
        }
    }

    function switchMode(m) {
        mode = m
        query = ""
        selectedIndex = 0
        currentPage = 0
        nixQuery = ""
        nixResults = []
        nixStatus = ""
        nixSelected = 0
        searchInput.text = ""
        logic.updateFilter()  // add this
        Qt.callLater(() => searchInput.forceActiveFocus())
    }

    // Apps state
    property string query:         ""
    property var    apps:          []
    property var    filtered:      []
    property int    selectedIndex: 0
    property int    currentPage:   0

    readonly property int cols:      4
    readonly property int rows:      3
    readonly property int perPage:   cols * rows
    readonly property int pageCount: Math.max(1, Math.ceil(filtered.length / perPage))
    readonly property var pageItems: filtered.slice(currentPage * perPage, (currentPage + 1) * perPage)

    onFilteredChanged: { currentPage = 0; selectedIndex = 0 }

    function selectIndex(i) {
        if (i < 0) i = Math.max(0, filtered.length - 1)
        if (i >= filtered.length) i = 0
        const page = Math.floor(i / perPage)
        if (page !== currentPage) currentPage = page
        selectedIndex = i
    }

    // Nix state
    property string nixQuery:    ""
    property var    nixResults:  []
    property int    nixSelected: 0
    property bool   nixLoading:  false
    property string nixStatus:   ""

    LauncherLogic { id: logic; root: root }

    // Backdrop
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.45
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    MouseArea { anchors.fill: parent; onClicked: root.visible = false }

    Rectangle {
        id: panel
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.14)
        width: 720
        height: mainCol.implicitHeight
        color: c.bg0
        border { width: 1; color: c.bg3 }

        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            id: mainCol
            anchors { left: parent.left; right: parent.right; top: parent.top }
            spacing: 0

            SearchBar {
                id: searchBar
                Layout.fillWidth: true
                root: root
                panel: panel
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: c.bg3 }

            AppsGrid {
                visible: root.mode === 0
                Layout.fillWidth: true
                root: root
                panel: panel
            }

            NixSearch {
                visible: root.mode === 1
                Layout.fillWidth: true
                root: root
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: c.bg3 }

            LauncherFooter {
                Layout.fillWidth: true
                root: root
            }
        }
    }
}
