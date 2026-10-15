import QtQuick
import QtQuick.Shapes
import "../../config"

// Escudo con un número: arriba recto, abajo en punta
Item {
    id: shield
    property int value: 0
    property color topColor: Theme.positiveTop
    property color bottomColor: Theme.positiveBot
    property color accent: Theme.positive
    signal clicked

    width: Theme.shieldW
    height: Theme.shieldH

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 1
            strokeColor: Theme.edgeDark
            fillGradient: LinearGradient {
                x1: 0
                y1: 0
                x2: 0
                y2: shield.height
                GradientStop {
                    position: 0
                    color: shield.topColor
                }
                GradientStop {
                    position: 1
                    color: shield.bottomColor
                }
            }
            startX: 0
            startY: 0
            PathLine {
                x: shield.width
                y: 0
            }
            PathLine {
                x: shield.width
                y: shield.height * 0.7
            }
            PathLine {
                x: shield.width / 2
                y: shield.height
            }        // punta
            PathLine {
                x: 0
                y: shield.height * 0.7
            }
            PathLine {
                x: 0
                y: 0
            }
        }
    }

    // Filo superior de color
    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: 2
        color: shield.accent
    }

    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -4
        text: shield.value
        color: shield.value > 0 ? Theme.text : Theme.textMute   // atenuado si es 0
        font.pixelSize: 19
        font.bold: true
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: shield.clicked()
    }
}
