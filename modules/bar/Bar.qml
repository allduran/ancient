import Quickshell
import Quickshell.Wayland
import QtQuick
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
            source: "../../assets/textures/strip-stone.png"
            fillMode: Image.Tile        // repite la textura en horizontal
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
        Clock {}
        PinnedApps {}
    }
}
