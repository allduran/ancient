pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../config"

// Energía (Ajustes → Sistema)
//   · inactividad: ancient lanza su propio hypridle con ~/.local/state/ancient/hypridle.conf
//     (el hypridle.service del sistema se para mientras ancient está activo, para no duplicar)
//   · perfil de energía con powerprofilesctl; en modo Dire, rendimiento si se pide
Singleton {
    id: root

    readonly property string conf: Quickshell.env("HOME") + "/.local/state/ancient/hypridle.conf"
    property string profile: ""         // perfil activo (vacío = no hay power-profiles-daemon)
    readonly property bool hasProfiles: profile !== ""

    // La llama Settings al cargar
    function init() {
        Quickshell.execDetached(["systemctl", "--user", "stop", "hypridle.service"]);
        getProfile.running = true;
        writeIdle();
    }

    // ── Inactividad ──
    function writeIdle() {
        const d = Settings.data;
        const l = ["# Generado por ancient (Ajustes → Sistema). Los cambios a mano se pisan.", "general {", "    lock_cmd = qs -c ancient ipc call lock lock"];
        if (d.lockOnSuspend)
            l.push("    before_sleep_cmd = loginctl lock-session");
        l.push("    after_sleep_cmd = hyprctl dispatch dpms on", "}");
        if (d.idleLock > 0)
            l.push("listener {", "    timeout = " + d.idleLock * 60, "    on-timeout = loginctl lock-session", "}");
        if (d.idleDpms > 0)
            l.push("listener {", "    timeout = " + d.idleDpms * 60, "    on-timeout = hyprctl dispatch dpms off", "    on-resume = hyprctl dispatch dpms on", "}");
        if (d.idleSuspend > 0)
            l.push("listener {", "    timeout = " + d.idleSuspend * 60, "    on-timeout = systemctl suspend", "}");
        writer.command = ["sh", "-c", "mkdir -p \"$(dirname \"$0\")\" && printf '%s\\n' \"$@\" > \"$0\"", root.conf].concat(l);
        writer.running = true;
    }
    Process {
        id: writer
        onExited: {
            idle.running = false;           // reinicia hypridle con la config nueva
            restartIdle.restart();
        }
    }
    Timer {
        id: restartIdle
        interval: 300
        onTriggered: idle.running = true
    }
    Process {
        id: idle                            // vive mientras viva ancient
        command: ["hypridle", "-c", root.conf]
    }

    // ── Gamemode (build de Dire) ──
    // `gamemoded -r` pide gamemode y lo mantiene mientras siga vivo
    Process {
        running: ShellState.mode === "dire" && Settings.data.direGamemode
        command: ["gamemoded", "-r"]
    }

    // ── Perfil de energía ──
    function applyProfile() {
        if (!root.hasProfiles)
            return;
        const want = ShellState.mode === "dire" && Settings.data.direPerformance ? "performance" : Settings.data.powerProfile;
        if (want === root.profile)
            return;
        Quickshell.execDetached(["powerprofilesctl", "set", want]);
        root.profile = want;
    }
    Process {
        id: getProfile
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.profile = this.text.trim();
                root.applyProfile();
            }
        }
    }

    Connections {
        target: ShellState
        function onModeChanged() {
            root.applyProfile();
        }
    }
    Connections {
        target: Settings.data
        function onIdleLockChanged() {
            root.writeIdle();
        }
        function onIdleDpmsChanged() {
            root.writeIdle();
        }
        function onIdleSuspendChanged() {
            root.writeIdle();
        }
        function onLockOnSuspendChanged() {
            root.writeIdle();
        }
        function onPowerProfileChanged() {
            root.applyProfile();
        }
        function onDirePerformanceChanged() {
            root.applyProfile();
        }
    }
}
