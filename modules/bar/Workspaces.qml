import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../../config"

BronzeFrame {
    id: root
    slantLeft: true

    readonly property var numerals: ["I", "II", "III", "IV", "V"]
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
            readonly property string appIcon: root.iconFor(root.workspace(index + 1))

            icon: appIcon
            empty: appIcon === ""
            label: root.numerals[index]
            active: root.activeId === index + 1
            tint: Theme.playerColors[index]
            barColor: empty ? "transparent" : Theme.playerColors[index]
            onClicked: Hyprland.dispatch('hl.dsp.focus({ workspace = "' + (index + 1) + '" })')
        }
    }
}
