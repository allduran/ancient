import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Shapes
import "../../config"
import "../../services"

// Rueda de chat: los 8 emojis más usados alrededor del ratón
PanelWindow {
    id: wheel
    visible: ShellState.emojiWheelOpen
    screen: Quickshell.screens.find(s => Hyprland.focusedMonitor && s.name === Hyprland.focusedMonitor.name) ?? null

    WlrLayershell.namespace: "ancient-emoji-wheel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    readonly property int outer: 170
    readonly property int inner: 64
    property real cx: width / 2
    property real cy: height / 2
    property bool placed: false        // ya sabemos dónde está el ratón
    property int hovered: -1           // sector bajo el ratón (−1 = centro)
    property real needle: -90          // ángulo de la aguja

    readonly property var items: Emoji.wheel
    readonly property var current: hovered >= 0 ? Emoji.find(items[hovered]) : null

    onVisibleChanged: {
        if (!visible)
            return;
        placed = false;
        hovered = -1;
        cursor.running = true;
        Qt.callLater(() => keys.forceActiveFocus());
    }

    function close() {
        ShellState.emojiWheelOpen = false;
    }
    function choose(i) {
        if (i < 0 || i >= items.length)
            return;
        close();
        Emoji.pick(items[i], true);
    }
    function openFull() {
        close();
        ShellState.emojiPickerOpen = true;
    }

    // Posición del ratón (global) → coordenadas de esta pantalla
    Process {
        id: cursor
        command: ["hyprctl", "cursorpos"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.split(",").map(Number);
                const mon = Hyprland.focusedMonitor;
                const x = p[0] - (mon ? mon.x : 0);
                const y = p[1] - (mon ? mon.y : 0);
                const m = wheel.outer + 10;
                wheel.cx = Math.max(m, Math.min(wheel.width - m, isNaN(x) ? wheel.width / 2 : x));
                wheel.cy = Math.max(m, Math.min(wheel.height - m, isNaN(y) ? wheel.height / 2 : y));
                wheel.placed = true;
            }
        }
    }

    // Ratón: elige el sector según el ángulo
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: m => {
            const dx = m.x - wheel.cx;
            const dy = m.y - wheel.cy;
            const dist = Math.sqrt(dx * dx + dy * dy);
            const ang = Math.atan2(dy, dx) * 180 / Math.PI;
            wheel.needle = ang;
            wheel.hovered = dist < wheel.inner ? -1 : ((Math.round((ang + 90) / 45) % 8) + 8) % 8;
        }
        onClicked: {
            if (wheel.hovered >= 0)
                wheel.choose(wheel.hovered);
            else
                wheel.openFull();
        }
    }

    // Teclas: 1–8 elegir · Tab todos · Esc cerrar
    Item {
        id: keys
        focus: true
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape)
                wheel.close();
            else if (e.key === Qt.Key_Tab)
                wheel.openFull();
            else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_8)
                wheel.choose(e.key - Qt.Key_1);
            else if ((e.key === Qt.Key_Return || e.key === Qt.Key_Enter) && wheel.hovered >= 0)
                wheel.choose(wheel.hovered);
            else
                return;
            e.accepted = true;
        }
    }

    // ── La rueda ──
    Item {
        id: disc
        x: wheel.cx - width / 2
        y: wheel.cy - height / 2
        width: wheel.outer * 2 + 12
        height: width
        opacity: wheel.placed ? 1 : 0
        scale: wheel.placed ? 1 : 0.85
        Behavior on opacity { NumberAnimation { duration: 120 } }
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }

        readonly property real c: width / 2

        // Aro exterior
        Rectangle {
            anchors.centerIn: parent
            width: wheel.outer * 2 + 8
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 2
            border.color: Theme.frameEdge
        }

        // Sectores
        Repeater {
            model: 8
            Shape {
                id: sector
                required property int index
                readonly property bool active: index === wheel.hovered
                readonly property real mid: -90 + 45 * index
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: sector.active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3) : Qt.rgba(0.04, 0.05, 0.055, 0.85)
                    strokeColor: sector.active ? Theme.accentLight : Theme.edge
                    strokeWidth: sector.active ? 2 : 1
                    PathAngleArc {
                        centerX: disc.c; centerY: disc.c
                        radiusX: wheel.outer; radiusY: wheel.outer
                        startAngle: sector.mid - 21.5
                        sweepAngle: 43
                    }
                    PathAngleArc {
                        centerX: disc.c; centerY: disc.c
                        radiusX: wheel.inner + 8; radiusY: wheel.inner + 8
                        startAngle: sector.mid + 21.5
                        sweepAngle: -43
                        moveToStart: false
                    }
                }
            }
        }

        // Emojis y teclas
        Repeater {
            model: wheel.items
            Column {
                required property string modelData
                required property int index
                readonly property real a: (-90 + 45 * index) * Math.PI / 180
                readonly property real r: (wheel.outer + wheel.inner + 8) / 2
                x: disc.c + r * Math.cos(a) - width / 2
                y: disc.c + r * Math.sin(a) - height / 2
                spacing: 2
                scale: index === wheel.hovered ? 1.2 : 1
                Behavior on scale { NumberAnimation { duration: 90 } }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData
                    font.pixelSize: 30
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 15; height: 15
                    color: "#0b0d10"
                    border.width: 1
                    border.color: Theme.edge
                    Text {
                        anchors.centerIn: parent
                        text: index + 1
                        color: Theme.textSoft
                        font.family: "monospace"; font.pixelSize: 9; font.bold: true
                    }
                }
            }
        }

        // Centro: aguja y nombre
        Rectangle {
            anchors.centerIn: parent
            width: wheel.inner * 2
            height: width
            radius: width / 2
            color: "#0a0c0e"
            border.width: 2
            border.color: Theme.accentLight

            Rectangle {
                x: parent.width / 2
                y: parent.height / 2 - 1.5
                width: wheel.inner - 6
                height: 3
                radius: 1.5
                color: Theme.accentLight
                transformOrigin: Item.Left
                rotation: wheel.needle
                opacity: wheel.hovered >= 0 ? 1 : 0.3
            }
            Column {
                anchors.centerIn: parent
                width: parent.width - 16
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: wheel.current ? wheel.current.n.toUpperCase() : "TODOS"
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    color: Theme.text
                    font.pixelSize: 11; font.bold: true; font.letterSpacing: 0.8
                }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: wheel.current ? "clic · pegar" : "Tab"
                    color: Theme.textMute
                    font.pixelSize: 10
                }
            }
        }
    }
}
