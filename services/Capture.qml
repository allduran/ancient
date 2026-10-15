pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

// Capturas: lanza scripts/capture.sh y gestiona el selector de zona
Singleton {
    id: root

    readonly property string script: Qt.resolvedUrl("../scripts/capture.sh").toString().replace("file://", "")

    property bool selecting: false      // selector visible
    property string pendingMode: ""     // "area" o "record-area"
    property string pendingGeom: ""     // "x,y wxh"

    function monitor() {
        return Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
    }

    function run(mode, arg) {
        Quickshell.execDetached([script, mode, arg !== undefined ? arg : monitor()]);
    }

    // Abre el selector (si es grabación y ya hay una en marcha, la para)
    function startSelect(mode) {
        if (mode === "record-area") {
            recCheck.running = true;
            return;
        }
        openSelector(mode);
    }

    function openSelector(mode) {
        root.pendingMode = mode;
        Hyprland.refreshToplevels();        // posiciones de ventanas al día
        root.selecting = true;
    }

    function finishSelect(x, y, w, h) {
        root.pendingGeom = x + "," + y + " " + w + "x" + h;
        root.selecting = false;
        delay.restart();
    }

    function cancelSelect() {
        root.selecting = false;
    }

    // Espera a que el selector desaparezca antes de capturar (si no, saldría en la foto)
    Timer {
        id: delay
        interval: 200
        onTriggered: root.run(root.pendingMode, root.pendingGeom)
    }

    // ¿Hay una grabación en marcha?
    Process {
        id: recCheck
        command: ["pgrep", "-x", "wf-recorder"]
        onExited: code => {
            if (code === 0)
                root.run("record-area", "");
                // sí → el script la para
            else
                root.openSelector("record-area");          // no → elegir zona
        }
    }
}
