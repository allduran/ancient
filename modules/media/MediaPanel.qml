import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import QtQuick
import "../../config"
import "../../services"
import "../common"

// Panel "Now Playing"
PanelWindow {
    id: win
    visible: ShellState.mediaOpen && Media.player !== null

    WlrLayershell.namespace: "ancient-media"
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

    readonly property var p: Media.player

    function close() {
        ShellState.mediaOpen = false;
    }

    onVisibleChanged: if (visible)
        Qt.callLater(() => keys.forceActiveFocus())

    // Teclado: Q W E como habilidades, Esc cierra
    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape)
                win.close();
            else if (e.key === Qt.Key_Q)
                Media.previous();
            else if (e.key === Qt.Key_W)
                Media.toggle();
            else if (e.key === Qt.Key_E)
                Media.next();
        }
    }

    // Clic fuera = cerrar (sin oscurecer la pantalla)
    MouseArea {
        anchors.fill: parent
        onClicked: win.close()
    }

    component Toggle: Rectangle {
        id: tg
        property string text
        property bool on: false
        signal clicked
        width: tgText.implicitWidth + 20
        height: 24
        color: Qt.rgba(0, 0, 0, 0.4)
        border.width: 1
        border.color: on ? Theme.accent : Theme.edge
        Text {
            id: tgText
            anchors.centerIn: parent
            text: tg.text
            color: tg.on ? Theme.accentLight : Theme.textMute
            font.family: "monospace"
            font.pixelSize: 11
            font.bold: true
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: tg.clicked()
        }
    }

    component Ability: Rectangle {
        id: ab
        property string key
        property string glyph
        property bool primary: false
        signal clicked
        width: 54
        height: 54
        border.width: 1
        border.color: primary ? Theme.accentLight : Theme.edgeDark
        gradient: Gradient {
            GradientStop {
                position: 0
                color: ab.primary ? Theme.accent : Theme.frameTop
            }
            GradientStop {
                position: 1
                color: ab.primary ? Qt.darker(Theme.accent, 1.8) : Theme.frameBot
            }
        }
        Text {
            anchors.centerIn: parent
            text: ab.glyph
            color: ab.primary ? "#0a0c0e" : Theme.text
            font.pixelSize: 20
            font.bold: true
        }
        Rectangle {
            x: 3
            y: 3
            width: 16
            height: 16
            color: Theme.slot
            border.width: 1
            border.color: Theme.edge
            Text {
                anchors.centerIn: parent
                text: ab.key
                color: Theme.text
                font.family: "monospace"
                font.pixelSize: 10
                font.bold: true
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: ab.clicked()
        }
    }

    // ── Marco de bronce ──
    Rectangle {
        x: 38
        y: Theme.stripHeight + 6
        width: 440
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

        MouseArea {
            anchors.fill: parent
        }    // los clics dentro no cierran

        TexturePanel {
            id: inner
            x: 6
            y: 6
            width: parent.width - 12
            height: col.implicitHeight
            border.width: 1
            border.color: Theme.edgeDark

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: Qt.rgba(0, 0, 0, 0.2)
                    }
                    GradientStop {
                        position: 1
                        color: Qt.rgba(0, 0, 0, 0.55)
                    }
                }
            }

            Column {
                id: col
                width: parent.width

                // Cabecera + pestañas por reproductor
                Rectangle {
                    width: parent.width
                    height: 30
                    color: Qt.rgba(0, 0, 0, 0.25)
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
                            leftMargin: 10
                            verticalCenter: parent.verticalCenter
                        }
                        text: "NOW PLAYING"
                        color: Theme.accentLight
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1.8
                    }
                    Row {
                        anchors {
                            right: parent.right
                            rightMargin: 6
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 3
                        Repeater {
                            model: Media.players
                            Toggle {
                                required property var modelData
                                text: modelData.identity.toUpperCase()
                                on: modelData === win.p
                                onClicked: Media.preferred = modelData.identity
                            }
                        }
                    }
                }

                // Portada + datos
                Row {
                    padding: 14
                    spacing: 14
                    width: parent.width

                    Rectangle {
                        width: 120
                        height: 120
                        color: Theme.slot
                        border.width: 2
                        border.color: Theme.accentLight
                        clip: true
                        Image {
                            anchors.fill: parent
                            anchors.margins: 2
                            source: win.p ? win.p.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            sourceSize: Qt.size(240, 240)
                        }
                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                                margins: 2
                            }
                            height: 4
                            color: Theme.positive
                        }
                    }

                    Column {
                        width: parent.width - 120 - 42
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Text {
                            width: parent.width
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            text: win.p ? win.p.trackTitle : ""
                            color: Theme.text
                            font.pixelSize: 20
                            font.bold: true
                        }
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: win.p ? win.p.trackArtist : ""
                            color: Theme.positive
                            font.pixelSize: 15
                            font.bold: true
                        }
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: win.p ? win.p.trackAlbum : ""
                            color: Theme.textMute
                            font.pixelSize: 13
                        }
                    }
                }

                // Barra de progreso (experiencia). Clic = saltar
                Item {
                    width: parent.width
                    height: 16

                    Rectangle {
                        id: track
                        anchors {
                            left: parent.left
                            right: parent.right
                            leftMargin: 14
                            rightMargin: 14
                        }
                        height: 16
                        color: Theme.edgeDark
                        border.width: 1
                        border.color: Theme.edge

                        Rectangle {
                            x: 1
                            y: 1
                            height: parent.height - 2
                            width: (parent.width - 2) * Media.progress
                            gradient: Gradient {
                                GradientStop {
                                    position: 0
                                    color: Theme.accentLight
                                }
                                GradientStop {
                                    position: 1
                                    color: Qt.darker(Theme.accent, 1.8)
                                }
                            }
                        }
                        Rectangle {           // marcador brillante
                            x: (parent.width - 3) * Media.progress
                            y: -3
                            width: 3
                            height: 22
                            color: Theme.text
                        }
                        Text {
                            anchors.centerIn: parent
                            text: win.p ? Media.fmt(win.p.position) + " / " + Media.fmt(win.p.length) : ""
                            color: "white"
                            font.family: "monospace"
                            font.pixelSize: 11
                            font.bold: true
                            style: Text.Outline
                            styleColor: "#000000"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: win.p && win.p.canSeek ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: e => Media.seek(e.x / width)
                        }
                    }
                }

                // Controles
                Item {
                    width: parent.width
                    height: 82

                    Row {
                        anchors {
                            left: parent.left
                            leftMargin: 14
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 6
                        Ability {
                            key: "Q"
                            glyph: "⏮"
                            onClicked: Media.previous()
                        }
                        Ability {
                            key: "W"
                            glyph: win.p && win.p.isPlaying ? "⏸" : "▶"
                            primary: true
                            onClicked: Media.toggle()
                        }
                        Ability {
                            key: "E"
                            glyph: "⏭"
                            onClicked: Media.next()
                        }
                    }

                    Column {
                        anchors {
                            right: parent.right
                            rightMargin: 14
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 6

                        Row {
                            anchors.right: parent.right
                            spacing: 4
                            Toggle {
                                text: "⇄ SHUFFLE"
                                visible: win.p !== null && win.p.shuffleSupported
                                on: win.p !== null && win.p.shuffle
                                onClicked: Media.toggleShuffle()
                            }
                            Toggle {
                                text: !win.p ? "↻ LOOP" : win.p.loopState === MprisLoopState.Track ? "↻ CANCIÓN" : win.p.loopState === MprisLoopState.Playlist ? "↻ LISTA" : "↻ LOOP"
                                visible: win.p !== null && win.p.loopSupported
                                on: win.p !== null && win.p.loopState !== MprisLoopState.None
                                onClicked: Media.cycleLoop()
                            }
                        }

                        Row {
                            anchors.right: parent.right
                            spacing: 6
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "VOL"
                                color: Theme.textMute
                                font.family: "monospace"
                                font.pixelSize: 10
                                font.bold: true
                            }
                            Rectangle {
                                width: 120
                                height: 10
                                color: Theme.edgeDark
                                border.width: 1
                                border.color: Theme.edge
                                Rectangle {
                                    x: 1
                                    y: 1
                                    height: parent.height - 2
                                    width: (parent.width - 2) * Audio.volume
                                    gradient: Gradient {
                                        GradientStop {
                                            position: 0
                                            color: Theme.manaTop
                                        }
                                        GradientStop {
                                            position: 1
                                            color: Theme.manaBot
                                        }
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: e => Audio.setVolume(e.x / width)
                                    onWheel: w => w.angleDelta.y > 0 ? Audio.up() : Audio.down()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
