pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// CPU, RAM y red. Lee /proc y nmcli cada pocos segundos.
Singleton {
    id: root

    property int cpu: 0              // %
    property int ramPercent: 0       // %
    property string network: "—"

    property var lastCpu: null       // lectura anterior, para calcular la diferencia

    FileView {
        id: statFile
        path: "/proc/stat"
        blockLoading: true
    }
    FileView {
        id: memFile
        path: "/proc/meminfo"
        blockLoading: true
    }

    function updateCpu() {
        statFile.reload();
        // Primera línea: "cpu  user nice system idle iowait irq softirq steal …"
        const f = statFile.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
        const idle = f[3] + f[4];
        const total = f.reduce((a, b) => a + b, 0);
        if (root.lastCpu) {
            const dt = total - root.lastCpu.total;
            const di = idle - root.lastCpu.idle;
            if (dt > 0)
                root.cpu = Math.round((1 - di / dt) * 100);
        }
        root.lastCpu = {
            total: total,
            idle: idle
        };
    }

    function updateRam() {
        memFile.reload();
        const t = memFile.text();
        const get = key => Number((t.match(new RegExp(key + ":\\s+(\\d+)")) || [0, 0])[1]);
        const total = get("MemTotal");
        const avail = get("MemAvailable");
        root.ramPercent = total > 0 ? Math.round((total - avail) / total * 100) : 0;
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.updateCpu();
            root.updateRam();
        }
    }

    // Red: nombre de la wifi, "Ethernet" u "Offline"
    Process {
        id: netProc
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                let name = "Offline";
                for (const line of this.text.trim().split("\n")) {
                    const parts = line.split(":");
                    if (parts[1] !== "connected")
                        continue;
                    if (parts[0] === "wifi") {
                        name = parts[2];
                        break;
                    }
                    if (parts[0] === "ethernet")
                        name = "Ethernet";
                }
                root.network = name;
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: netProc.running = true
    }
}
