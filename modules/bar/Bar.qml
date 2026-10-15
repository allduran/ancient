import Quickshell
import Quickshell.Wayland
import QtQuick
import Quickshell.Hyprland
import "../../services"
import "../../config"

PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    WlrLayershell.namespace: "ancient-bar"
    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.dialSize + 4   // alto suficiente para el dial que cuelga
    exclusiveZone: Theme.stripHeight     // las ventanas solo respetan la franja
    color: "transparent"

    // Reciben ratón: la franja y el bloque central. Lo demás deja pasar los clics.
    mask: Region {
        item: strip
        Region {
            item: center
            intersection: Intersection.Combine   // sumar a la franja, no intersecar
        }
    }

    // ── Franja de piedra a lo ancho ──
    Rectangle {
        id: strip
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
            fillMode: Image.Tile        // repite la textura en horizontal
        }

        // Botón: mostrar/ocultar la lista de ventanas
        Rectangle {
            anchors {
                left: parent.left
                leftMargin: 6
                verticalCenter: parent.verticalCenter
            }
            width: 26
            height: 22
            color: ShellState.windowListOpen ? Theme.frameTop : Theme.slot
            border.width: 1
            border.color: ShellState.windowListOpen ? Theme.accent : Theme.edge

            Text {
                anchors.centerIn: parent
                text: "☰"
                color: ShellState.windowListOpen ? Theme.accentLight : Theme.textSoft
                font.pixelSize: 13
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: ShellState.windowListOpen = !ShellState.windowListOpen
            }
        }

        // Stats (esquina derecha)
        Stats {
            anchors {
                right: parent.right
                rightMargin: 10
                verticalCenter: parent.verticalCenter
            }
        }

        // Filo bronce
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 1
            color: Theme.edge
        }
        // Sombra bajo el filo
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.bottom
            }
            height: 2
            color: Theme.edgeDark
        }
    }

    // ── Bloque central (cuelga de la franja) ──
    Row {
        id: center
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
        }
        spacing: 4

        Workspaces {}

        // Ventanas abiertas (verde). Clic: mostrar/ocultar la lista
        Shield {
            value: Hyprland.toplevels.values.length
            onClicked: ShellState.windowListOpen = !ShellState.windowListOpen
        }

        Clock {}

        // Notificaciones (rojo). Clic: borrarlas todas
        Shield {
            value: Notifs.count
            topColor: Theme.dangerTop
            bottomColor: Theme.dangerBot
            accent: Theme.danger
            onClicked: Notifs.clearAll()
        }

        PinnedApps {}
    }
}
