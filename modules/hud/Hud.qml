import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../../config"

// HUD inferior: oculto; aparece al llevar el ratón al borde de abajo
PanelWindow {
    id: hud
    required property var modelData
    screen: modelData

    WlrLayershell.namespace: "ancient-hud"
    WlrLayershell.layer: WlrLayer.Top
    // Abierto → recibe el teclado; cerrado → el teclado sigue en tus ventanas
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors {
        bottom: true
        left: true
        right: true
    }
    implicitHeight: 250
    color: "transparent"

    property bool shown: false
    onShownChanged: {
        if (shown) {
            Hyprland.refreshToplevels();       // minimapa al día
            Qt.callLater(() => keys.forceActiveFocus());
        }
    }

    // Zona que recibe el ratón: oculto → 3 px del borde; visible → las piezas del HUD
    mask: shown ? fullRegion : triggerRegion
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
                hud.shown = false;
                event.accepted = true;
                return;
            }
            const k = event.text.toUpperCase();
            if (hero.press(k)) {
                event.accepted = true;
                if (k === "F")
                    hud.shown = false;      // que el selector de captura reciba el teclado
            }
        }
    }

    HoverHandler {
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
        y: hud.shown ? 0 : height
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
