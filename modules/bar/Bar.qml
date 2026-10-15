import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../config"

PanelWindow {
    id: bar
    required property var modelData   // la pantalla, la pasa Variants
    screen: modelData

    WlrLayershell.namespace: "ancient-bar"   // para la layer rule de hypr/shell.lua
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    color: "transparent"

    // Fondo degradado
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Theme.panelTop
            }
            GradientStop {
                position: 1
                color: Theme.panelBot
            }
        }

        // Filo bronce abajo
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 1
            color: Theme.edge
        }
    }

    // Centro
    Clock {
        anchors.centerIn: parent
    }
}
