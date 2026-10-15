import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../../config"

Row {
    id: root
    spacing: 0

    readonly property var numerals: ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
    // Primer escritorio del grupo visible: 0 → 1–5, 5 → 6–10, …
    readonly property int base: activeId > 0 ? Math.floor((activeId - 1) / 5) * 5 : 0
    readonly property int activeId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    function workspace(id) {
        const list = Hyprland.workspaces.values;
        for (let i = 0; i < list.length; i++)
            if (list[i].id === id)
                return list[i];
        return null;
    }

    // Icono de la primera ventana del escritorio
    function iconFor(ws) {
        if (!ws || ws.toplevels.values.length === 0)
            return "";
        const top = ws.toplevels.values[0];
        const appId = top.wayland ? top.wayland.appId : (top.lastIpcObject["class"] || "");
        const entry = DesktopEntries.heuristicLookup(appId);
        return Quickshell.iconPath(entry ? entry.icon : appId, "application-x-executable");
    }

    Repeater {
        model: 5

        Portrait {
            required property int index
            readonly property int wsId: root.base + index + 1
            readonly property string appIcon: root.iconFor(root.workspace(wsId))

            icon: appIcon
            empty: appIcon === ""
            label: root.numerals[wsId - 1] ?? String(wsId)
            active: root.activeId === wsId
            tint: Theme.playerColors[index]
            barColor: empty ? "transparent" : Theme.playerColors[index]
            onClicked: Hyprland.dispatch('hl.dsp.focus({ workspace = "' + wsId + '" })')
        }
    }
}
