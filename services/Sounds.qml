pragma Singleton

import Quickshell
import QtQuick
import "../config"

// Sonidos del shell (assets/sounds): al bloquear, al llegar un aviso y al cambiar de modo.
// Ajustes: Settings.data.sounds = true (sonidos de ancient) | false (ninguno)
Singleton {
    id: root

    readonly property string dir: Quickshell.shellDir + "/assets/sounds/"

    // event: "lock" | "notify" | "mode-radiant" | "mode-dire"
    function play(event) {
        if (!Settings.data.sounds)
            return;
        Quickshell.execDetached(["pw-play", root.dir + event + ".ogg"]);
    }

    // Al cambiar de modo (no suena al arrancar: solo cuando ya se cargaron los ajustes)
    Connections {
        target: ShellState
        function onModeChanged() {
            if (Settings.loaded)
                root.play("mode-" + ShellState.mode);
        }
    }
}
