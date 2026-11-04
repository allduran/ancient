pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import "../config"

// Volumen de la salida de audio por defecto
Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink !== null && sink.audio !== null
    readonly property real volume: ready ? sink.audio.volume : 0
    readonly property bool muted: ready ? sink.audio.muted : false

    PwObjectTracker {
        objects: [root.sink]
    }

    function setVolume(v) {
        if (ready)
            sink.audio.volume = Math.max(0, Math.min(Settings.data.volMax / 100, v));   // tope de Ajustes → Sistema
    }
    function up() {
        if (muted)
            sink.audio.muted = false;     // subir quita el silencio
        setVolume(volume + Settings.data.volStep / 100);
    }
    function down() {
        setVolume(volume - Settings.data.volStep / 100);
    }
    function toggleMute() {
        if (ready)
            sink.audio.muted = !muted;
    }
}
