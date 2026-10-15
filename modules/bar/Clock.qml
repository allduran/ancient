import Quickshell
import QtQuick
import QtQuick.Shapes
import "../../config"

Item {
    id: dial
    width: Theme.dialSize
    height: Theme.dialSize

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property real hours: clock.date.getHours() + clock.date.getMinutes() / 60
    readonly property bool isDay: hours >= 7 && hours < 19

    // Aro exterior: azul (noche) abajo, dorado (día) arriba
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 2
            strokeColor: Theme.edgeDark
            fillGradient: ConicalGradient {
                centerX: dial.width / 2
                centerY: dial.height / 2
                angle: 270                      // empieza abajo (medianoche)
                GradientStop {
                    position: 0.00
                    color: Theme.night
                }
                GradientStop {
                    position: 0.20
                    color: Theme.night
                }
                GradientStop {
                    position: 0.30
                    color: Theme.day
                }   // amanecer
                GradientStop {
                    position: 0.70
                    color: Theme.day
                }
                GradientStop {
                    position: 0.80
                    color: Theme.night
                } // anochecer
                GradientStop {
                    position: 1.00
                    color: Theme.night
                }
            }
            PathAngleArc {
                centerX: dial.width / 2
                centerY: dial.height / 2
                radiusX: dial.width / 2 - 1
                radiusY: dial.height / 2 - 1
                startAngle: 0
                sweepAngle: 360
            }
        }
    }

    // Disco interior con aro dorado
    Rectangle {
        anchors.fill: parent
        anchors.margins: 5
        radius: width / 2
        border.width: 2
        border.color: Theme.gold
        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#2a2519"
            }
            GradientStop {
                position: 1
                color: "#0b0a08"
            }
        }
    }

    // Aguja: gira con la hora (medianoche abajo, mediodía arriba)
    Item {
        anchors.fill: parent
        rotation: dial.hours / 24 * 360 + 180

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            width: 2
            height: 10
            color: Theme.text
        }
    }

    // Icono + hora + fecha
    Column {
        anchors.centerIn: parent
        spacing: 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: dial.isDay ? "☀" : "☾"
            color: dial.isDay ? Theme.goldLight : "#9fb8e0"
            font.pixelSize: 12
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: Theme.text
            font.pixelSize: 17
            font.bold: true
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "ddd d").toUpperCase()
            color: Theme.textSoft
            font.pixelSize: 9
            font.letterSpacing: 1
        }
    }
}
