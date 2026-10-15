import QtQuick
import QtQuick.Shapes
import "../../config"

// Marco de bronce con un extremo cortado en diagonal.
// Lo que pongas dentro se coloca en fila.
Item {
    id: frame
    property bool slantLeft: true          // diagonal a la izquierda (true) o a la derecha
    readonly property int slant: 14
    default property alias content: row.data

    implicitWidth: row.implicitWidth + slant + 5
    implicitHeight: row.implicitHeight + 6

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 1
            strokeColor: Theme.frameEdge
            fillGradient: LinearGradient {
                x1: 0
                y1: 0
                x2: 0
                y2: frame.height
                GradientStop {
                    position: 0
                    color: Theme.frameTop
                }
                GradientStop {
                    position: 1
                    color: Theme.frameBot
                }
            }
            startX: 0
            startY: 0
            PathLine {
                x: frame.width
                y: 0
            }
            PathLine {
                x: frame.slantLeft ? frame.width : frame.width - frame.slant
                y: frame.height
            }
            PathLine {
                x: frame.slantLeft ? frame.slant : 0
                y: frame.height
            }
            PathLine {
                x: 0
                y: 0
            }
        }
    }

    Row {
        id: row
        x: frame.slantLeft ? frame.slant + 2 : 3
        y: 3
    }
}
