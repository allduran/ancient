import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes
import "../../config"
import "../../services"
import "../common"

// "¿Abandonar la partida?": menú de sesión con acciones como habilidades
PanelWindow {
    id: menu
    visible: Session.menuOpen

    WlrLayershell.namespace: "ancient-session"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    readonly property var actions: [
        {
            key: Qt.Key_L,
            label: "L",
            name: "Bloquear",
            icon: "lock.svg",
            tint: "#2c4a6e",
            hold: false,
            run: () => Session.lock()
        },
        {
            key: Qt.Key_S,
            label: "S",
            name: "Suspender",
            icon: "suspend.svg",
            tint: "#3a2c5e",
            hold: false,
            run: () => Session.suspend()
        },
        {
            key: Qt.Key_O,
            label: "O",
            name: "Cerrar sesión",
            icon: "logout.svg",
            tint: "#4a4232",
            hold: true,
            run: () => Session.logout()
        },
        {
            key: Qt.Key_R,
            label: "R",
            name: "Reiniciar",
            icon: "reboot.svg",
            tint: "#5a4a1e",
            hold: true,
            run: () => Session.reboot()
        },
        {
            key: Qt.Key_P,
            label: "P",
            name: "Apagar",
            icon: "power.svg",
            tint: "#6e2a20",
            hold: true,
            run: () => Session.poweroff()
        }
    ]

    function close() {
        Session.menuOpen = false;
    }

    // Cierra primero y ejecuta después (el bloqueo no debe abrirse encima del menú)
    function run(fn) {
        close();
        pending.fn = fn;
        pending.restart();
    }

    Timer {
        id: pending
        property var fn: null
        interval: 150
        onTriggered: if (fn)
            fn()
    }

    // Pedir el foco cuando la ventana ya está en pantalla (en el mismo instante se pierde)
    onVisibleChanged: if (visible)
        Qt.callLater(() => keys.forceActiveFocus())

    // Teclado: L/S ejecutan al momento; O/R/P hay que mantenerlas
    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape) {
                menu.close();
                return;
            }
            if (e.isAutoRepeat)
                return;
            for (let i = 0; i < menu.actions.length; i++)
                if (menu.actions[i].key === e.key)
                    buttons.itemAt(i).press();
        }
        Keys.onReleased: e => {
            if (e.isAutoRepeat)
                return;
            for (let i = 0; i < menu.actions.length; i++)
                if (menu.actions[i].key === e.key)
                    buttons.itemAt(i).release();
        }
    }

    // Fondo oscurecido: clic fuera = cancelar
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)
        MouseArea {
            anchors.fill: parent
            onClicked: menu.close()
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 720
        height: col.implicitHeight + 2
        color: Theme.stone
        border.width: 1
        border.color: Theme.frameEdge

        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: col
            x: 1
            y: 1
            width: parent.width - 2

            // Título
            TexturePanel {
                width: parent.width
                height: 56
                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    height: 2
                    color: Theme.accent
                }
                Row {
                    anchors.centerIn: parent
                    spacing: 14
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 9
                        height: 9
                        rotation: 45
                        color: Theme.accent
                    }
                    Text {
                        text: "¿ABANDONAR LA PARTIDA?"
                        color: Theme.accentLight
                        font.pixelSize: 22
                        font.bold: true
                        font.letterSpacing: 3
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 9
                        height: 9
                        rotation: 45
                        color: Theme.accent
                    }
                }
            }

            // Habilidades
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                topPadding: 34
                bottomPadding: 24
                spacing: 22

                Repeater {
                    id: buttons
                    model: menu.actions

                    Column {
                        id: ability
                        required property var modelData
                        spacing: 8

                        property real progress: 0          // 0 → 1 mientras se mantiene

                        function press() {
                            if (!modelData.hold) {
                                menu.run(modelData.run);
                                return;
                            }
                            fill.restart();
                        }
                        function release() {
                            if (!modelData.hold)
                                return;
                            fill.stop();
                            progress = 0;
                        }

                        NumberAnimation {
                            id: fill
                            target: ability
                            property: "progress"
                            from: 0
                            to: 1
                            duration: 1500
                            onFinished: {
                                ability.progress = 0;
                                menu.run(ability.modelData.run);
                            }
                        }

                        Rectangle {
                            id: slot
                            width: 96
                            height: 96
                            clip: true
                            border.width: 1
                            border.color: slotArea.containsMouse ? Theme.accentLight : Theme.edgeDark
                            gradient: Gradient {
                                GradientStop {
                                    position: 0
                                    color: ability.modelData.tint
                                }
                                GradientStop {
                                    position: 1
                                    color: Qt.darker(ability.modelData.tint, 2.6)
                                }
                            }

                            Image {
                                anchors.centerIn: parent
                                width: 40
                                height: 40
                                sourceSize: Qt.size(80, 80)        // nítido aunque sea SVG
                                source: "../../assets/icons/" + ability.modelData.icon
                            }

                            // Cooldown: la zona oscura se va comiendo en sentido horario
                            Shape {
                                anchors.fill: parent
                                visible: ability.progress > 0
                                ShapePath {
                                    strokeWidth: 0
                                    fillColor: Qt.rgba(0, 0, 0, 0.62)
                                    startX: slot.width / 2
                                    startY: slot.height / 2
                                    PathAngleArc {
                                        moveToStart: false
                                        centerX: slot.width / 2
                                        centerY: slot.height / 2
                                        radiusX: slot.width
                                        radiusY: slot.height
                                        startAngle: -90 + 360 * ability.progress
                                        sweepAngle: 360 * (1 - ability.progress)
                                    }
                                    PathLine {
                                        x: slot.width / 2
                                        y: slot.height / 2
                                    }
                                }
                            }

                            // Marco de acento mientras se mantiene pulsado
                            Rectangle {
                                anchors.fill: parent
                                visible: ability.progress > 0
                                color: "transparent"
                                border.width: 2
                                border.color: Theme.accentLight
                            }

                            // Tecla en la esquina
                            Rectangle {
                                x: 4
                                y: 4
                                width: 20
                                height: 20
                                color: Theme.slot
                                border.width: 1
                                border.color: Theme.edge
                                Text {
                                    anchors.centerIn: parent
                                    text: ability.modelData.label
                                    color: Theme.text
                                    font.family: "monospace"
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: slotArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onPressed: ability.press()
                                onReleased: ability.release()
                                onCanceled: ability.release()
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: ability.progress > 0 ? "Mantén… " + Math.round(ability.progress * 100) + "%" : ability.modelData.name
                            color: ability.progress > 0 ? Theme.accentLight : ability.modelData.key === Qt.Key_P ? "#e07a6e" : Theme.textSoft
                            font.pixelSize: 15
                            font.bold: ability.progress > 0
                        }
                    }
                }
            }

            // Pie
            Rectangle {
                width: parent.width
                height: 42
                color: Qt.rgba(0, 0, 0, 0.3)
                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                    }
                    height: 1
                    color: Theme.edge
                }
                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 18
                        verticalCenter: parent.verticalCenter
                    }
                    text: "<font color='" + Theme.accentLight + "'><b>L S O R P</b></font> o clic · cerrar sesión, reiniciar y apagar: <b>mantener pulsado</b>"
                    textFormat: Text.StyledText
                    color: Theme.textMute
                    font.pixelSize: 13
                }
                Text {
                    anchors {
                        right: parent.right
                        rightMargin: 18
                        verticalCenter: parent.verticalCenter
                    }
                    text: "ESC cancelar"
                    color: Theme.textMute
                    font.family: "monospace"
                    font.pixelSize: 11
                    font.bold: true
                }
            }
        }
    }
}
