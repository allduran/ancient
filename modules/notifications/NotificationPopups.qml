import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../config"
import "../../services"

// Pila de popups arriba a la derecha
PanelWindow {
    WlrLayershell.namespace: "ancient-notifs"
    WlrLayershell.layer: WlrLayer.Overlay       // por encima de todo
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        right: true
    }
    margins {
        top: Theme.stripHeight + 8
        right: 8
    }
    implicitWidth: Theme.notifWidth
    implicitHeight: Math.max(1, stack.implicitHeight)
    color: "transparent"
    visible: Notifs.popups.length > 0

    Column {
        id: stack
        width: parent.width
        spacing: 6

        Repeater {
            // ScriptModel compara listas: solo crea/borra los popups que cambian,
            // así los que ya están no reinician su cooldown
            model: ScriptModel {
                values: Notifs.popups
            }

            NotificationCard {
                required property var modelData
                notif: modelData
                width: stack.width
            }
        }
    }
}
