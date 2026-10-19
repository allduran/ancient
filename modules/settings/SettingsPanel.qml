import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes
import "../../config"
import "../../services"
import "../common"

// Ajustes: loadout del héroe (apariencia) + árbol de talentos (comportamiento)
PanelWindow {
    id: win
    visible: ShellState.settingsOpen

    WlrLayershell.namespace: "ancient-settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    readonly property string home: Quickshell.env("HOME")
    property string page: "talents"     // talents | wallpaper | theme | avatar | terminal | apps
    property string appQuery: ""
    property var avatars: []
    property var terminals: []

    onVisibleChanged: {
        if (!visible)
            return;
        page = "talents";
        Wallpapers.refresh();
        scan.running = true;
        Qt.callLater(() => keys.forceActiveFocus());
    }

    function close() {
        ShellState.settingsOpen = false;
    }

    // Avatares (~/Pictures y ~/Pictures/Avatars) y terminales instaladas
    Process {
        id: scan
        command: ["sh", "-c",
            "find \"$HOME/Pictures\" \"$HOME/Pictures/Avatars\" -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) ! -name 'wallpaper-dota-*' 2>/dev/null | sort -u | head -n 60; " +
            "echo '--'; for t in foot kitty alacritty wezterm ghostty konsole; do command -v $t >/dev/null && echo $t; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.split("--\n");
                win.avatars = (parts[0] || "").split("\n").filter(l => l !== "");
                win.terminals = (parts[1] || "").split("\n").filter(l => l !== "");
            }
        }
    }

    Item {
        id: keys
        focus: true
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape) {
                win.close();
                e.accepted = true;
            }
        }
    }

    // Fondo: clic fuera = cerrar
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        MouseArea { anchors.fill: parent; onClicked: win.close() }
    }

    // ── Piezas ──
    component Section: Text {
        color: Theme.accentLight
        font.pixelSize: 12; font.bold: true; font.letterSpacing: 2.2
    }

    // Hueco equipado (abre su página a la derecha)
    component Slot: Rectangle {
        id: slot
        property string key
        property string value
        property string target
        default property alias art: artArea.data
        readonly property bool active: win.page === target
        height: 96
        color: "#050607"
        clip: true
        border.width: active ? 2 : 1
        border.color: active ? Theme.accentLight : (slotArea.containsMouse ? Theme.accent : "#050607")
        Item { id: artArea; anchors.fill: parent; anchors.margins: slot.border.width }
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 46
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.88) }
            }
            Column {
                x: 10
                anchors { bottom: parent.bottom; bottomMargin: 6 }
                Text { text: slot.key; color: Theme.textMute; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.8 }
                Text { width: slot.width - 20; elide: Text.ElideRight; text: slot.value; color: Theme.text; font.pixelSize: 14; font.bold: true }
            }
        }
        MouseArea { id: slotArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.page = slot.target }
    }

    // Botón de modo (Radiant / Dire)
    component ModeButton: Rectangle {
        id: mb
        property string mode
        property string label
        property color tint
        readonly property bool on: ShellState.mode === mode
        height: 30
        color: on ? Qt.rgba(tint.r, tint.g, tint.b, 0.3) : Qt.rgba(0, 0, 0, 0.5)
        border.width: 1
        border.color: on ? tint : Theme.edge
        Text { anchors.centerIn: parent; text: mb.label; color: mb.on ? Theme.text : Theme.textMute; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1.6 }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ShellState.mode = mb.mode }
    }

    // Un talento (mitad izquierda o derecha de un nivel)
    component Talent: Rectangle {
        id: tal
        property string title
        property string desc
        property bool on
        property bool rightSide
        signal picked
        width: 240
        height: 64
        border.width: 1
        border.color: on ? Theme.accentLight : (talArea.containsMouse ? Theme.edge : "#050607")
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: tal.rightSide ? 1 : 0; color: tal.on ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.28) : Qt.rgba(0, 0, 0, 0.5) }
            GradientStop { position: tal.rightSide ? 0 : 1; color: Qt.rgba(0, 0, 0, 0.5) }
        }
        Column {
            anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right; leftMargin: 16; rightMargin: 16 }
            spacing: 2
            Text {
                width: parent.width
                horizontalAlignment: tal.rightSide ? Text.AlignLeft : Text.AlignRight
                text: tal.title
                color: tal.on ? Theme.text : Theme.textMute
                elide: Text.ElideRight
                font.pixelSize: 14; font.bold: true
            }
            Text {
                width: parent.width
                horizontalAlignment: tal.rightSide ? Text.AlignLeft : Text.AlignRight
                text: tal.desc
                elide: Text.ElideRight
                color: tal.on ? Theme.textSoft : Theme.label
                font.pixelSize: 12
            }
        }
        MouseArea { id: talArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tal.picked() }
    }

    // ── Ventana ──
    Rectangle {
        anchors.centerIn: parent
        width: 1160
        height: 720
        border.width: 1
        border.color: Theme.frameEdge
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.frameTop }
            GradientStop { position: 1; color: Theme.frameBot }
        }
        MouseArea { anchors.fill: parent }

        TexturePanel {
            anchors { fill: parent; margins: 5 }
            shade: 0.45
            accentTop: true
            border.width: 1
            border.color: Theme.edgeDark

            // Cabecera
            Rectangle {
                id: head
                width: parent.width
                height: 56
                color: Qt.rgba(0, 0, 0, 0.35)
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.edge }
                Row {
                    x: 18
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 18
                    Text { text: "AJUSTES"; color: Theme.text; font.pixelSize: 20; font.bold: true; font.letterSpacing: 2 }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: win.page === "talents" ? "ÁRBOL DE TALENTOS · COMPORTAMIENTO" : "LOADOUT · APARIENCIA"
                        color: Theme.accentLight
                        font.pixelSize: 12; font.bold: true; font.letterSpacing: 2.4
                    }
                }
                Text {
                    anchors { right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }
                    text: "✕"
                    color: Theme.textMute
                    font.pixelSize: 20
                    MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: win.close() }
                }
            }

            Row {
                anchors { top: head.bottom; left: parent.left; right: parent.right; bottom: parent.bottom; margins: 18 }
                spacing: 18

                // ─ Héroe ─
                Column {
                    width: 220
                    height: parent.height
                    spacing: 10

                    Rectangle {
                        width: parent.width
                        height: 30
                        color: Qt.rgba(0, 0, 0, 0.5)
                        border.width: 1
                        border.color: Theme.edge
                        Text { anchors.centerIn: parent; text: (Quickshell.env("USER") || "").toUpperCase(); color: Theme.text; font.pixelSize: 15; font.bold: true; font.letterSpacing: 2 }
                    }

                    Rectangle {
                        width: parent.width
                        height: parent.height - 30 - 30 - 64 - 30
                        border.width: 2
                        border.color: Theme.accentLight
                        gradient: Gradient {
                            GradientStop { position: 0; color: Qt.darker(Theme.playerColors[0], 1.8) }
                            GradientStop { position: 1; color: Qt.darker(Theme.playerColors[0], 4.5) }
                        }
                        Image {
                            id: faceImg
                            anchors { fill: parent; margins: 2 }
                            source: "file://" + win.home + "/.face?" + Settings.faceStamp
                            fillMode: Image.PreserveAspectCrop
                            cache: false
                            asynchronous: true
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: faceImg.status !== Image.Ready
                            text: (Quickshell.env("USER") || "?").charAt(0).toUpperCase()
                            color: Theme.text
                            font.pixelSize: 80; font.bold: true
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 6
                        ModeButton { width: (parent.width - 6) / 2; mode: "radiant"; label: "RADIANT"; tint: Theme.positive }
                        ModeButton { width: (parent.width - 6) / 2; mode: "dire"; label: "DIRE"; tint: "#e0583a" }
                    }

                    // Botón del árbol de talentos
                    Rectangle {
                        width: parent.width
                        height: 64
                        border.width: win.page === "talents" ? 2 : 1
                        border.color: win.page === "talents" ? Theme.accentLight : Theme.edge
                        gradient: Gradient {
                            GradientStop { position: 0; color: Theme.dialTop }
                            GradientStop { position: 1; color: Theme.dialBot }
                        }
                        Row {
                            anchors.centerIn: parent
                            spacing: 12
                            // Mini árbol
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3
                                Repeater {
                                    model: 4
                                    Row {
                                        required property int index
                                        spacing: 3
                                        Rectangle { width: 10; height: 6; color: index % 2 === 0 ? Theme.accentLight : Theme.label }
                                        Rectangle { width: 4; height: 6; color: Theme.accent }
                                        Rectangle { width: 10; height: 6; color: index % 2 === 1 ? Theme.accentLight : Theme.label }
                                    }
                                }
                            }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                Text { text: "TALENTOS"; color: Theme.text; font.pixelSize: 16; font.bold: true; font.letterSpacing: 2 }
                                Text { text: "comportamiento"; color: Theme.textMute; font.pixelSize: 11 }
                            }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.page = "talents" }
                    }
                }

                // ─ Huecos equipados ─
                Column {
                    width: 260
                    height: parent.height
                    spacing: 10

                    Section { text: "EQUIPADO" }
                    Grid {
                        width: parent.width
                        columns: 2
                        spacing: 8

                        Slot {
                            width: (parent.width - 8) / 2
                            key: "FONDO"; target: "wallpaper"
                            value: Wallpapers.current !== "" ? Wallpapers.current.split("/").pop().replace(/\.\w+$/, "") : "—"
                            Image {
                                anchors.fill: parent
                                source: Wallpapers.current !== "" ? "file://" + Wallpapers.current : ""
                                sourceSize.width: 300
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }
                        Slot {
                            width: (parent.width - 8) / 2
                            key: "TEMA"; target: "theme"
                            value: ShellState.mode === "dire" ? "Dire" : "Radiant"
                            Row {
                                anchors.fill: parent
                                Rectangle { width: parent.width / 3; height: parent.height; color: Theme.accent }
                                Rectangle { width: parent.width / 3; height: parent.height; color: Theme.frameTop }
                                TexturePanel { width: parent.width / 3; height: parent.height }
                            }
                        }
                        Slot {
                            width: (parent.width - 8) / 2
                            key: "AVATAR"; target: "avatar"
                            value: "~/.face"
                            Image {
                                anchors.fill: parent
                                source: "file://" + win.home + "/.face?" + Settings.faceStamp
                                fillMode: Image.PreserveAspectCrop
                                cache: false
                                asynchronous: true
                            }
                        }
                        Slot {
                            width: (parent.width - 8) / 2
                            key: "TERMINAL"; target: "terminal"
                            value: ShellState.terminal
                            Rectangle {
                                anchors.fill: parent
                                color: "#0a0c0e"
                                Text { x: 10; y: 10; text: "❯ _"; color: Theme.positive; font.family: "monospace"; font.pixelSize: 16; font.bold: true }
                            }
                        }
                    }

                    Section { text: "APPS FIJADAS"; topPadding: 8 }
                    Flow {
                        width: parent.width
                        spacing: 4
                        Repeater {
                            model: ShellState.pinnedApps
                            Rectangle {
                                required property string modelData
                                readonly property var entry: Apps.byId(modelData)
                                width: 56; height: 44
                                border.width: 1
                                border.color: "#050607"
                                gradient: Gradient {
                                    GradientStop { position: 0; color: Apps.color(entry) }
                                    GradientStop { position: 1; color: "#0a0c0e" }
                                }
                                Image {
                                    anchors.centerIn: parent
                                    width: 24; height: 24
                                    source: Apps.icon(parent.entry)
                                    sourceSize: Qt.size(24, 24)
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: m => {
                                        if (m.button === Qt.RightButton)
                                            ShellState.pinnedApps = ShellState.pinnedApps.filter(k => k !== parent.modelData);
                                        else
                                            win.page = "apps";
                                    }
                                }
                            }
                        }
                        Rectangle {
                            width: 56; height: 44
                            color: Qt.rgba(0, 0, 0, 0.4)
                            border.width: 1
                            border.color: win.page === "apps" ? Theme.accentLight : Theme.edge
                            Text { anchors.centerIn: parent; text: "+"; color: Theme.textMute; font.pixelSize: 22 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.page = "apps" }
                        }
                    }
                    Text { width: parent.width; wrapMode: Text.WordWrap; text: "Clic derecho en una app para quitarla"; color: Theme.textMute; font.pixelSize: 12 }
                }

                // ─ Panel derecho: página elegida ─
                Rectangle {
                    width: parent.width - 220 - 260 - 36
                    height: parent.height
                    color: Qt.rgba(0, 0, 0, 0.45)
                    border.width: 1
                    border.color: Theme.edge
                    clip: true

                    Rectangle {
                        id: pageHead
                        width: parent.width
                        height: 40
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) }
                            GradientStop { position: 1; color: "transparent" }
                        }
                        Text {
                            x: 14
                            anchors.verticalCenter: parent.verticalCenter
                            text: ({ talents: "TALENTOS", wallpaper: "FONDO", theme: "TEMA", avatar: "AVATAR", terminal: "TERMINAL", apps: "APPS FIJADAS" })[win.page]
                            color: Theme.accentLight
                            font.pixelSize: 13; font.bold: true; font.letterSpacing: 2
                        }
                        Text {
                            anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                            text: ({
                                talents: "elige un lado en cada nivel",
                                wallpaper: Wallpapers.list.length + " en ~/Pictures/Wallpapers",
                                theme: "también con la R del HUD",
                                avatar: "imágenes de ~/Pictures y ~/Pictures/Avatars",
                                terminal: "la que abre Quick buy",
                                apps: "clic para fijar o quitar"
                            })[win.page]
                            color: Theme.textMute
                            font.pixelSize: 12
                        }
                    }

                    Item {
                        anchors { top: pageHead.bottom; left: parent.left; right: parent.right; bottom: parent.bottom; margins: 14 }

                        // TALENTOS
                        Item {
                            anchors.fill: parent
                            visible: win.page === "talents"

                            Rectangle {                      // tronco
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 10
                                width: 4
                                height: parent.height - 20
                                gradient: Gradient {
                                    GradientStop { position: 0; color: Theme.accentLight }
                                    GradientStop { position: 1; color: Qt.darker(Theme.accent, 1.8) }
                                }
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 12
                                Repeater {
                                    model: [
                                        { lvl: "35", cat: "VENTANAS", key: "floating", l: ["Mosaico automático", "Hyprland coloca las ventanas"], r: ["Ventanas flotantes", "Todas se abren sueltas"], rightIsTrue: true },
                                        { lvl: "30", cat: "HYPRLAND", key: "luaDispatch", l: ["Config en Lua", "Hyprland 0.55+"], r: ["Config clásica", "hyprland.conf"], rightIsTrue: false },
                                        { lvl: "25", cat: "MODO", key: "autoDire", l: ["Cambio manual", "R del HUD o Super+Tab"], r: ["Dire al jugar", "Al abrir Steam o un juego"], rightIsTrue: true },
                                        { lvl: "20", cat: "AVISOS", key: "quietDire", l: ["Avisos siempre", "Popups en los dos modos"], r: ["Silencio en Dire", "Solo críticos jugando"], rightIsTrue: true },
                                        { lvl: "15", cat: "HUD", key: "hudHover", l: ["Al bajar el ratón", "Borde inferior"], r: ["Con un atajo", "duran ipc hud"], rightIsTrue: false },
                                        { lvl: "10", cat: "RELOJ", key: "clock24", l: ["24 horas", "20:05"], r: ["12 horas", "8:05 PM"], rightIsTrue: false }
                                    ]
                                    Row {
                                        id: level
                                        required property var modelData
                                        readonly property bool value: Settings.data[modelData.key]
                                        readonly property bool rightOn: value === modelData.rightIsTrue
                                        spacing: 16
                                        Talent {
                                            title: level.modelData.l[0]; desc: level.modelData.l[1]
                                            on: !level.rightOn
                                            onPicked: Settings.set(level.modelData.key, !level.modelData.rightIsTrue)
                                        }
                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 58; height: 58; radius: 29
                                            border.width: 2
                                            border.color: Theme.accentLight
                                            gradient: Gradient {
                                                GradientStop { position: 0; color: Theme.dialTop }
                                                GradientStop { position: 1; color: Theme.dialBot }
                                            }
                                            Column {
                                                anchors.centerIn: parent
                                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: level.modelData.lvl; color: Theme.text; font.pixelSize: 18; font.bold: true }
                                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: level.modelData.cat; color: Theme.accentLight; font.pixelSize: 7; font.bold: true; font.letterSpacing: 1 }
                                            }
                                        }
                                        Talent {
                                            rightSide: true
                                            title: level.modelData.r[0]; desc: level.modelData.r[1]
                                            on: level.rightOn
                                            onPicked: Settings.set(level.modelData.key, level.modelData.rightIsTrue)
                                        }
                                    }
                                }
                            }
                        }

                        // FONDO
                        GridView {
                            anchors.fill: parent
                            visible: win.page === "wallpaper"
                            clip: true
                            cellWidth: width / 3
                            cellHeight: 120
                            model: Wallpapers.list
                            delegate: Item {
                                required property var modelData
                                width: GridView.view.cellWidth
                                height: 120
                                readonly property bool on: modelData.path === Wallpapers.current
                                Rectangle {
                                    anchors { fill: parent; margins: 4 }
                                    color: "#050607"
                                    border.width: parent.on ? 2 : 1
                                    border.color: parent.on ? Theme.accentLight : "#050607"
                                    clip: true
                                    Image {
                                        anchors { fill: parent; margins: parent.border.width }
                                        source: "file://" + modelData.path
                                        sourceSize.width: 400
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                    }
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        width: parent.width; height: 4
                                        readonly property string m: Wallpapers.modeOf(modelData)
                                        color: m === "radiant" ? Theme.positive : m === "dire" ? "#e0583a" : Theme.textMute
                                    }
                                    Text { x: 6; y: 4; text: modelData.num; color: Theme.text; font.pixelSize: 13; font.bold: true; style: Text.Outline; styleColor: "black" }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Wallpapers.apply(modelData) }
                                }
                            }
                        }

                        // TEMA
                        Row {
                            anchors.centerIn: parent
                            visible: win.page === "theme"
                            spacing: 20
                            Repeater {
                                model: [["radiant", "RADIANT", "modo general", "#c9a45c", "#8fc27f"], ["dire", "DIRE", "modo juego", "#e0583a", "#ff8a5c"]]
                                Rectangle {
                                    required property var modelData
                                    readonly property bool on: ShellState.mode === modelData[0]
                                    width: 220; height: 260
                                    color: "#050607"
                                    border.width: on ? 2 : 1
                                    border.color: on ? Theme.accentLight : Theme.edge
                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 10
                                        Row {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            spacing: 6
                                            Rectangle { width: 50; height: 90; color: modelData[3] }
                                            Rectangle { width: 50; height: 90; color: modelData[4] }
                                        }
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData[1]; color: Theme.text; font.pixelSize: 20; font.bold: true; font.letterSpacing: 2 }
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData[2]; color: Theme.textMute; font.pixelSize: 12 }
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ShellState.mode = modelData[0] }
                                }
                            }
                        }

                        // AVATAR
                        GridView {
                            anchors.fill: parent
                            visible: win.page === "avatar"
                            clip: true
                            cellWidth: width / 4
                            cellHeight: cellWidth
                            model: win.avatars
                            delegate: Item {
                                required property string modelData
                                width: GridView.view.cellWidth
                                height: width
                                Rectangle {
                                    anchors { fill: parent; margins: 4 }
                                    color: "#050607"
                                    border.width: 1
                                    border.color: avArea.containsMouse ? Theme.accentLight : "#050607"
                                    clip: true
                                    Image {
                                        anchors { fill: parent; margins: 1 }
                                        source: "file://" + modelData
                                        sourceSize.width: 200
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                    }
                                    MouseArea { id: avArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Settings.setFace(modelData) }
                                }
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: win.avatars.length === 0
                                width: parent.width - 40
                                wrapMode: Text.WordWrap
                                horizontalAlignment: Text.AlignHCenter
                                text: "No hay imágenes. Pon tu foto en ~/Pictures/Avatars"
                                color: Theme.textMute
                                font.pixelSize: 14
                            }
                        }

                        // TERMINAL
                        Column {
                            anchors.fill: parent
                            visible: win.page === "terminal"
                            spacing: 6
                            Repeater {
                                model: win.terminals
                                Rectangle {
                                    required property string modelData
                                    readonly property bool on: ShellState.terminal === modelData
                                    width: parent.width
                                    height: 46
                                    color: on ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2) : Qt.rgba(0, 0, 0, 0.35)
                                    border.width: 1
                                    border.color: on ? Theme.accentLight : Theme.edgeDark
                                    Text { x: 14; anchors.verticalCenter: parent.verticalCenter; text: modelData; color: Theme.text; font.family: "monospace"; font.pixelSize: 15; font.bold: true }
                                    Text { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; visible: parent.on; text: "EQUIPADA"; color: Theme.accentLight; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1.6 }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ShellState.terminal = modelData }
                                }
                            }
                        }

                        // APPS
                        Item {
                            anchors.fill: parent
                            visible: win.page === "apps"
                            Rectangle {
                                id: appSearch
                                width: parent.width
                                height: 30
                                color: Theme.slot
                                border.width: 1
                                border.color: appInput.activeFocus ? Theme.accent : Theme.edge
                                TextInput {
                                    id: appInput
                                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Theme.text
                                    font.pixelSize: 14
                                    clip: true
                                    onTextChanged: win.appQuery = text.toLowerCase()
                                    Keys.onEscapePressed: win.close()
                                    Text { anchors.verticalCenter: parent.verticalCenter; visible: appInput.text === ""; text: "Buscar app…"; color: Theme.textMute; font.pixelSize: 14 }
                                }
                            }
                            ListView {
                                anchors { top: appSearch.bottom; topMargin: 8; left: parent.left; right: parent.right; bottom: parent.bottom }
                                clip: true
                                spacing: 3
                                model: Apps.all.filter(e => win.appQuery === "" || e.name.toLowerCase().includes(win.appQuery))
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool pinned: Apps.isPinned(modelData)
                                    width: ListView.view.width
                                    height: 40
                                    color: pinned ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : Qt.rgba(0, 0, 0, 0.35)
                                    border.width: 1
                                    border.color: pinned ? Theme.accent : Theme.edgeDark
                                    Row {
                                        x: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 10
                                        Image { width: 24; height: 24; source: Apps.icon(modelData); sourceSize: Qt.size(24, 24) }
                                        Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.name; color: Theme.text; font.pixelSize: 14 }
                                    }
                                    Text { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; text: parent.pinned ? "◆ FIJADA" : "FIJAR"; color: parent.pinned ? Theme.accentLight : Theme.textMute; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1.4 }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Apps.togglePin(modelData) }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
