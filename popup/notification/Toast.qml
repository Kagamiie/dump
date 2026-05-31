import QtQuick
import QtQuick.Layouts
import "../../themes/"

Item {
    id: root
    required property Colors c

    required property string notifSummary
    required property string notifBody
    required property string notifAppName
    required property string notifAppIcon
    required property real   notifTimeout
    required property var    notifActions
    required property string notifImage
    required property int    notifCount

    property int stackIndex: 0
    signal dismissed

    implicitWidth:  320
    implicitHeight: card.implicitHeight

    property bool _hovered: false

    function resetTimer() {
        progressAnim.stop()
        progressFill.width = 0
        progressAnim.start()
    }

    // FIX : ne pas démarrer l'animation avant que le composant soit visible et layouté.
    // "running: true" au niveau de la déclaration se déclenche AVANT le premier layout pass,
    // donc progressBar.width vaut 0 → l'animation va de 0 à 0 → invisible.
    // On démarre dans Component.onCompleted, après que la largeur soit connue.
    Component.onCompleted: {
        progressAnim.start()
    }

    NumberAnimation {
        id: progressAnim
        target: progressFill
        property: "width"
        from: 0
        // FIX : utilise la largeur du card (320) directement au lieu de progressBar.width
        // pour éviter la dépendance au layout pas encore calculé au démarrage
        to: 320
        duration: notifTimeout * 1000
        running: false  // démarré dans Component.onCompleted
        onFinished: root.dismissed()
    }

    // FIX : pause/resume basé sur _hovered (renommé pour éviter conflit avec prop QML "hovered")
    on_HoveredChanged: _hovered ? progressAnim.pause() : progressAnim.resume()

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root._hovered = true
        onExited:  root._hovered = false
        onClicked: root.dismissed()
        propagateComposedEvents: true
    }

    Rectangle {
        id: card
        width: 320
        implicitWidth:  320
        implicitHeight: mainCol.implicitHeight
        // FIX : les couleurs viennent de root.c (Colors passé en required property)
        // Si c est null au rendu → tout blanc. Vérification défensive.
        color:        root.c ? root.c.bg0 : "#1b1b1b"
        border.width: 1
        border.color: root.c ? root.c.bg3 : "#3c3c3c"

        ColumnLayout {
            id: mainCol
            width: 320
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Item {
                    width: 60; height: 60

                    Image {
                        anchors.centerIn: parent
                        width: 36; height: 36
                        source: {
                            if (notifImage !== "")
                                return notifImage
                            if (notifAppIcon.startsWith("file://"))
                                return decodeURIComponent(notifAppIcon)
                            if (notifAppIcon !== "")
                                return "image://icon/" + notifAppIcon.toLowerCase()
                            return ""
                        }
                        visible: notifImage !== "" || notifAppIcon !== ""
                        fillMode: Image.PreserveAspectFit
                    }

                    Image {
                        anchors.centerIn: parent
                        width: 32; height: 32
                        source: Qt.resolvedUrl("../../assets/notif/default.png")
                        fillMode: Image.PreserveAspectFit
                        smooth: true; mipmap: true
                        visible: notifImage === "" && notifAppIcon === ""
                    }

                    Rectangle {
                        visible: notifCount > 1
                        anchors { right: parent.right; bottom: parent.bottom; rightMargin: 4; bottomMargin: 4 }
                        width: 18; height: 18; radius: 9
                        color: root.c ? root.c.accent : "#a588d0"

                        Text {
                            anchors.centerIn: parent
                            text: notifCount > 9 ? "9+" : notifCount
                            font { pixelSize: 9; bold: true; family: "JetBrains Mono Nerd Font" }
                            color: root.c ? root.c.bg0 : "#1b1b1b"
                        }
                    }
                }

                Rectangle {
                    width: 1
                    Layout.fillHeight: true
                    color: root.c ? root.c.bg3 : "#3c3c3c"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    // Header titre
                    Rectangle {
                        Layout.fillWidth: true
                        height: 32
                        color: root.c ? root.c.bg1 : "#222222"

                        Rectangle {
                            anchors { top: parent.top; left: parent.left; right: parent.right }
                            height: 1
                            color: root.c ? root.c.bg3 : "#3c3c3c"
                        }
                        Rectangle {
                            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                            width: 1
                            color: root.c ? root.c.bg3 : "#3c3c3c"
                        }

                        Text {
                            anchors.centerIn: parent
                            width: parent.width - 16
                            text: notifSummary !== "" ? notifSummary : notifAppName
                            font { pixelSize: 11; family: "JetBrains Mono Nerd Font"; italic: true }
                            color: root.c ? root.c.fg0 : "#eeeeee"
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width; height: 1
                            color: root.c ? root.c.bg3 : "#3c3c3c"
                        }
                    }

                    // Corps
                    Text {
                        Layout.fillWidth: true
                        Layout.margins: 10
                        text: notifBody
                        font { pixelSize: 11; family: "JetBrains Mono Nerd Font" }
                        color: root.c ? root.c.fg1 : "#d4d4d4"
                        wrapMode: Text.WrapAnywhere
                        visible: notifBody !== ""
                    }

                    // Actions
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        visible: notifActions.length > 0

                        Rectangle {
                            Layout.fillWidth: true; height: 1
                            color: root.c ? root.c.bg3 : "#3c3c3c"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Repeater {
                                model: notifActions
                                delegate: Rectangle {
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    height: 26
                                    color: actMa.containsMouse
                                        ? (root.c ? root.c.bg2 : "#2e2e2e")
                                        : "transparent"

                                    Rectangle {
                                        visible: index > 0
                                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                                        width: 1
                                        color: root.c ? root.c.bg3 : "#3c3c3c"
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.text
                                        font { pixelSize: 10; family: "JetBrains Mono Nerd Font" }
                                        color: actMa.containsMouse
                                            ? (root.c ? root.c.accent : "#a588d0")
                                            : (root.c ? root.c.fg2   : "#ababab")
                                    }

                                    MouseArea {
                                        id: actMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: { modelData.invoke(); root.dismissed() }
                                    }
                                }
                            }
                        }
                    }

                    // Barre de progression
                    Rectangle {
                        id: progressBar
                        Layout.fillWidth: true
                        height: 3
                        color: root.c ? root.c.bg1 : "#222222"

                        Rectangle {
                            id: progressFill
                            height: parent.height
                            width: 0
                            color: root.c ? root.c.accent : "#a588d0"
                        }
                    }
                }
            }
        }
    }
}
