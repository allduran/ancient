import Quickshell
import QtQuick
import QtQuick.Shapes
import "../../config"
import "../../services"
import "../common"
import "../bar"

// Contenido de la pantalla de bloqueo (diseño "altar")
Item {
    id: root

    Component.onCompleted: input.forceActiveFocus()

    // Fondo: textura del modo, oscurecida
    TexturePanel {
        anchors.fill: parent
        shade: 0.35
    }

    // Brillo central del color del modo + viñeta
    Shape {
        anchors.fill: parent
        ShapePath {
            strokeWidth: 0
            fillGradient: RadialGradient {
                centerX: root.width / 2
                centerY: root.height * 0.46
                centerRadius: root.height * 0.5
                focalX: centerX
                focalY: centerY
                GradientStop {
                    position: 0
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)
                }
                GradientStop {
                    position: 1
                    color: "transparent"
                }
            }
            PathRectangle {
                width: root.width
                height: root.height
            }
        }
        ShapePath {
            strokeWidth: 0
            fillGradient: RadialGradient {
                centerX: root.width / 2
                centerY: root.height / 2
                centerRadius: root.width * 0.65
                focalX: centerX
                focalY: centerY
                GradientStop {
                    position: 0.45
                    color: "transparent"
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(0, 0, 0, 0.85)
                }
            }
            PathRectangle {
                width: root.width
                height: root.height
            }
        }
    }

    // ── Franja superior ──
    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: Theme.stripHeight
        color: Theme.stone
        Image {
            anchors.fill: parent
            source: "../../assets/textures/" + Theme.stripTexture
            fillMode: Image.Tile
        }
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 1
            color: Theme.edge
        }
        Text {
            anchors {
                left: parent.left
                leftMargin: 14
                verticalCenter: parent.verticalCenter
            }
            text: "ANCIENT"
            color: Theme.textSoft
            font.family: "monospace"
            font.pixelSize: 11
            font.bold: true
            font.letterSpacing: 2
        }
    }

    // ── Altar ──
    Rectangle {
        id: altar
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -root.height * 0.03
        width: 460
        height: inner.height + 12
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

        TexturePanel {
            id: inner
            x: 6
            y: 6
            width: parent.width - 12
            height: content.implicitHeight + 64
            accentTop: true
            border.width: 1
            border.color: Theme.edgeDark

            Rectangle {      // oscurecido hacia abajo, para leer bien
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: Qt.rgba(0, 0, 0, 0.15)
                    }
                    GradientStop {
                        position: 1
                        color: Qt.rgba(0, 0, 0, 0.55)
                    }
                }
            }

            Column {
                id: content
                anchors {
                    top: parent.top
                    topMargin: 34
                    left: parent.left
                    right: parent.right
                    leftMargin: 30
                    rightMargin: 30
                }
                spacing: 22

                // Dial grande (el mismo de la barra, escalado)
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 200
                    height: 200
                    Clock {
                        anchors.centerIn: parent
                        scale: 200 / Theme.dialSize
                    }
                }

                // Separador con rombo
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 170
                        height: 1
                        color: Theme.frameEdge
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 7
                        height: 7
                        rotation: 45
                        color: Theme.accent
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 170
                        height: 1
                        color: Theme.frameEdge
                    }
                }

                // Usuario
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 14

                    Rectangle {
                        width: 84
                        height: 48
                        border.width: 1
                        border.color: Theme.accentLight
                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: Qt.darker(Theme.playerColors[0], 1.8)
                            }
                            GradientStop {
                                position: 1
                                color: Qt.darker(Theme.playerColors[0], 4.0)
                            }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: (Quickshell.env("USER") || "?").charAt(0).toUpperCase()
                            color: Theme.text
                            font.pixelSize: 26
                            font.bold: true
                        }
                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                                margins: 1
                            }
                            height: 3
                            color: Theme.playerColors[0]
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text {
                            text: (Quickshell.env("USER") || "").toUpperCase()
                            color: Theme.text
                            font.pixelSize: 20
                            font.bold: true
                            font.letterSpacing: 2.4
                        }
                        Text {
                            text: "SESIÓN BLOQUEADA"
                            color: Theme.accentLight
                            font.family: "monospace"
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }
                }

                // Contraseña
                Column {
                    width: parent.width
                    spacing: 8

                    Row {
                        width: parent.width
                        height: 42
                        spacing: 4

                        Rectangle {
                            width: parent.width - 50
                            height: parent.height
                            color: Qt.rgba(0.02, 0.024, 0.027, 0.85)
                            border.width: 1
                            border.color: input.activeFocus ? Theme.accent : Theme.frameEdge

                            TextInput {
                                id: input
                                anchors {
                                    fill: parent
                                    leftMargin: 12
                                    rightMargin: 12
                                }
                                verticalAlignment: TextInput.AlignVCenter
                                echoMode: TextInput.Password
                                passwordCharacter: "•"
                                color: Theme.accentLight
                                font.family: "monospace"
                                font.pixelSize: 18
                                font.letterSpacing: 4
                                enabled: !Lock.busy
                                onTextChanged: Lock.password = text
                                Keys.onReturnPressed: Lock.tryUnlock()
                                Keys.onEnterPressed: Lock.tryUnlock()
                                Keys.onEscapePressed: text = ""
                            }
                        }

                        Rectangle {
                            width: 46
                            height: parent.height
                            border.width: 1
                            border.color: Theme.edgeDark
                            gradient: Gradient {
                                GradientStop {
                                    position: 0
                                    color: Theme.accent
                                }
                                GradientStop {
                                    position: 1
                                    color: Qt.darker(Theme.accent, 1.8)
                                }
                            }
                            Text {
                                anchors.centerIn: parent
                                text: Lock.busy ? "…" : "➜"
                                color: "#0a0c0e"
                                font.pixelSize: 18
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Lock.tryUnlock()
                            }
                        }
                    }

                    Text {
                        text: Lock.busy ? "Comprobando…" : Lock.failed ? "Contraseña incorrecta" : " "
                        color: Lock.failed ? Theme.danger : Theme.textMute
                        font.pixelSize: 13
                    }
                }
            }
        }
    }

    // Al fallar, vaciar el campo
    Connections {
        target: Lock
        function onFailedChanged() {
            if (Lock.failed)
                input.text = "";
        }
    }

    // ── Franja inferior: consejo + energía ──
    Rectangle {
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        height: 46
        color: Theme.stone
        Image {
            anchors.fill: parent
            source: "../../assets/textures/" + Theme.stripTexture
            fillMode: Image.Tile
        }
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
                leftMargin: 14
                verticalCenter: parent.verticalCenter
            }
            text: "<font color='" + Theme.accentLight + "'><b>CONSEJO</b></font>&nbsp;&nbsp; Escribe tu contraseña y pulsa Enter."
            textFormat: Text.StyledText
            color: Theme.textSoft
            font.pixelSize: 14
        }

        Row {
            anchors {
                right: parent.right
                rightMargin: 14
                verticalCenter: parent.verticalCenter
            }
            spacing: 4
            Repeater {
                model: [
                    {
                        glyph: "☾",
                        danger: false,
                        run: () => Session.suspend()
                    },
                    {
                        glyph: "↻",
                        danger: false,
                        run: () => Session.reboot()
                    },
                    {
                        glyph: "⏻",
                        danger: true,
                        run: () => Session.poweroff()
                    }
                ]
                Rectangle {
                    required property var modelData
                    width: 36
                    height: 32
                    color: modelData.danger ? Qt.rgba(0.23, 0.09, 0.07, 0.8) : Qt.rgba(0, 0, 0, 0.45)
                    border.width: 1
                    border.color: modelData.danger ? Theme.danger : Qt.rgba(1, 1, 1, 0.12)
                    Text {
                        anchors.centerIn: parent
                        text: modelData.glyph
                        color: Theme.textSoft
                        font.pixelSize: 16
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.run()
                    }
                }
            }
        }
    }
}
