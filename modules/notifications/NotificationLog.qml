import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import "../../config"
import "../../services"
import "../common"

// Registro de avisos: todas las notificaciones guardadas, debajo del escudo rojo de la barra
PanelWindow {
    id: log
    visible: ShellState.notifsOpen

    WlrLayershell.namespace: "ancient-notif-log"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    readonly property var items: Notifs.list.slice().reverse()     // las nuevas arriba

    function close() {
        ShellState.notifsOpen = false;
    }
    function iconSource(name) {
        if (!name)
            return "";
        if (name.startsWith("/"))
            return "file://" + name;
        if (name.includes("://"))
            return name;
        return Quickshell.iconPath(name, "dialog-information");
    }
    function ago(n) {
        const t = Notifs.times[n.id];
        if (!t)
            return "";
        const m = Math.floor((Date.now() - t) / 60000);
        if (m < 1)
            return "ahora";
        if (m < 60)
            return "hace " + m + " min";
        const h = Math.floor(m / 60);
        return h < 24 ? "hace " + h + " h" : "hace " + Math.floor(h / 24) + " d";
    }
    // Clic en un aviso: su acción por defecto (abre la app que lo envió) y se cierra el registro
    function open(n) {
        const acts = n.actions;
        for (let i = 0; i < acts.length; i++) {
            if (acts[i].identifier === "default") {
                acts[i].invoke();
                break;
            }
        }
        close();
    }

    onVisibleChanged: if (visible)
        Qt.callLater(() => keys.forceActiveFocus())

    Item {
        id: keys
        focus: true
        Keys.onEscapePressed: log.close()
    }

    // Clic fuera = cerrar
    MouseArea {
        anchors.fill: parent
        onClicked: log.close()
    }

    Rectangle {
        id: frame
        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.dialSize + 10
        width: 440
        height: Math.min(560, 48 + 40 + Math.max(1, log.items.length) * 86 + 12)
        border.width: 1
        border.color: Theme.frameEdge
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Theme.frameTop
            }
            GradientStop {
                position: 1
                color: Theme.frameBot
            }
        }
        MouseArea {
            anchors.fill: parent        // los clics dentro no cierran
        }

        TexturePanel {
            anchors {
                fill: parent
                margins: 5
            }
            shade: 0.45
            accentTop: true
            border.width: 1
            border.color: Theme.edgeDark

            // Cabecera
            Rectangle {
                id: head
                width: parent.width
                height: 42
                color: Qt.rgba(0, 0, 0, 0.35)
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Theme.edge
                }
                Column {
                    x: 12
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: "REGISTRO DE AVISOS"
                        color: Theme.text
                        font.pixelSize: 14
                        font.bold: true
                        font.letterSpacing: 2
                    }
                    Text {
                        text: Notifs.count + (Notifs.count === 1 ? " aviso" : " avisos") + (Toggles.dnd ? " · no molestar activo" : "")
                        color: Theme.textMute
                        font.pixelSize: 11
                    }
                }
                Rectangle {
                    visible: Notifs.count > 0
                    anchors {
                        right: parent.right
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    width: clearText.implicitWidth + 20
                    height: 26
                    color: clearArea.containsMouse ? Theme.dangerTop : Qt.rgba(0, 0, 0, 0.4)
                    border.width: 1
                    border.color: clearArea.containsMouse ? Theme.danger : Theme.edge
                    Text {
                        id: clearText
                        anchors.centerIn: parent
                        text: "BORRAR TODO"
                        color: Theme.textSoft
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 1.4
                    }
                    MouseArea {
                        id: clearArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.clearAll()
                    }
                }
            }

            ListView {
                anchors {
                    top: head.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: 8
                }
                clip: true
                spacing: 4
                model: log.items
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
                    width: ListView.view.width
                    height: 82
                    color: rowArea.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(0, 0, 0, 0.35)
                    border.width: 1
                    border.color: row.critical ? Theme.danger : Theme.edgeDark

                    // Filo izquierdo: rojo si es crítico
                    Rectangle {
                        width: 3
                        height: parent.height
                        color: row.critical ? Theme.danger : Theme.accent
                    }

                    Image {
                        id: icon
                        x: 12
                        y: 10
                        width: 28
                        height: 28
                        source: row.modelData.image !== "" ? row.modelData.image : log.iconSource(row.modelData.appIcon)
                        sourceSize: Qt.size(56, 56)
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }

                    Column {
                        anchors {
                            left: icon.right
                            leftMargin: 10
                            right: closeBtn.left
                            rightMargin: 8
                            top: parent.top
                            topMargin: 8
                        }
                        spacing: 2
                        Row {
                            spacing: 8
                            Text {
                                text: (row.modelData.appName || "Aviso").toUpperCase()
                                color: Theme.accentLight
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 1.4
                            }
                            Text {
                                text: log.ago(row.modelData)
                                color: Theme.textMute
                                font.pixelSize: 10
                            }
                        }
                        Text {
                            width: parent.width
                            text: row.modelData.summary
                            elide: Text.ElideRight
                            color: Theme.text
                            font.pixelSize: 14
                            font.bold: true
                        }
                        Text {
                            width: parent.width
                            text: row.modelData.body
                            textFormat: Text.StyledText
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            color: Theme.textSoft
                            font.pixelSize: 12
                        }
                    }

                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: log.open(row.modelData)
                    }

                    // ✕: borrar este aviso
                    Text {
                        id: closeBtn
                        anchors {
                            right: parent.right
                            rightMargin: 10
                            top: parent.top
                            topMargin: 6
                        }
                        text: "✕"
                        color: closeArea.containsMouse ? Theme.text : Theme.textMute
                        font.pixelSize: 14
                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: row.modelData.dismiss()
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: log.items.length === 0
                    text: "SIN AVISOS"
                    color: Theme.textMute
                    font.pixelSize: 13
                    font.bold: true
                    font.letterSpacing: 2
                }
            }
        }
    }
}
