pragma Singleton

import Quickshell
import Quickshell.Wayland
import QtQuick
import "../config"

// Catálogo de aplicaciones (.desktop) + búsqueda, categorías, fijadas y recientes
Singleton {
    id: root

    // Todas las apps visibles, ordenadas por nombre
    readonly property var all: DesktopEntries.applications.values.filter(e => !e.noDisplay).sort((a, b) => a.name.localeCompare(b.name))

    readonly property var categories: [
        {
            label: "Todas",
            match: []
        },
        {
            label: "Desarrollo",
            match: ["Development"]
        },
        {
            label: "Gráficos",
            match: ["Graphics"]
        },
        {
            label: "Internet",
            match: ["Network", "WebBrowser"]
        },
        {
            label: "Multimedia",
            match: ["AudioVideo", "Audio", "Video"]
        },
        {
            label: "Juegos",
            match: ["Game"]
        },
        {
            label: "Sistema",
            match: ["System", "Settings", "Utility"]
        },
        {
            label: "Otras",
            match: null
        }
    ]

    // Categorías del .desktop como array JS normal
    function cats(e) {
        return e && e.categories ? Array.from(e.categories) : [];
    }

    function inCategory(e, cat) {
        const c = cats(e);
        if (cat.match === null)    // "Otras": las que no encajan en ningún grupo
            return !categories.some(k => k.match && k.match.length > 0 && k.match.some(m => c.includes(m)));
        if (cat.match.length === 0)
            return true;
        return cat.match.some(m => c.includes(m));
    }

    function categoryLabel(e) {
        for (let i = 1; i < categories.length - 1; i++)
            if (inCategory(e, categories[i]))
                return categories[i].label;
        return "Otras";
    }

    function count(cat) {
        return all.filter(e => inCategory(e, cat)).length;
    }

    // Búsqueda: primero las que empiezan por el texto, luego las que lo contienen,
    // luego las que lo tienen en descripción o palabras clave
    function search(query, cat) {
        const q = query.trim().toLowerCase();
        const list = all.filter(e => inCategory(e, cat));
        if (q === "")
            return list;
        const score = e => {
            const n = e.name.toLowerCase();
            if (n.startsWith(q))
                return 0;
            if (n.includes(q))
                return 1;
            const extra = ((e.genericName || "") + " " + (e.comment || "") + " " + (e.keywords || []).join(" ")).toLowerCase();
            return extra.includes(q) ? 2 : 9;
        };
        return list.map(e => ({
                    e: e,
                    s: score(e)
                })).filter(x => x.s < 9).sort((a, b) => a.s - b.s).map(x => x.e);
    }

    function byId(id) {
        return DesktopEntries.heuristicLookup(id);
    }

    function icon(e) {
        return Quickshell.iconPath(e ? e.icon : "", "application-x-executable");
    }

    // Color estable por app (siempre el mismo para la misma app)
    function color(e) {
        const pal = Theme.playerColors.concat(Theme.pinnedColors);
        if (!e)
            return pal[0];
        let h = 0;
        for (const ch of e.id)
            h = (h * 31 + ch.charCodeAt(0)) >>> 0;
        return pal[h % pal.length];
    }

    function windowCount(e) {
        if (!e || !e.id)
            return 0;          // acciones o entradas sin id
        const id = e.id.toLowerCase();
        return ToplevelManager.toplevels.values.filter(t => {
            const a = (t.appId || "").toLowerCase();
            return a !== "" && (a === id || id.endsWith(a) || id.includes(a));
        }).length;
    }

    function isPinned(e) {
        return e !== null && ShellState.pinnedApps.some(k => byId(k) === e);
    }

    function togglePin(e) {
        if (!e)
            return;
        ShellState.pinnedApps = isPinned(e) ? ShellState.pinnedApps.filter(k => byId(k) !== e) : ShellState.pinnedApps.concat([e.id]);
    }

    function launch(e) {
        if (!e)
            return;
        e.execute();
        ShellState.recentApps = [e.id].concat(ShellState.recentApps.filter(i => i !== e.id)).slice(0, 8);
    }
}
