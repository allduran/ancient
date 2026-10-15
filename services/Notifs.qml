pragma Singleton

import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// Servidor de notificaciones de ancient
Singleton {
    id: root

    readonly property var list: server.trackedNotifications.values   // todas (escudo)
    readonly property int count: list.length
    property var popups: []                                           // las que se ven ahora

    function hidePopup(n) {
        root.popups = root.popups.filter(p => p !== n);
    }

    function clearAll() {
        const all = server.trackedNotifications.values.slice();
        for (const n of all)
            n.dismiss();
        root.popups = [];
    }

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true;                                    // guardarla
            root.popups = [n].concat(root.popups).slice(0, 4);   // nueva arriba, máximo 4
            n.closed.connect(() => root.hidePopup(n));           // si la cierra la app, quitar el popup
        }
    }
}
