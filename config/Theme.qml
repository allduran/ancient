pragma Singleton

import Quickshell
import QtQuick

Singleton {
    // Piedra / fondos
    readonly property color stone: "#15181b"
    readonly property color slot: "#0a0c0e"

    // Marcos de bronce
    readonly property color frameTop: "#4a4232"
    readonly property color frameBot: "#1c1914"
    readonly property color frameEdge: "#8a7448"
    readonly property color edge: "#6b5b3a"
    readonly property color edgeDim: "#3b3428"
    readonly property color edgeDark: "#050607"

    // Acentos
    readonly property color gold: "#c9a45c"
    readonly property color goldLight: "#e6c77e"
    readonly property color radiant: "#8fc27f"
    readonly property color radiantTop: "#2e5226"
    readonly property color radiantBot: "#14240f"
    readonly property color dire: "#c8463a"
    readonly property color direTop: "#5a1f18"
    readonly property color direBot: "#26100c"
    readonly property color day: "#e6b84e"
    readonly property color night: "#1d3a66"

    // Texto
    readonly property color text: "#f2e6c8"
    readonly property color textSoft: "#d8cfba"
    readonly property color textMute: "#8e8676"

    // Colores de "jugador" para los escritorios 1–5
    readonly property var playerColors: ["#3375ff", "#66ffbf", "#bf00bf", "#f3f00b", "#ff6b00"]
    // Colores de las apps fijadas (lado derecho)
    readonly property var direColors: ["#fe86c2", "#a1b447", "#65d9f7", "#008321", "#a46900"]

    // Medidas
    readonly property int stripHeight: 30
    readonly property int portraitW: 54
    readonly property int portraitH: 30     // igual que la franja
    readonly property int dialSize: 76
    readonly property int shieldW: 34
    readonly property int shieldH: 42

    readonly property color label: "#4a463c"   // números romanos de retratos vacíos
    readonly property color dialTop: "#2a2519"
    readonly property color dialBot: "#0b0a08"
    readonly property color moon: "#9fb8e0"

    readonly property int notifWidth: 340
    readonly property int notifTimeout: 6000    // ms que dura un popup

    readonly property color manaTop: "#4f7fd0"
    readonly property color manaBot: "#2b4e96"
}
