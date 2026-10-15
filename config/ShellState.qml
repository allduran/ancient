pragma Singleton

import Quickshell
import QtQuick

// Estado de la interfaz que comparten varios componentes
Singleton {
    property bool windowListOpen: true
    property bool windowListCollapsed: false
}
