import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../config"

Row {
    id: root
    spacing: 0

    // Apps fijadas: nombre del .desktop (o parecido)
    property var apps: ["nemo", "foot", "zen", "spotify", "steam"]

    // Primera ventana abierta cuyo appId contiene la clave
    function windowFor(key) {
        const list = ToplevelManager.toplevels.values;
        for (let i = 0; i < list.length; i++)
            if ((list[i].appId || "").toLowerCase().includes(key))
                return list[i];
        return null;
    }

    Repeater {
        model: root.apps

        Portrait {
            required property string modelData
            required property int index
            readonly property var entry: DesktopEntries.heuristicLookup(modelData)
            readonly property var win: root.windowFor(modelData)
            readonly property color appColor: Theme.pinnedColors[index % Theme.pinnedColors.length]

            icon: Quickshell.iconPath(entry ? entry.icon : modelData, "application-x-executable")
            tint: appColor
            barColor: win ? appColor : "transparent"     // barra = app abierta
            active: win !== null && win.activated        // marco = ventana enfocada

            onClicked: {
                if (win) {
                    win.activate();      // abierta → la enfoca
                } else if (entry) {
                    entry.execute();     // cerrada → la lanza
                }
            }
        }
    }
}
