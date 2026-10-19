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
    property bool mediaOpen: false
    property string terminal: "foot"     // terminal para "Quick buy" (actualizar)
    property bool clipboardOpen: false
    property bool emojiWheelOpen: false
    property bool emojiPickerOpen: false
    property bool wallpaperOpen: false
    property bool settingsOpen: false
    property bool hudOpen: false         // HUD con atajo (talento HUD)
}
