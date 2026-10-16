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
    exclusionMode: ExclusionMode.Ignore
    anchors {
        bottom: true
        left: true
        right: true
    }
    implicitHeight: 250
    color: "transparent"

    property bool shown: false
    onShownChanged: if (shown)
        Hyprland.refreshToplevels()    // minimapa al día

    // Zona que recibe el ratón: oculto → 3 px del borde; visible → las piezas del HUD
    mask: shown ? hudRegion : triggerRegion
    property Region triggerRegion: Region {
        item: trigger
    }
    property Region hudRegion: Region {
        item: minimap
        Region {
            item: hero
            intersection: Intersection.Combine
        }
        Region {
            item: shop
            intersection: Intersection.Combine
        }
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
        interval: 500
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
