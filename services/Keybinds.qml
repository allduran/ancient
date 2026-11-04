pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Atajos de ancient
//   · lee los atajos reales de Hyprland (hyprctl binds -j)
//   · los cambios hechos en Ajustes → Atajos se guardan en settings.json (keybinds) y se
//     escriben en ~/.local/state/ancient/keybinds.lua, que carga hypr/shell.lua (solo con ancient)
Singleton {
    id: root

    readonly property string luaFile: Quickshell.env("HOME") + "/.local/state/ancient/keybinds.lua"

    // Acciones de ancient: id = acción de `duran ipc`, call = target y función de qs
    readonly property var actions: [
        {
            id: "launcher",
            group: "SHELL",
            name: "Armería",
            desc: "lanzador de apps",
            call: "launcher toggle"
        },
        {
            id: "settings",
            group: "SHELL",
            name: "Ajustes",
            desc: "esta ventana",
            call: "settings toggle"
        },
        {
            id: "mode",
            group: "SHELL",
            name: "Cambiar modo",
            desc: "Radiant / Dire",
            call: "mode toggle"
        },
        {
            id: "wallpaper",
            group: "SHELL",
            name: "Fondos",
            desc: "galería de fondos",
            call: "wallpaper toggle"
        },
        {
            id: "bar",
            group: "SHELL",
            name: "Barra",
            desc: "mostrar / ocultar",
            call: "bar toggle"
        },
        {
            id: "notifs_clear",
            group: "SHELL",
            name: "Borrar avisos",
            desc: "vacía las notificaciones",
            call: "notifs clear"
        },
        {
            id: "lock",
            group: "SESIÓN",
            name: "Bloquear",
            desc: "pantalla de bloqueo",
            call: "lock lock"
        },
        {
            id: "session",
            group: "SESIÓN",
            name: "Abandonar…",
            desc: "apagar, reiniciar, salir",
            call: "session open"
        },
        {
            id: "minimize",
            group: "VENTANAS",
            name: "Minimizar",
            desc: "a la mochila del HUD",
            call: "window minimize"
        },
        {
            id: "hud",
            group: "VENTANAS",
            name: "HUD",
            desc: "mostrar / ocultar (talento HUD)",
            call: "hud toggle"
        },
        {
            id: "clipboard",
            group: "HERRAMIENTAS",
            name: "Courier",
            desc: "portapapeles",
            call: "clipboard toggle"
        },
        {
            id: "emoji",
            group: "HERRAMIENTAS",
            name: "Emojis",
            desc: "rueda de chat",
            call: "emoji toggle"
        },
        {
            id: "emoji_all",
            group: "HERRAMIENTAS",
            name: "Todos los emojis",
            desc: "selector completo",
            call: "emoji all"
        },
        {
            id: "shot_region",
            group: "CAPTURAS",
            name: "Captura de zona",
            desc: "selector de región",
            call: "capture region"
        },
        {
            id: "shot_screen",
            group: "CAPTURAS",
            name: "Captura de pantalla",
            desc: "pantalla entera",
            call: "capture screen"
        },
        {
            id: "shot_window",
            group: "CAPTURAS",
            name: "Captura de ventana",
            desc: "ventana activa",
            call: "capture window"
        },
        {
            id: "rec_region",
            group: "CAPTURAS",
            name: "Grabar zona",
            desc: "vídeo de una región",
            call: "capture record"
        },
        {
            id: "rec_screen",
            group: "CAPTURAS",
            name: "Grabar pantalla",
            desc: "vídeo de la pantalla",
            call: "capture recordScreen"
        },
        {
            id: "media_toggle",
            group: "MULTIMEDIA",
            name: "Play / pausa",
            desc: "reproductor",
            call: "media toggle"
        },
        {
            id: "media_next",
            group: "MULTIMEDIA",
            name: "Siguiente",
            desc: "reproductor",
            call: "media next"
        },
        {
            id: "media_prev",
            group: "MULTIMEDIA",
            name: "Anterior",
            desc: "reproductor",
            call: "media previous"
        }
    ]

    property var binds: []          // [{ combo, arg }] de hyprctl

    function refresh() {
        if (!query.running)
            query.running = true;
    }

    // "SUPER + SHIFT + V" a partir de la máscara de Hyprland
    function comboOf(mask, key) {
        const mods = [];
        if (mask & 64)
            mods.push("SUPER");
        if (mask & 4)
            mods.push("CTRL");
        if (mask & 8)
            mods.push("ALT");
        if (mask & 1)
            mods.push("SHIFT");
        return mods.concat([key.length === 1 ? key.toUpperCase() : key]).join(" + ");
    }

    function command(action) {
        return "qs -c ancient ipc call " + action.call;
    }

    // ¿Este atajo de Hyprland lanza esta acción?
    function runs(arg, action) {
        return new RegExp("duran ipc " + action.id + "(\\s|$)").test(arg) || arg.includes("ipc call " + action.call);
    }

    // Atajos de una acción: [{ combo, src: "ANCIENT" | "DOTFILES" }]
    function combosFor(action) {
        const mine = Settings.data.keybinds[action.id] || "";
        const list = root.binds.filter(b => runs(b.arg, action) && b.combo !== mine).map(b => ({
                    combo: b.combo,
                    src: "DOTFILES"
                }));
        if (mine !== "")
            list.unshift({
                combo: mine,
                src: "ANCIENT"
            });
        return list;
    }

    // Otros atajos que usan la misma combinación (para avisar)
    function conflicts(combo, action) {
        if (combo === "")
            return [];
        const others = root.binds.filter(b => b.combo === combo && !runs(b.arg, action)).map(b => b.arg.replace(/^.*duran ipc /, "").replace(/^~\/\.local\/bin\//, ""));
        for (const a of root.actions)
            if (a.id !== action.id && Settings.data.keybinds[a.id] === combo)
                others.push(a.name);
        return others;
    }

    // Guardar / quitar el atajo de ancient de una acción
    function assign(action, combo) {
        const k = Object.assign({}, Settings.data.keybinds);
        if (combo === "")
            delete k[action.id];
        else
            k[action.id] = combo;
        Settings.data.keybinds = k;
        writeLua();
    }
    function resetAll() {
        Settings.data.keybinds = {};
        writeLua();
    }

    function writeLua() {
        const lines = ["-- Generado por ancient (Ajustes → Atajos). No lo edites a mano.", "-- Lo carga hypr/shell.lua: estos atajos solo existen con ancient activo."];
        for (const a of root.actions) {
            const combo = Settings.data.keybinds[a.id];
            if (combo)
                lines.push('hl.bind("' + combo + '", hl.dsp.exec_cmd("' + command(a) + '"))');
        }
        writer.command = ["sh", "-c", "printf '%s\\n' \"$@\" > \"$0\" && hyprctl reload >/dev/null", root.luaFile].concat(lines);
        writer.running = true;
    }

    Process {
        id: writer
        onExited: reloadLater.restart()
    }
    Timer {
        id: reloadLater
        interval: 400                    // da tiempo a Hyprland a recargar
        onTriggered: root.refresh()
    }

    Process {
        id: query
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.binds = JSON.parse(this.text).map(b => ({
                                combo: root.comboOf(b.modmask, b.key),
                                arg: b.arg || ""
                            }));
                } catch (err) {
                    root.binds = [];
                }
            }
        }
    }
}
