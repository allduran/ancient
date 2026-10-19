import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../../config"
import "../../services"

// HUD inferior: oculto; aparece al llevar el ratón al borde de abajo
// (o con `duran ipc hud`, si en Ajustes → Talentos está "Con un atajo")
PanelWindow {
    id: hud
    required property var modelData
    screen: modelData

    WlrLayershell.namespace: "ancient-hud"
    WlrLayershell.layer: WlrLayer.Top
    // Abierto → recibe el teclado; cerrado → el teclado sigue en tus ventanas
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors {
        bottom: true
        left: true
        right: true
    }
    implicitHeight: 250
    color: "transparent"

    property bool shown: false            // por el ratón
    readonly property bool onFocused: Hyprland.focusedMonitor !== null && Hyprland.focusedMonitor.name === modelData.name
    readonly property bool open: Settings.data.hudHover ? shown : (ShellState.hudOpen && onFocused)

    function close() {
        shown = false;
        ShellState.hudOpen = false;
    }

    onOpenChanged: {
        if (open) {
            Hyprland.refreshToplevels();       // minimapa al día
            Qt.callLater(() => keys.forceActiveFocus());
        }
    }

    // Zona que recibe el ratón: oculto → 3 px del borde; visible → las piezas del HUD
    mask: open ? fullRegion : (Settings.data.hudHover ? triggerRegion : emptyRegion)
    property Region emptyRegion: Region {}
    property Region triggerRegion: Region {
        item: trigger
    }
    property Region fullRegion: Region {
        item: hoverZone
    }

    Item {
        id: trigger
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 3
    }

    Item {
        id: hoverZone
        anchors.fill: parent
    }

    // Teclas de las habilidades
    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                hud.close();
                event.accepted = true;
                return;
            }
            const k = event.text.toUpperCase();
            if (hero.press(k)) {
                event.accepted = true;
                if (k === "F")
                    hud.close();      // que el selector de captura reciba el teclado
            }
        }
    }

    HoverHandler {
        enabled: Settings.data.hudHover
        onHoveredChanged: {
            if (hovered) {
                hideTimer.stop();
                hud.shown = true;
            } else
                hideTimer.restart();
        }
    }
    Timer {
        id: hideTimer
        interval: 800
        onTriggered: hud.shown = false
    }

    // Todo el HUD sube y baja junto
    Item {
        anchors {
            left: parent.left
            right: parent.right
        }
        height: parent.height
        y: hud.open ? 0 : height
        Behavior on y {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Minimap {
            id: minimap
            anchors {
                left: parent.left
                bottom: parent.bottom
            }
        }
        HeroPanel {
            id: hero
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
            }
        }
        Shop {
            id: shop
            anchors {
                right: parent.right
                bottom: parent.bottom
            }
        }
    }
}
