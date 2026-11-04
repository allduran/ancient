pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../config"

// Interruptores rápidos: Wi-Fi, Bluetooth, No molestar, luz nocturna
Singleton {
    id: root

    property bool wifi: false
    property bool bluetooth: false
    property bool dnd: false            // No molestar (solo dentro del shell)
    property bool night: false
    readonly property int nightTemp: Settings.data.nightTemp   // K (Ajustes → Sistema)

    function toggleWifi() {
        root.wifi = !root.wifi;
        Quickshell.execDetached(["nmcli", "radio", "wifi", root.wifi ? "on" : "off"]);
    }
    function toggleBluetooth() {
        root.bluetooth = !root.bluetooth;
        Quickshell.execDetached(["bluetoothctl", "power", root.bluetooth ? "on" : "off"]);
    }
    function toggleDnd() {
        root.dnd = !root.dnd;
    }
    function toggleNight() {
        setNight(!root.night);
    }
    function setNight(on) {
        root.night = on;
        if (on)
            Quickshell.execDetached(["sh", "-c", "pkill -x hyprsunset; sleep 0.2; hyprsunset -t \"$1\"", "sh", String(root.nightTemp)]);
        else
            Quickshell.execDetached(["pkill", "-x", "hyprsunset"]);
    }

    // Cambiar la temperatura con la luz encendida la aplica al momento
    onNightTempChanged: if (root.night)
        setNight(true)

    // Luz nocturna automática: se enciende al entrar en el horario y se apaga al salir
    // (fuera de esos dos momentos puedes encenderla o apagarla a mano)
    function inNightHours() {
        const h = new Date().getHours();
        const from = Settings.data.nightFrom, to = Settings.data.nightTo;
        return from > to ? (h >= from || h < to) : (h >= from && h < to);
    }
    property bool wasNightHours: false
    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const now = root.inNightHours();
            if (Settings.data.nightAuto && now !== root.wasNightHours)
                root.setNight(now);
            root.wasNightHours = now;
        }
    }

    // Lee el estado real cada 5 s (por si se cambia desde fuera)
    Process {
        id: poll
        command: ["sh", "-c", "nmcli radio wifi; " + "bluetoothctl show | grep -q 'Powered: yes' && echo on || echo off; " + "pgrep -x hyprsunset >/dev/null && echo on || echo off"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = this.text.trim().split("\n");
                root.wifi = l[0] === "enabled";
                root.bluetooth = l[1] === "on";
                root.night = l[2] === "on";
            }
        }
    }
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: poll.running = true
    }
}
