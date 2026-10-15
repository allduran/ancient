import QtQuick
import "../../config"

// Retrato estilo Dota: fondo tintado, icono y barra de color abajo.
Rectangle {
    id: p
    property color tint: "#444444"
    property color barColor: "transparent"
    property string icon: ""
    property string label: ""      // se muestra si no hay icono
    property bool active: false
    property bool empty: false
    signal clicked

    width: Theme.portraitW
    height: Theme.portraitH
    gradient: Gradient {
        GradientStop {
            position: 0
            color: p.empty ? Theme.slot : Qt.darker(p.tint, 1.8)
        }
        GradientStop {
            position: 1
            color: p.empty ? Theme.slot : Qt.darker(p.tint, 4.0)
        }
    }

    // Brillo superior
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        height: 1
        color: Qt.rgba(1, 1, 1, p.empty ? 0.03 : 0.14)
    }

    // Separador derecho
    Rectangle {
        anchors {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
        width: 1
        color: Theme.edgeDark
    }

    Image {
        anchors.centerIn: parent
        width: 20
        height: 20
        sourceSize: Qt.size(40, 40)
        source: p.icon
        visible: p.icon !== ""
    }

    Text {
        anchors.centerIn: parent
        visible: p.icon === ""
        text: p.label
        color: "#4a463c"
        font.pixelSize: 12
        font.bold: true
    }

    // Barra de color inferior
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 4
        color: p.barColor
    }

    // Marco blanco si está activo
    Rectangle {
        anchors.fill: parent
        visible: p.active
        color: "transparent"
        border.width: 2
        border.color: Theme.text
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: p.clicked()
    }
}
