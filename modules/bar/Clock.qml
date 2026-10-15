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
        border.color: Theme.accent
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Theme.dialTop
            }
            GradientStop {
                position: 1
                color: Theme.dialBot
            }
        }
    }

    // Líquido con oleaje: dorado de día, azul de noche
    Canvas {
        id: liquid
        anchors.fill: parent
        anchors.margins: 7                 // dentro del aro dorado
        renderTarget: Canvas.FramebufferObject

        property real level: 0.55          // altura del líquido (0 vacío · 1 lleno)
        property real phase: 0
        property color tint: dial.isDay ? Theme.day : Theme.night
        Behavior on tint {
            ColorAnimation {
                duration: 3000
            }
        }   // fundido al amanecer/anochecer

        onPhaseChanged: requestPaint()
        onTintChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            const w = width, h = height, r = w / 2;
            const baseY = h * (1 - level);
            ctx.reset();

            // Recorte circular: nada se pinta fuera del disco
            ctx.beginPath();
            ctx.arc(r, r, r, 0, Math.PI * 2);
            ctx.clip();

            // Dibuja una ola rellena hacia abajo
            function wave(amp, len, speed, offset, alpha) {
                ctx.beginPath();
                ctx.moveTo(0, h);
                for (let x = 0; x <= w; x += 2)
                    ctx.lineTo(x, baseY + Math.sin(x / len + phase * speed + offset) * amp);
                ctx.lineTo(w, h);
                ctx.closePath();
                ctx.fillStyle = Qt.rgba(tint.r, tint.g, tint.b, alpha);
                ctx.fill();
            }

            wave(3.5, 9, 1.0, 0, 0.15);    // ola de fondo, más transparente
            wave(1.5, 7, -1.4, 2, 0.35);   // ola delantera, en sentido contrario
        }

        // ~30 fps: suficiente para que se vea fluido y gasta poco
        Timer {
            interval: 33
            repeat: true
            running: liquid.visible
            onTriggered: liquid.phase = (liquid.phase + 0.08) % (Math.PI * 20)
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
            color: dial.isDay ? Theme.accentLight : Theme.moon
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
