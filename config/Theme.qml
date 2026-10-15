pragma Singleton

import Quickshell
import QtQuick

// Colores y medidas. Los que dependen del modo salen de la paleta activa.
Singleton {
    id: theme

    // ── Paletas ──
    readonly property var radiant: ({
            stone: "#15181b",
            slot: "#0a0c0e",
            frameTop: "#4a4232",
            frameBot: "#1c1914",
            frameEdge: "#8a7448",
            edge: "#6b5b3a",
            edgeDim: "#3b3428",
            edgeDark: "#050607",
            accent: "#c9a45c",
            accentLight: "#e6c77e",
            label: "#4a463c",
            dialTop: "#2a2519",
            dialBot: "#0b0a08",
            stripTexture: "strip-stone.png"
        })

    readonly property var dire: ({
            stone: "#1a1110",
            slot: "#0d0807",
            frameTop: "#3a1c18",
            frameBot: "#140a08",
            frameEdge: "#7a2e22",
            edge: "#6b2a20",
            edgeDim: "#3b1a15",
            edgeDark: "#050303",
            accent: "#e0583a",
            accentLight: "#ff8a5c",
            label: "#4a3430",
            dialTop: "#2a1512",
            dialBot: "#0b0605",
            stripTexture: "strip-lava.png"
        })

    // Paleta activa
    readonly property var p: ShellState.mode === "dire" ? dire : radiant

    // ── Colores que cambian con el modo ──
    readonly property color stone: p.stone
    readonly property color slot: p.slot
    readonly property color frameTop: p.frameTop
    readonly property color frameBot: p.frameBot
    readonly property color frameEdge: p.frameEdge
    readonly property color edge: p.edge
    readonly property color edgeDim: p.edgeDim
    readonly property color edgeDark: p.edgeDark
    readonly property color accent: p.accent
    readonly property color accentLight: p.accentLight
    readonly property color label: p.label
    readonly property color dialTop: p.dialTop
    readonly property color dialBot: p.dialBot
    readonly property string stripTexture: p.stripTexture

    // ── Colores fijos (iguales en los dos modos) ──
    readonly property color positive: "#8fc27f"
    readonly property color positiveTop: "#2e5226"
    readonly property color positiveBot: "#14240f"
    readonly property color danger: "#c8463a"
    readonly property color dangerTop: "#5a1f18"
    readonly property color dangerBot: "#26100c"
    readonly property color day: "#e6b84e"
    readonly property color night: "#1d3a66"
    readonly property color moon: "#9fb8e0"
    readonly property color manaTop: "#4f7fd0"
    readonly property color manaBot: "#2b4e96"

    readonly property color text: "#f2e6c8"
    readonly property color textSoft: "#d8cfba"
    readonly property color textMute: "#8e8676"

    readonly property var playerColors: ["#3375ff", "#66ffbf", "#bf00bf", "#f3f00b", "#ff6b00"]
    readonly property var pinnedColors: ["#fe86c2", "#a1b447", "#65d9f7", "#008321", "#a46900"]

    // ── Medidas ──
    readonly property int stripHeight: 30
    readonly property int portraitW: 54
    readonly property int portraitH: 30
    readonly property int dialSize: 76
    readonly property int shieldW: 34
    readonly property int shieldH: 42
    readonly property int notifWidth: 340
    readonly property int notifTimeout: 6000
}
