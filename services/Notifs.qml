pragma Singleton

import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// Servidor de notificaciones de ancient. Las guarda para contarlas y mostrarlas.
Singleton {
    id: root

    readonly property var list: server.trackedNotifications.values
    readonly property int count: list.length

    function clearAll() {
        const all = server.trackedNotifications.values.slice();
        for (const n of all)
            n.dismiss();
    }

    NotificationServer {
        id: server
        keepOnReload: true          // no las pierde al recargar el shell
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        onNotification: n => n.tracked = true
        // guardarla en la lista
    }
}
