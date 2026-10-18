pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../config"

// Fondos: ~/Pictures/Wallpapers/wallpaper-dota-<n>.<jpg|jpeg|png|webp>
// Cada fondo puede ser de Radiant, de Dire o de los dos (sin asignar).
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    readonly property string stateFile: Quickshell.env("HOME") + "/.local/state/ancient/wallpapers.json"

    property var list: []           // [{ name, path, num, size }] ordenados por número
    property string current: ""     // ruta del fondo puesto
    property var modes: ({})        // { "wallpaper-dota-3.jpg": "radiant" | "dire" }
    property var last: ({})         // último fondo usado en cada modo { radiant: ruta, dire: ruta }

    function modeOf(w) {
        return root.modes[w.name] ?? "";
    }
    function fits(w, m) {
        const a = modeOf(w);
        return a === "" || a === m;
    }
    function count(m) {
        return root.list.filter(w => modeOf(w) === m).length;
    }
    function sizeText(bytes) {
        return bytes >= 1048576 ? (bytes / 1048576).toFixed(1) + " MB" : Math.round(bytes / 1024) + " KB";
    }

    function refresh() {
        if (!scan.running)
            scan.running = true;
    }

    function apply(w) {
        root.current = w.path;
        const l = Object.assign({}, root.last);
        l[ShellState.mode] = w.path;
        root.last = l;
        save();
    }

    // R / D: asigna a ese modo, o lo quita si ya lo era
    function assign(w, m) {
        const x = Object.assign({}, root.modes);
        if (x[w.name] === m)
            delete x[w.name];
        else
            x[w.name] = m;
        root.modes = x;
        save();
        followMode();
    }

    function save() {
        stateView.setText(JSON.stringify({
            current: root.current,
            modes: root.modes,
            last: root.last
        }));
    }

    // Si el fondo puesto no vale para el modo activo, pone otro que sí
    function followMode() {
        const m = ShellState.mode;
        const cur = root.list.find(w => w.path === root.current);
        if (cur && fits(cur, m))
            return;
        const pick = root.list.find(w => w.path === root.last[m] && fits(w, m))
            ?? root.list.find(w => modeOf(w) === m)
            ?? root.list.find(w => fits(w, m));
        if (pick) {
            root.current = pick.path;
            save();
        }
    }

    Connections {
        target: ShellState
        function onModeChanged() {
            root.followMode();
        }
    }

    Process {
        id: scan
        command: ["sh", "-c", "find \"$1\" -maxdepth 1 -type f -printf '%f\\t%s\\n' 2>/dev/null", "sh", root.dir]
        stdout: StdioCollector {
            onStreamFinished: {
                root.list = this.text.split("\n").map(l => {
                    const parts = l.split("\t");
                    const m = /^wallpaper-dota-(\d+)\.(jpe?g|png|webp)$/i.exec(parts[0] ?? "");
                    return m ? {
                        name: parts[0],
                        path: root.dir + "/" + parts[0],
                        num: Number(m[1]),
                        size: Number(parts[1])
                    } : null;
                }).filter(x => x).sort((a, b) => a.num - b.num);
                root.followMode();
            }
        }
    }

    FileView {
        id: stateView
        path: root.stateFile
        blockLoading: true
        onLoaded: {
            try {
                const s = JSON.parse(text());
                root.current = s.current ?? "";
                root.modes = s.modes ?? {};
                root.last = s.last ?? {};
            } catch (err) {}
        }
    }

    Component.onCompleted: refresh()
}
