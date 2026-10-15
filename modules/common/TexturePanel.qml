import QtQuick
import "../../config"

// Superficie con la textura del modo activo + filo superior opcional
Rectangle {
    id: panel
    property bool accentTop: false      // filo de acento arriba
    property bool edgeBottom: false     // filo oscuro abajo
    property real shade: 0.0            // 0 = textura tal cual · 0.5 = más oscura

    color: Theme.stone
    clip: true

    Image {
        anchors.fill: parent
        source: "../../assets/textures/" + Theme.panelTexture
        fillMode: Image.Tile
    }
    Rectangle {                          // oscurecido opcional (legibilidad)
        anchors.fill: parent
        color: "black"
        opacity: panel.shade
    }
    Rectangle {                          // brillo superior: da relieve
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        height: 1
        color: Qt.rgba(1, 1, 1, 0.08)
    }
    Rectangle {
        visible: panel.accentTop
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        height: 2
        color: Theme.accent
    }
    Rectangle {
        visible: panel.edgeBottom
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 1
        color: Theme.edge
    }
}
