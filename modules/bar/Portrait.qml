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
    clip: true      // recorta el "arte" de fondo a los bordes del retrato
    border.width: 1
    border.color: Theme.edgeDark
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

    // "Arte" de fondo: el mismo icono ampliado, recortado y atenuado
    Image {
        anchors.centerIn: parent
        width: parent.width * 1.4
        height: width
        sourceSize: Qt.size(96, 96)
        source: p.icon
        visible: p.icon !== ""
        opacity: 0.05
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

    Image {
        anchors.centerIn: parent
        width: 24
        height: 24
        sourceSize: Qt.size(48, 48)
        source: p.icon
        visible: p.icon !== ""
    }

    Text {
        anchors.centerIn: parent
        visible: p.icon === ""
        text: p.label
        color: Theme.label
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
        height: 3
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
