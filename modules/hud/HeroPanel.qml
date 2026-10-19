import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Shapes
import "../../config"
import "../../services"
import "../common"

// Panel central: retrato, estadísticas, vida/maná, buffs, habilidades e inventario
Item {
    id: hero
    width: 1090
    height: 196

    // ── Datos ──
    readonly property string user: Quickshell.env("USER") || "?"
    readonly property string home: Quickshell.env("HOME")
    readonly property var bat: UPower.displayDevice
    readonly property bool hasBattery: bat !== null && bat.isLaptopBattery
    readonly property int batPct: !bat ? 0 : Math.round(bat.percentage > 1 ? bat.percentage : bat.percentage * 100)
    readonly property bool charging: hasBattery && bat.state === UPowerDeviceState.Charging
    readonly property int level: Math.floor(SysStats.uptime / 3600) + 1          // 1 nivel por hora encendido
    readonly property real xp: (SysStats.uptime % 3600) / 3600                    // progreso al siguiente

    property real now: Date.now()
    Timer {
        interval: 1000
        repeat: true
        running: Capture.recording
        onTriggered: hero.now = Date.now()
    }

    function rate(b) {
        if (b >= 1048576)
            return (b / 1048576).toFixed(1) + "M";
        if (b >= 1024)
            return Math.round(b / 1024) + "K";
        return Math.round(b) + "B";
    }
    function mmss(ms) {
        const s = Math.max(0, Math.floor(ms / 1000));
        const m = Math.floor(s / 60);
        return (m < 10 ? "0" : "") + m + ":" + (s % 60 < 10 ? "0" : "") + (s % 60);
    }
    // Tecla → habilidad. Devuelve true si la tecla era de una habilidad.
    function press(k) {
        const map = {
            Q: abQ,
            W: abW,
            E: abE,
            D: abD,
            F: abF,
            R: abR
        };
        if (!map[k])
            return false;
        map[k].trigger();
        return true;
    }

    // Buffs activos (estados del sistema)
    readonly property var buffs: {
        const list = [];
        if (Capture.recording)
            list.push({
                text: "● REC " + mmss(now - Capture.recStart),
                tint: "#6e2a20"
            });
        if (SysStats.vpn)
            list.push({
                text: "⛨ VPN",
                tint: "#2c4a6e"
            });
        if (Toggles.dnd)
            list.push({
                text: "⊘ NO MOLESTAR",
                tint: "#3a2c5e"
            });
        if (Toggles.night)
            list.push({
                text: "☾ NOCTURNA",
                tint: "#5a4a1e"
            });
        if (charging)
            list.push({
                text: "⚡ CARGANDO",
                tint: "#2e5226"
            });
        return list;
    }

    // ── Piezas ──
    component StatRow: Row {
        id: sr
        property string label
        property string value
        spacing: 6
        Text {
            width: 40
            text: sr.label
            color: Theme.textMute
            font.family: "monospace"
            font.pixelSize: 10
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: sr.value
            color: Theme.text
            font.family: "monospace"
            font.pixelSize: 12
            font.bold: true
        }
    }

    component ResourceBar: Rectangle {
        id: rb
        property real value: 0
        property string label
        property string regen: ""
        property color topColor
        property color botColor
        color: Theme.edgeDark
        border.width: 1
        border.color: Qt.darker(topColor, 2.5)
        Rectangle {
            x: 1
            y: 1
            height: parent.height - 2
            width: (parent.width - 2) * Math.max(0, Math.min(1, rb.value))
            Behavior on width {
                NumberAnimation {
                    duration: 300
                }
            }
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: rb.topColor
                }
                GradientStop {
                    position: 1
                    color: rb.botColor
                }
            }
        }
        Text {
            anchors.centerIn: parent
            text: rb.label
            color: "white"
            font.family: "monospace"
            font.pixelSize: rb.height > 15 ? 12 : 10
            font.bold: true
            style: Text.Outline
            styleColor: "#000000"
        }
        Text {
            anchors {
                right: parent.right
                rightMargin: 6
                verticalCenter: parent.verticalCenter
            }
            text: rb.regen
            color: "#b8f0a8"
            font.family: "monospace"
            font.pixelSize: 10
            font.bold: true
            style: Text.Outline
            styleColor: "#000000"
        }
    }

    // Hueco vacío (habilidad o inventario), con tecla opcional
    component EmptySlot: Rectangle {
        id: es
        property string key: ""
        color: Theme.slot
        border.width: 1
        border.color: Theme.edgeDark
        Rectangle {
            visible: es.key !== ""
            x: 3
            y: 3
            width: 15
            height: 15
            color: Theme.slot
            border.width: 1
            border.color: Theme.edge
            Text {
                anchors.centerIn: parent
                text: es.key
                color: Theme.textMute
                font.family: "monospace"
                font.pixelSize: 10
                font.bold: true
            }
        }
    }

    // ── Buffs (encima del marco) ──
    Row {
        x: 12
        y: 0
        spacing: 4
        Repeater {
            model: hero.buffs
            Rectangle {
                required property var modelData
                height: 24
                width: buffText.implicitWidth + 16
                border.width: 1
                border.color: Theme.edgeDark
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: modelData.tint
                    }
                    GradientStop {
                        position: 1
                        color: Qt.darker(modelData.tint, 2.6)
                    }
                }
                Text {
                    id: buffText
                    anchors.centerIn: parent
                    text: modelData.text
                    color: Theme.text
                    font.family: "monospace"
                    font.pixelSize: 11
                    font.bold: true
                }
            }
        }
    }

    // ── Marco ──
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 164
        border.width: 1
        border.color: Theme.frameEdge
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Theme.frameTop
            }
            GradientStop {
                position: 1
                color: Theme.frameBot
            }
        }

        TexturePanel {
            anchors {
                fill: parent
                margins: 5
                bottomMargin: 0
            }
            shade: 0.35
            accentTop: true
            border.width: 1
            border.color: Theme.edgeDark

            Row {
                anchors {
                    fill: parent
                    topMargin: 8
                    bottomMargin: 8
                    leftMargin: 10
                    rightMargin: 10
                }
                spacing: 12

                // ─ Retrato ─
                Column {
                    width: 160
                    height: parent.height
                    spacing: 4

                    Rectangle {
                        width: parent.width
                        height: 20
                        color: Qt.rgba(0, 0, 0, 0.5)
                        border.width: 1
                        border.color: Theme.edge
                        Text {
                            anchors.centerIn: parent
                            text: hero.user.toUpperCase()
                            color: Theme.text
                            font.pixelSize: 13
                            font.bold: true
                            font.letterSpacing: 2
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: parent.height - 24
                        border.width: 1
                        border.color: Theme.accentLight
                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: Qt.darker(Theme.playerColors[0], 1.8)
                            }
                            GradientStop {
                                position: 1
                                color: Qt.darker(Theme.playerColors[0], 4.5)
                            }
                        }

                        Item {
                            anchors {
                                fill: parent
                                margins: 1
                            }
                            clip: true
                            Image {
                                id: face
                                anchors.fill: parent
                                source: "file://" + hero.home + "/.face?" + Settings.faceStamp
                                cache: false
                                fillMode: Image.PreserveAspectCrop
                                sourceSize: Qt.size(320, 240)
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: face.status !== Image.Ready
                                text: hero.user.charAt(0).toUpperCase()
                                color: Theme.text
                                font.pixelSize: 44
                                font.bold: true
                            }
                        }

                        // Nivel con anillo de experiencia
                        Item {
                            x: -10
                            y: parent.height - 30
                            width: 40
                            height: 40
                            Rectangle {
                                anchors.fill: parent
                                radius: 20
                                color: Theme.edgeDark
                            }
                            Shape {
                                anchors.fill: parent
                                preferredRendererType: Shape.CurveRenderer
                                ShapePath {
                                    strokeColor: Theme.accentLight
                                    strokeWidth: 4
                                    fillColor: "transparent"
                                    capStyle: ShapePath.FlatCap
                                    PathAngleArc {
                                        centerX: 20
                                        centerY: 20
                                        radiusX: 17
                                        radiusY: 17
                                        startAngle: -90
                                        sweepAngle: 360 * hero.xp
                                    }
                                }
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: 28
                                height: 28
                                radius: 14
                                gradient: Gradient {
                                    GradientStop {
                                        position: 0
                                        color: Theme.dialTop
                                    }
                                    GradientStop {
                                        position: 1
                                        color: Theme.dialBot
                                    }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: hero.level
                                    color: Theme.text
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                            }
                        }
                    }
                }

                // ─ Estadísticas ─
                Column {
                    width: 110
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    StatRow {
                        label: "TEMP"
                        value: SysStats.temp + "°C"
                    }
                    StatRow {
                        label: "DISCO"
                        value: SysStats.diskFree
                    }
                    StatRow {
                        label: "NET"
                        value: "↓" + hero.rate(SysStats.netDown)
                    }
                    StatRow {
                        label: ""
                        value: "↑" + hero.rate(SysStats.netUp)
                    }
                }

                // ─ Vida, maná y habilidades ─
                Column {
                    width: 552
                    spacing: 6

                    ResourceBar {
                        width: parent.width
                        height: 18
                        value: hero.hasBattery ? hero.batPct / 100 : 1
                        label: hero.hasBattery ? hero.batPct + " / 100" : "AC"
                        regen: hero.charging && hero.bat.changeRate ? "+" + Math.abs(hero.bat.changeRate).toFixed(1) + "W" : ""
                        topColor: "#5fae4c"
                        botColor: "#2f6a24"
                    }
                    ResourceBar {
                        width: parent.width
                        height: 14
                        value: SysStats.ramPercent / 100
                        label: SysStats.ramUsedGb.toFixed(1) + " / " + Math.round(SysStats.ramTotalGb) + " GB"
                        topColor: Theme.manaTop
                        botColor: Theme.manaBot
                    }

                    // Habilidades
                    Row {
                        topPadding: 6
                        spacing: 6

                        // Ajustes (panel futuro)
                        Ability {
                            width: 34
                            height: 56
                            icon: "settings.svg"
                            onActivated: ShellState.settingsOpen = true
                        }

                        Ability {
                            id: abQ
                            key: "Q"
                            name: "WI-FI"
                            icon: "wifi.svg"
                            on: Toggles.wifi
                            topColor: "#245060"
                            bottomColor: "#0e2128"
                            onActivated: Toggles.toggleWifi()
                        }
                        Ability {
                            id: abW
                            key: "W"
                            name: "BLUETOOTH"
                            icon: "bluetooth.svg"
                            on: Toggles.bluetooth
                            topColor: "#2c3a6e"
                            bottomColor: "#10142b"
                            onActivated: Toggles.toggleBluetooth()
                        }
                        Ability {
                            id: abE
                            key: "E"
                            name: "SILENCIO"
                            icon: "dnd.svg"
                            on: Toggles.dnd
                            topColor: "#3a2c5e"
                            bottomColor: "#141026"
                            onActivated: Toggles.toggleDnd()
                        }
                        Ability {
                            id: abD
                            key: "D"
                            name: "NOCTURNA"
                            icon: "night.svg"
                            on: Toggles.night
                            topColor: "#5a4a1e"
                            bottomColor: "#241d0b"
                            onActivated: Toggles.toggleNight()
                        }
                        Ability {
                            id: abF
                            key: "F"
                            name: "CAPTURA"
                            icon: "capture.svg"
                            cooldown: 3000
                            onActivated: Capture.startSelect("area")
                        }

                        // Definitiva: cambiar de modo
                        Ability {
                            id: abR
                            key: "R"
                            icon: "dire.svg"
                            big: true
                            name: ShellState.mode === "dire" ? "RADIANT" : "DIRE"
                            topColor: ShellState.mode === "dire" ? "#2e5226" : "#6e2a20"
                            bottomColor: ShellState.mode === "dire" ? "#14240f" : "#2a0e0a"
                            cooldown: 2000
                            onActivated: ShellState.mode = ShellState.mode === "dire" ? "radiant" : "dire"
                        }
                    }
                }

                // ─ Inventario: fase 3 (salvo el reproductor) ─
                Column {
                    width: 200
                    spacing: 5

                    Grid {
                        columns: 3
                        spacing: 3
                        Repeater {
                            model: 6
                            EmptySlot {
                                width: 50
                                height: 36
                            }
                        }
                    }

                    Row {
                        spacing: 3
                        Repeater {
                            model: 3
                            EmptySlot {
                                width: 30
                                height: 22
                            }
                        }
                        Item {
                            width: 34
                            height: 1
                        }

                        // TP: fase 3
                        Rectangle {
                            width: 30
                            height: 30
                            radius: 15
                            color: Theme.slot
                            border.width: 2
                            border.color: Theme.edge
                            Text {
                                anchors.centerIn: parent
                                text: "TP"
                                color: Theme.textMute
                                font.family: "monospace"
                                font.pixelSize: 9
                                font.bold: true
                            }
                        }

                        // Reproductor: abre el panel Now Playing
                        Rectangle {
                            width: 30
                            height: 30
                            radius: 15
                            color: Media.active ? Theme.positiveBot : Theme.slot
                            border.width: 2
                            border.color: Media.active ? Theme.positive : Theme.edge
                            Text {
                                anchors.centerIn: parent
                                text: "♪"
                                color: Media.player && Media.player.isPlaying ? Theme.positive : Theme.textMute
                                font.pixelSize: 14
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                enabled: Media.active
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ShellState.mediaOpen = !ShellState.mediaOpen
                            }
                        }
                    }

                    Text {
                        text: "INVENTARIO · MOCHILA"
                        color: Theme.textMute
                        font.family: "monospace"
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 1.2
                    }
                }
            }
        }
    }
}
