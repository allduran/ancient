pragma Singleton

import Quickshell
import QtQuick

// Estado de la interfaz que comparten varios componentes
Singleton {
    property bool windowListOpen: true
    property bool windowListCollapsed: false
    property string mode: "radiant"      // "radiant" (general) | "dire" (juego)
    property bool armoryOpen: false
    property var pinnedApps: ["nemo", "foot", "zen", "spotify", "steam"]
    property var recentApps: []          // ids de las últimas apps lanzadas (máx. 8)
}
