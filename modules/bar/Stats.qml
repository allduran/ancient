import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick
import "../../config"
import "../../services"

// Stats en dos líneas, estilo K/D/A
Grid {
    id: root
    columns: 3
    columnSpacing: 14
    rowSpacing: 0

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var bat: UPower.displayDevice
    readonly property bool hasBattery: bat !== null && bat.isLaptopBattery
    readonly property int batPct: !bat ? 0 : Math.round(bat.percentage > 1 ? bat.percentage : bat.percentage * 100)
    readonly property bool charging: hasBattery && bat.state === UPowerDeviceState.Charging

    PwObjectTracker {
        objects: [root.sink]
    }    // necesario para leer el volumen

    // Una estadística: etiqueta apagada + valor
    component Stat: Item {
        id: stat
        property string label
        property string value
        property color valueColor: Theme.text
        property bool interactive: false
        signal clicked
        signal scrolled(int delta)

        implicitWidth: row.implicitWidth
        implicitHeight: row.implicitHeight

        Row {
            id: row
            spacing: 4
            Text {
                text: stat.label
                color: Theme.textMute
                font.family: "monospace"
                font.pixelSize: 10
                font.bold: true
            }
            Text {
                text: stat.value
                color: stat.valueColor
                font.family: "monospace"
                font.pixelSize: 10
                font.bold: true
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: stat.interactive
            cursorShape: Qt.PointingHandCursor
            onClicked: stat.clicked()
            onWheel: w => stat.scrolled(w.angleDelta.y)
        }
    }

    // ── Línea 1 ──
    Stat {
        label: "CPU"
        value: SysStats.cpu + "%"
        valueColor: SysStats.cpu > 85 ? Theme.dire : Theme.text
    }
    Stat {
        label: "RAM"
        value: SysStats.ramPercent + "%"
        valueColor: SysStats.ramPercent > 85 ? Theme.dire : Theme.text
    }
    Stat {
        label: "NET"
        value: SysStats.network
        valueColor: SysStats.network === "Offline" ? Theme.dire : Theme.text
    }

    // ── Línea 2 ──
    Stat {
        label: "VOL"
        interactive: true
        value: !root.sink || !root.sink.audio ? "—" : root.sink.audio.muted ? "MUTE" : Math.round(root.sink.audio.volume * 100) + "%"
        valueColor: root.sink && root.sink.audio && root.sink.audio.muted ? Theme.textMute : Theme.text
        onClicked: if (root.sink && root.sink.audio)
            root.sink.audio.muted = !root.sink.audio.muted
        onScrolled: delta => {
            if (!root.sink || !root.sink.audio)
                return;
            const v = root.sink.audio.volume + (delta > 0 ? 0.05 : -0.05);
            root.sink.audio.volume = Math.max(0, Math.min(1, v));
        }
    }
    Stat {
        visible: root.hasBattery
        label: "BAT"
        value: (root.charging ? "⚡" : "") + root.batPct + "%"
        valueColor: root.batPct < 15 && !root.charging ? Theme.dire : Theme.radiant
    }
}
