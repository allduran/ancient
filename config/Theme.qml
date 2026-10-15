pragma Singleton

import Quickshell
import QtQuick

Singleton {
    // Fondos
    readonly property color panelTop: "#171b20"
    readonly property color panelBot: "#0e1114"
    readonly property color slot: "#0c0f12"

    // Bordes bronce
    readonly property color edge: "#4a3f2c"
    readonly property color edgeDim: "#3b3428"
    readonly property color edgeDark: "#050607"

    // Acentos
    readonly property color gold: "#c9a45c"
    readonly property color radiant: "#8fc27f"   // verde: activo
    readonly property color dire: "#c8463a"   // rojo: peligro

    // Texto
    readonly property color text: "#f2e6c8"
    readonly property color textSoft: "#d8cfba"
    readonly property color textMute: "#a69e8c"

    // Medidas
    readonly property int barHeight: 52
}
