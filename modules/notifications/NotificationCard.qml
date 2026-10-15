import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import "../../config"
import "../../services"

// Un popup de notificación
Item {
    id: card
    required property var notif
    readonly property bool critical: notif.urgency === NotificationUrgency.Critical
    readonly property color accent: critical ? Theme.danger : Theme.positive
    property real life: 1                     // 1 → 0 durante el cooldown

    implicitHeight: frame.height

    function iconSource(name) {
        if (!name)
            return "";
        if (name.startsWith("/"))
            return "file://" + name;
        if (name.includes("://"))
            return name;
        return Quickshell.iconPath(name, "dialog-information");
    }

    // Cooldown: al terminar, oculta el popup (las urgentes no caducan)
    NumberAnimation on life {
        from: 1
        to: 0
        duration: Theme.notifTimeout
        running: !card.critical
        paused: hover.containsMouse
        onFinished: Notifs.hidePopup(card.notif)
    }

    Rectangle {
        id: frame
        width: card.width
        height: content.implicitHeight + 2
        color: Qt.rgba(0.05, 0.06, 0.07, 0.95)
        border.width: 1
        border.color: Theme.edge

        // Entrada deslizando desde la derecha
        NumberAnimation on x {
            from: card.width
            to: 0
            duration: 220
            easing.type: Easing.OutCubic
        }

        // Hover (pausa) + clic en el cuerpo
        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                const acts = card.notif.actions;
                for (let i = 0; i < acts.length; i++)
                    if (acts[i].identifier === "default")
                        acts[i].invoke();
                Notifs.hidePopup(card.notif);
            }
        }

        // Filo de color a la izquierda
        Rectangle {
            x: 1
            y: 1
            width: 3
            height: parent.height - 2
            color: card.accent
        }

        Column {
            id: content
            x: 4
            y: 1
            width: parent.width - 5

            // Cabecera: icono + app + cerrar
            Rectangle {
                width: parent.width
                height: 22
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

                Image {
                    id: appIcon
                    anchors {
                        left: parent.left
                        leftMargin: 6
                        verticalCenter: parent.verticalCenter
                    }
                    width: 14
                    height: 14
                    sourceSize: Qt.size(28, 28)
                    source: card.iconSource(card.notif.appIcon)
                }
                Text {
                    anchors {
                        left: appIcon.right
                        leftMargin: 6
                        right: closeBtn.left
                        verticalCenter: parent.verticalCenter
                    }
                    text: (card.notif.appName || "Notification").toUpperCase()
                    elide: Text.ElideRight
                    color: Theme.accentLight
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 1.5
                }
                Text {
                    id: closeBtn
                    anchors {
                        right: parent.right
                        rightMargin: 8
                        verticalCenter: parent.verticalCenter
                    }
                    text: "✕"
                    color: closeArea.containsMouse ? Theme.danger : Theme.textMute
                    font.pixelSize: 12
                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.notif.dismiss()      // la borra del todo
                    }
                }
            }

            // Cuerpo: imagen opcional + título + texto
            Row {
                padding: 8
                spacing: 10
                width: parent.width

                Image {
                    visible: card.notif.image !== ""
                    width: visible ? 40 : 0
                    height: 40
                    sourceSize: Qt.size(80, 80)
                    fillMode: Image.PreserveAspectCrop
                    source: card.notif.image
                }

                Column {
                    width: parent.width - 16 - (card.notif.image !== "" ? 50 : 0)
                    spacing: 2

                    Text {
                        width: parent.width
                        text: card.notif.summary
                        elide: Text.ElideRight
                        color: Theme.text
                        font.pixelSize: 13
                        font.bold: true
                    }
                    Text {
                        width: parent.width
                        visible: text !== ""
                        text: card.notif.body
                        textFormat: Text.StyledText
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        color: Theme.textSoft
                        font.pixelSize: 12
                    }
                }
            }

            // Botones de acción
            Row {
                visible: actionRepeater.count > 0
                leftPadding: 8
                bottomPadding: 8
                spacing: 6

                Repeater {
                    id: actionRepeater
                    model: card.notif.actions

                    Rectangle {
                        required property var modelData
                        visible: modelData.identifier !== "default"
                        width: actionText.implicitWidth + 18
                        height: 22
                        color: actionArea.containsMouse ? Theme.frameTop : Theme.slot
                        border.width: 1
                        border.color: Theme.edge

                        Text {
                            id: actionText
                            anchors.centerIn: parent
                            text: modelData.text
                            color: Theme.textSoft
                            font.pixelSize: 11
                        }
                        MouseArea {
                            id: actionArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.invoke()
                        }
                    }
                }
            }

            // Barra de cooldown dorada
            Rectangle {
                width: parent.width * card.life
                height: 2
                color: card.critical ? Theme.danger : Theme.accent
            }
        }
    }
}
