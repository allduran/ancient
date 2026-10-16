pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../config"

// "Oro": actualizaciones pendientes (pacman)
Singleton {
    id: root
    property int count: 0

    function check() {
        proc.running = true;
    }

    // "Quick buy": abre la terminal y actualiza
    function run() {
        Quickshell.execDetached([ShellState.terminal, "-e", "sh", "-c", "sudo pacman -Syu; echo; read -p 'Pulsa Enter para cerrar…' _"]);
        recheck.restart();
    }

    Process {
        id: proc
        command: ["checkupdates"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = this.text.trim();
                root.count = t === "" ? 0 : t.split("\n").length;
            }
        }
    }

    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.check()
    }
    Timer {
        id: recheck
        interval: 5 * 60 * 1000
        onTriggered: root.check()
    }   // vuelve a contar tras actualizar
}
