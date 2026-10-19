pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "../config"

// Ajustes que se guardan entre sesiones: ~/.local/state/ancient/settings.json
//   · talentos (comportamiento): una cosa u otra
//   · loadout (apariencia): modo, terminal, apps fijadas
Singleton {
    id: root

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/ancient"
    property alias data: adapter        // Settings.data.clock24, Settings.data.floating…
    property bool loaded: false
    property int faceStamp: 0           // cambia al poner otra foto (refresca las imágenes)

    // ── Escritura ──
    function set(key, value) {
        adapter[key] = value;
        if (key === "floating")
            writeHypr(true);
    }

    // Lo que lee hypr/shell.lua: modo (colores de los bordes) y ventanas flotantes
    function writeHypr(reload) {
        hyprWrite.command = ["sh", "-c",
            "mkdir -p \"$1\" && printf 'mode=%s\\nfloat=%s\\n' \"$2\" \"$3\" > \"$1/hypr\"" + (reload ? " && hyprctl reload >/dev/null" : ""),
            "sh", root.stateDir, adapter.mode, adapter.floating ? "1" : "0"];
        hyprWrite.running = true;
    }
    Process { id: hyprWrite }

    // Talento HYPRLAND: sintaxis de dispatch
    function focusWorkspace(id) {
        if (adapter.luaDispatch)
            Hyprland.dispatch('hl.dsp.focus({ workspace = "' + id + '" })');
        else
            Hyprland.dispatch("workspace " + id);
    }

    // Avatar: copia la imagen a ~/.face
    function setFace(path) {
        face.command = ["cp", path, Quickshell.env("HOME") + "/.face"];
        face.running = true;
    }
    Process {
        id: face
        onExited: root.faceStamp++
    }

    // Talento MODO: Dire automático mientras haya un juego abierto
    readonly property bool gaming: ToplevelManager.toplevels.values.some(t => /^(steam_app_\d+|gamescope)$/i.test(t.appId || ""))
    onGamingChanged: if (adapter.autoDire)
        ShellState.mode = gaming ? "dire" : "radiant"

    // ── Archivo ──
    FileView {
        id: file
        path: root.stateDir + "/settings.json"
        blockLoading: true
        onAdapterUpdated: writeAdapter()
        onLoaded: root.applyLoaded()
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                writeAdapter();
            root.applyLoaded();
        }

        JsonAdapter {
            id: adapter
            // Talentos
            property bool clock24: true
            property bool hudHover: true        // false: el HUD sale con un atajo
            property bool quietDire: false      // silenciar avisos en modo Dire
            property bool autoDire: false       // Dire al abrir un juego
            property bool luaDispatch: true     // false: sintaxis clásica de Hyprland
            property bool floating: false       // ventanas flotantes
            // Loadout
            property string mode: "radiant"
            property string terminal: "foot"
            property var pinnedApps: ["nemo", "foot", "zen", "spotify", "steam"]
        }
    }

    // Al cargar, el estado guardado pasa a ShellState
    function applyLoaded() {
        if (root.loaded)
            return;
        ShellState.mode = adapter.mode;
        ShellState.terminal = adapter.terminal;
        ShellState.pinnedApps = adapter.pinnedApps;
        root.loaded = true;
        writeHypr(false);
    }

    Component.onCompleted: Qt.callLater(applyLoaded)

    // Y lo que cambie en ShellState se guarda
    Connections {
        target: ShellState
        function onModeChanged() {
            if (!root.loaded || adapter.mode === ShellState.mode)
                return;
            adapter.mode = ShellState.mode;
            root.writeHypr(true);           // bordes de Hyprland con los colores del modo
        }
        function onTerminalChanged() {
            if (root.loaded)
                adapter.terminal = ShellState.terminal;
        }
        function onPinnedAppsChanged() {
            if (root.loaded)
                adapter.pinnedApps = ShellState.pinnedApps;
        }
    }
}
