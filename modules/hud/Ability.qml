import QtQuick
import QtQuick.Shapes
import "../../config"

// Habilidad del HUD: icono, tecla, nombre, encendida/apagada y cooldown
Rectangle {
    id: ab

    property string key: ""
    property string name: ""
    property string icon: ""
    property bool on: true              // false → oscurecida (apagada)
    property bool big: false            // la definitiva (R)
    property int cooldown: 0            // ms; 0 = sin cooldown
    property color topColor: Theme.frameTop
    property color bottomColor: Theme.frameBot
    property real cd: 0                 // 1 → 0 mientras se enfría
    signal activated
    // Usar la habilidad (clic o tecla)
    function trigger() {
        if (ab.cd > 0)
            return;          // aún en cooldown
        ab.activated();
        if (ab.cooldown > 0)
            cdAnim.restart();
        flash.restart();
    }

    width: big ? 64 : 56
    height: big ? 64 : 56
    y: big ? -4 : 0
    clip: true
    border.width: big ? 2 : 1
    border.color: big || area.containsMouse ? Theme.accentLight : Theme.edgeDark
    gradient: Gradient {
        GradientStop {
            position: 0
            color: ab.topColor
        }
        GradientStop {
            position: 1
            color: ab.bottomColor
        }
    }

    // Icono
    Image {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: ab.name !== "" ? -4 : 0
        source: ab.icon !== "" ? Qt.resolvedUrl("../../assets/icons/" + ab.icon) : ""
        sourceSize: Qt.size(ab.big ? 28 : 22, ab.big ? 28 : 22)
        opacity: ab.on ? 1 : 0.4
    }

    // Sombra inferior (volumen)
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: parent.height * 0.4
        gradient: Gradient {
            GradientStop {
                position: 0
                color: "transparent"
            }
            GradientStop {
                position: 1
                color: Qt.rgba(0, 0, 0, 0.55)
            }
        }
    }

    // Apagada: oscurecida
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: ab.on ? 0 : 0.5
        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }
    }

    // Nombre
    Text {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 3
        }
        text: ab.name
        color: ab.on ? Theme.textSoft : Theme.textMute
        font.family: "monospace"
        font.pixelSize: 8
        font.bold: true
    }

    // Cooldown: sector oscuro que se va cerrando en sentido horario
    Shape {
        anchors.fill: parent
        visible: ab.cd > 0
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: Qt.rgba(0, 0, 0, 0.7)
            strokeColor: "transparent"
            startX: ab.width / 2
            startY: ab.height / 2
            PathAngleArc {
                centerX: ab.width / 2
                centerY: ab.height / 2
                radiusX: ab.width
                radiusY: ab.width
                startAngle: -90 + 360 * (1 - ab.cd)
                sweepAngle: 360 * ab.cd
                moveToStart: false
            }
            PathLine {
                x: ab.width / 2
                y: ab.height / 2
            }
        }
    }
    Text {
        anchors.centerIn: parent
        visible: ab.cd > 0
        text: Math.ceil(ab.cd * ab.cooldown / 1000)
        color: Theme.text
        font.pixelSize: 20
        font.bold: true
        style: Text.Outline
        styleColor: "black"
    }

    // Tecla
    Rectangle {
        visible: ab.key !== ""
        x: 3
        y: 3
        width: 15
        height: 15
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

    NumberAnimation {
        id: cdAnim
        target: ab
        property: "cd"
        from: 1
        to: 0
        duration: ab.cooldown
    }

    Rectangle {
        id: glow
        anchors.fill: parent
        color: Theme.accentLight
        opacity: 0
        NumberAnimation on opacity {
            id: flash
            running: false
            from: 0.5
            to: 0
            duration: 250
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: ab.trigger()
    }
}
