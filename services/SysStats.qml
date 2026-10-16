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
    property int temp: 0                 // °C
    property string diskFree: "—"
    property real netDown: 0             // bytes/s
    property real netUp: 0
    property real ramUsedGb: 0
    property real ramTotalGb: 0
    property bool vpn: false
    property real uptime: 0              // segundos encendido
    property var lastNet: null

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
        root.ramTotalGb = total / 1048576;
        root.ramUsedGb = (total - avail) / 1048576;
    }

    FileView {
        id: netFile
        path: "/proc/net/dev"
        blockLoading: true
    }
    FileView {
        id: upFile
        path: "/proc/uptime"
        blockLoading: true
    }

    // Velocidad de red: diferencia de bytes entre lecturas (sin contar "lo")
    function updateNet() {
        netFile.reload();
        let rx = 0, tx = 0;
        for (const line of netFile.text().split("\n").slice(2)) {
            const parts = line.trim().split(/[:\s]+/);
            if (parts.length < 10 || parts[0] === "lo")
                continue;
            rx += Number(parts[1]);
            tx += Number(parts[9]);
        }
        if (root.lastNet) {
            root.netDown = (rx - root.lastNet.rx) / 2;   // el Timer va cada 2 s
            root.netUp = (tx - root.lastNet.tx) / 2;
        }
        root.lastNet = {
            rx: rx,
            tx: tx
        };
    }

    function updateUptime() {
        upFile.reload();
        root.uptime = Number(upFile.text().split(" ")[0]);
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.updateCpu();
            root.updateRam();
            root.updateNet();
            root.updateUptime();
        }
    }

    // Red: nombre de la wifi, "Ethernet" u "Offline"
    Process {
        id: netProc
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                let name = "Offline";
                let vpn = false;
                for (const line of this.text.trim().split("\n")) {
                    const parts = line.split(":");
                    if (parts[1] !== "connected")
                        continue;
                    if (parts[0] === "wireguard" || parts[0] === "tun" || parts[0] === "vpn")
                        vpn = true;
                    else if (parts[0] === "wifi" && name === "Offline")
                        name = parts[2];
                    else if (parts[0] === "ethernet" && name === "Offline")
                        name = "Ethernet";
                }
                root.network = name;
                root.vpn = vpn;
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

    // Temperatura del paquete de CPU (o la primera zona) y espacio libre en /
    Process {
        id: hwProc
        command: ["sh", "-c", "t=$(for z in /sys/class/thermal/thermal_zone*; do [ \"$(cat $z/type)\" = x86_pkg_temp ] && cat $z/temp && break; done); " + "[ -z \"$t\" ] && t=$(cat /sys/class/thermal/thermal_zone0/temp); " + "echo $t $(df -h --output=avail / | tail -1)"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.trim().split(/\s+/);
                root.temp = Math.round(Number(p[0]) / 1000);
                root.diskFree = p[1] || "—";
            }
        }
    }
    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: hwProc.running = true
    }
}
