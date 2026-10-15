import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../../config"
import "../../services"

// Selector de zona estilo Dota (uno por monitor)
PanelWindow {
    id: sel
    required property var modelData
    screen: modelData
    visible: Capture.selecting

    WlrLayershell.namespace: "ancient-selector"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive   // para recibir Esc
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    // ── Estado ──
    property real x1: 0
    property real y1: 0
    property real x2: 0
    property real y2: 0
    property bool dragging: false
    property var hovered: null          // ventana bajo el ratón

    readonly property real sx: Math.min(x1, x2)
    readonly property real sy: Math.min(y1, y2)
    readonly property real sw: Math.abs(x2 - x1)
    readonly property real sh: Math.abs(y2 - y1)
    readonly property bool hasSel: sw > 4 && sh > 4

    // Zona "iluminada": la selección, o la ventana bajo el ratón, o nada
    readonly property real fx: hasSel ? sx : hovered ? hovered.x : 0
    readonly property real fy: hasSel ? sy : hovered ? hovered.y : 0
    readonly property real fw: hasSel ? sw : hovered ? hovered.w : 0
    readonly property real fh: hasSel ? sh : hovered ? hovered.h : 0

    onVisibleChanged: {
        dragging = false;
        hovered = null;
        x1 = 0;
        y1 = 0;
        x2 = 0;
        y2 = 0;
    }

    // Ventanas visibles en este monitor, en coordenadas locales
    function windowsHere() {
        const mon = Hyprland.monitorFor(sel.screen);
        if (!mon || !mon.activeWorkspace)
            return [];
        return Hyprland.toplevels.values.filter(t => t.workspace && t.workspace.id === mon.activeWorkspace.id && t.lastIpcObject.at).map(t => ({
                    x: t.lastIpcObject.at[0] - sel.screen.x,
                    y: t.lastIpcObject.at[1] - sel.screen.y,
                    w: t.lastIpcObject.size[0],
                    h: t.lastIpcObject.size[1],
                    title: t.title,
                    color: Theme.playerColors[Math.max(0, t.workspace.id - 1) % 5]
                }));
    }

    // La ventana más pequeña que contiene el punto (la de "encima" si se solapan)
    function windowAt(px, py) {
        let best = null;
        for (const w of windowsHere())
            if (px >= w.x && px <= w.x + w.w && py >= w.y && py <= w.y + w.h)
                if (!best || w.w * w.h < best.w * best.h)
                    best = w;
        return best;
    }

    function finish(x, y, w, h) {
        Capture.finishSelect(Math.round(x + sel.screen.x), Math.round(y + sel.screen.y), Math.round(w), Math.round(h));
    }

    // Esquina en forma de corchete
    component Bracket: Item {
        property bool flipX: false
        property bool flipY: false
        width: 18
        height: 18
        Rectangle {
            width: 18
            height: 3
            y: parent.flipY ? 15 : 0
            color: Theme.accentLight
        }
        Rectangle {
            width: 3
            height: 18
            x: parent.flipX ? 15 : 0
            color: Theme.accentLight
        }
    }

    Item {
        id: root
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Capture.cancelSelect()

        readonly property color dim: Qt.rgba(0, 0, 0, 0.55)

        // ── Oscurecido: 4 rectángulos alrededor de la zona iluminada ──
        Rectangle {
            x: 0
            y: 0
            width: root.width
            height: sel.fy
            color: root.dim
        }
        Rectangle {
            x: 0
            y: sel.fy + sel.fh
            width: root.width
            height: root.height - sel.fy - sel.fh
            color: root.dim
        }
        Rectangle {
            x: 0
            y: sel.fy
            width: sel.fx
            height: sel.fh
            color: root.dim
        }
        Rectangle {
            x: sel.fx + sel.fw
            y: sel.fy
            width: root.width - sel.fx - sel.fw
            height: sel.fh
            color: root.dim
        }

        // ── Ventana resaltada (antes de arrastrar) ──
        Rectangle {
            visible: !sel.hasSel && sel.hovered !== null
            x: sel.fx
            y: sel.fy
            width: sel.fw
            height: sel.fh
            color: "transparent"
            border.width: 2
            border.color: sel.hovered ? sel.hovered.color : "transparent"

            Rectangle {
                y: -height - 4
                width: hoverTitle.implicitWidth + 16
                height: 20
                color: Theme.slot
                border.width: 1
                border.color: Theme.edge
                Text {
                    id: hoverTitle
                    anchors.centerIn: parent
                    text: sel.hovered ? sel.hovered.title : ""
                    color: Theme.text
                    font.pixelSize: 11
                }
            }
        }

        // ── Selección: borde fino + corchetes + medidas ──
        Item {
            id: frame
            visible: sel.hasSel
            x: sel.sx
            y: sel.sy
            width: sel.sw
            height: sel.sh

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.width: 1
                border.color: Theme.accent
            }

            Bracket {
                x: -3
                y: -3
            }
            Bracket {
                x: frame.width - 15
                y: -3
                flipX: true
            }
            Bracket {
                x: -3
                y: frame.height - 15
                flipY: true
            }
            Bracket {
                x: frame.width - 15
                y: frame.height - 15
                flipX: true
                flipY: true
            }

            // Placa de bronce con las medidas
            Rectangle {
                x: Math.min(frame.width - width, root.width - sel.sx - width - 4)
                y: frame.height + 6 + height > root.height - sel.sy ? -height - 6 : frame.height + 6
                width: sizeText.implicitWidth + 18
                height: 22
                border.width: 1
                border.color: Theme.frameEdge
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: Theme.frameTop
                    }
                    GradientStop {
                        position: 1
                        color: Theme.frameBot
                    }
                }
                Text {
                    id: sizeText
                    anchors.centerIn: parent
                    text: Math.round(sel.sw) + " × " + Math.round(sel.sh)
                    color: Theme.text
                    font.family: "monospace"
                    font.pixelSize: 11
                    font.bold: true
                }
            }
        }

        // ── Mira (antes de arrastrar) ──
        Rectangle {
            visible: !sel.dragging && !sel.hasSel
            x: mouse.mouseX
            width: 1
            height: root.height
            color: Theme.accentLight
            opacity: 0.35
        }
        Rectangle {
            visible: !sel.dragging && !sel.hasSel
            y: mouse.mouseY
            width: root.width
            height: 1
            color: Theme.accentLight
            opacity: 0.35
        }

        // ── Pista inferior ──
        Rectangle {
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: 40
            }
            width: hint.implicitWidth + 32
            height: 30
            color: Qt.rgba(0.04, 0.05, 0.06, 0.9)
            border.width: 1
            border.color: Theme.edge
            Rectangle {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                height: 2
                color: Theme.accent
            }
            Text {
                id: hint
                anchors.centerIn: parent
                text: (Capture.pendingMode === "record-area" ? "GRABAR · " : "CAPTURA · ") + "Arrastra para seleccionar  ·  Clic en una ventana  ·  Esc cancelar"
                color: Theme.textSoft
                font.pixelSize: 11
                font.letterSpacing: 1
            }
        }

        // ── Ratón ──
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.CrossCursor

            onPressed: e => {
                if (e.button === Qt.RightButton) {
                    Capture.cancelSelect();
                    return;
                }
                sel.dragging = true;
                sel.x1 = e.x;
                sel.y1 = e.y;
                sel.x2 = e.x;
                sel.y2 = e.y;
            }
            onPositionChanged: e => {
                if (sel.dragging) {
                    sel.x2 = e.x;
                    sel.y2 = e.y;
                } else
                    sel.hovered = sel.windowAt(e.x, e.y);
            }
            onReleased: e => {
                if (e.button !== Qt.LeftButton)
                    return;
                sel.dragging = false;
                if (sel.hasSel)
                    sel.finish(sel.sx, sel.sy, sel.sw, sel.sh);
                else if (sel.hovered)
                    sel.finish(sel.hovered.x, sel.hovered.y, sel.hovered.w, sel.hovered.h);
            }
        }
    }
}
