import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../services"

// Bloqueo seguro de Wayland: una superficie por monitor
WlSessionLock {
    locked: Lock.locked

    WlSessionLockSurface {
        color: "black"
        LockContent {
            anchors.fill: parent
        }
    }
}
