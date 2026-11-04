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
        hyprWrite.command = ["sh", "-c", "mkdir -p \"$1\" && printf 'mode=%s\\nfloat=%s\\n' \"$2\" \"$3\" > \"$1/hypr\"" + (reload ? " && hyprctl reload >/dev/null" : ""), "sh", root.stateDir, adapter.mode, adapter.floating ? "1" : "0"];
        hyprWrite.running = true;
    }
    Process {
        id: hyprWrite
    }

    // Talento HYPRLAND: sintaxis de dispatch
    function focusWorkspace(id) {
        if (adapter.luaDispatch)
            Hyprland.dispatch('hl.dsp.focus({ workspace = "' + id + '" })');
        else
            Hyprland.dispatch("workspace " + id);
    }

    // ── Minimizar (talento MINIMIZAR) ──
    // Mochila: a special:minimized, se ve en el inventario del HUD y se recupera desde ahí.
    // Escritorio especial: a special:special, el de Super+S de Hyprland.
    readonly property string minimizedWs: adapter.minimizeBackpack ? "minimized" : "special"
    readonly property var minimized: Hyprland.toplevels.values.filter(t => t.workspace && t.workspace.name === "special:minimized")

    function minimize() {
        const ws = "special:" + minimizedWs;
        if (adapter.luaDispatch)
            Hyprland.dispatch('hl.dsp.window.move({ workspace = "' + ws + '", follow = false })');
        else
            Hyprland.dispatch("movetoworkspacesilent " + ws);
    }

    // Devuelve una ventana minimizada al escritorio actual y la enfoca
    function restore(t) {
        const ws = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1;
        const addr = "address:" + t.lastIpcObject.address;
        if (adapter.luaDispatch)
            Hyprland.dispatch('hl.dsp.window.move({ window = "' + addr + '", workspace = "' + ws + '" })');
        else
            Hyprland.dispatch("movetoworkspace " + ws + "," + addr);
    }

    // ── Cursor ──
    function setCursor(name, size) {
        adapter.cursorTheme = name;
        adapter.cursorSize = size;
        applyCursor();
    }
    function applyCursor() {
        if (adapter.cursorTheme === "")
            return;
        const size = String(adapter.cursorSize);
        Quickshell.execDetached(["hyprctl", "setcursor", adapter.cursorTheme, size]);
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "cursor-theme", adapter.cursorTheme]);
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "cursor-size", size]);
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
            property int hudDelay: 1200          // ms con el ratón en el borde antes de mostrar el HUD
            property bool quietDire: false      // silenciar avisos en modo Dire
            property bool autoDire: false       // Dire al abrir un juego
            property bool luaDispatch: true     // false: sintaxis clásica de Hyprland
            property bool floating: false       // ventanas flotantes
            property bool windowListStart: false // lista de ventanas abierta al iniciar
            property bool minimizeBackpack: true // minimizar a la mochila del HUD
            property bool lockOnSuspend: true   // bloquear antes de suspender
            property bool notifBottom: false    // avisos abajo a la derecha
            property bool autoUpdates: true     // contar actualizaciones cada 30 min
            property bool sounds: true          // false: sin sonidos
            property string cursorTheme: ""     // "" = el de variables.lua
            property int cursorSize: 24
            property var keybinds: ({})         // atajos cambiados en Ajustes → Atajos
            // Sistema → Energía (minutos; 0 = nunca)
            property int idleLock: 5
            property int idleDpms: 10
            property int idleSuspend: 0
            property string powerProfile: "balanced"   // power-saver | balanced | performance
            property bool direPerformance: true         // modo Dire → rendimiento
            // Sistema → Luz nocturna y volumen
            property int nightTemp: 4500        // K (más bajo = más cálido)
            property bool nightAuto: false      // encender sola en el horario
            property int nightFrom: 21          // hora de encendido
            property int nightTo: 7             // hora de apagado
            property int volMax: 100            // % (más de 100 amplifica)
            property int volStep: 5             // % por pulsación
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
        ShellState.windowListOpen = adapter.windowListStart;
        root.loaded = true;
        applyCursor();                      // el cursor elegido gana al de variables.lua
        writeHypr(false);
        Power.init();                       // hypridle de ancient y perfil de energía
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
