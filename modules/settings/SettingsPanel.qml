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
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    readonly property string home: Quickshell.env("HOME")
    property string page: "talents"     // talents | keys | sys | wallpaper | theme | avatar | terminal | cursor | apps
    property string appQuery: ""
    property var avatars: []
    property var terminals: []
    property var cursorThemes: []

    // Atajos: acción que se está cambiando y modificadores marcados
    property string capturing: ""
    property var capMods: ["SUPER"]
    property string keyQuery: ""

    function startCapture(id) {
        capturing = id;
        capMods = ["SUPER"];
        keys.forceActiveFocus();
    }
    function toggleMod(m) {
        capMods = capMods.includes(m) ? capMods.filter(x => x !== m) : capMods.concat([m]);
    }
    // Nombre de la tecla como lo entiende Hyprland
    function keyName(e) {
        const k = e.key;
        if ((k >= Qt.Key_A && k <= Qt.Key_Z) || (k >= Qt.Key_0 && k <= Qt.Key_9))
            return String.fromCharCode(k);
        if (k >= Qt.Key_F1 && k <= Qt.Key_F12)
            return "F" + (k - Qt.Key_F1 + 1);
        const m = {};
        m[Qt.Key_Space] = "space";
        m[Qt.Key_Tab] = "Tab";
        m[Qt.Key_Return] = "Return";
        m[Qt.Key_Enter] = "Return";
        m[Qt.Key_Period] = "period";
        m[Qt.Key_Comma] = "comma";
        m[Qt.Key_Minus] = "minus";
        m[Qt.Key_Equal] = "equal";
        m[Qt.Key_Plus] = "plus";
        m[Qt.Key_Slash] = "slash";
        m[Qt.Key_Backslash] = "backslash";
        m[Qt.Key_Semicolon] = "semicolon";
        m[Qt.Key_Apostrophe] = "apostrophe";
        m[Qt.Key_BracketLeft] = "bracketleft";
        m[Qt.Key_BracketRight] = "bracketright";
        m[Qt.Key_Left] = "Left";
        m[Qt.Key_Right] = "Right";
        m[Qt.Key_Up] = "Up";
        m[Qt.Key_Down] = "Down";
        m[Qt.Key_Delete] = "Delete";
        m[Qt.Key_Insert] = "Insert";
        m[Qt.Key_Home] = "Home";
        m[Qt.Key_End] = "End";
        m[Qt.Key_PageUp] = "Page_Up";
        m[Qt.Key_PageDown] = "Page_Down";
        m[Qt.Key_Print] = "Print";
        return m[k] ?? "";
    }
    function capture(e) {
        const action = Keybinds.actions.find(a => a.id === capturing);
        if (e.key === Qt.Key_Escape) {
            capturing = "";
            return;
        }
        if (e.key === Qt.Key_Backspace) {          // quitar el atajo de ancient
            Keybinds.assign(action, "");
            capturing = "";
            return;
        }
        const name = keyName(e);
        if (name === "")
            return;                                 // solo modificadores: seguir esperando
        const mods = capMods.slice();
        if (e.modifiers & Qt.MetaModifier && !mods.includes("SUPER"))
            mods.push("SUPER");
        if (e.modifiers & Qt.ControlModifier && !mods.includes("CTRL"))
            mods.push("CTRL");
        if (e.modifiers & Qt.AltModifier && !mods.includes("ALT"))
            mods.push("ALT");
        if (e.modifiers & Qt.ShiftModifier && !mods.includes("SHIFT"))
            mods.push("SHIFT");
        const order = ["SUPER", "CTRL", "ALT", "SHIFT"];
        const combo = order.filter(m => mods.includes(m)).concat([name]).join(" + ");
        Keybinds.assign(action, combo);
        capturing = "";
    }

    onVisibleChanged: {
        if (!visible)
            return;
        page = "talents";
        capturing = "";
        Wallpapers.refresh();
        Keybinds.refresh();
        scan.running = true;
        Qt.callLater(() => keys.forceActiveFocus());
    }

    function close() {
        ShellState.settingsOpen = false;
    }

    // Avatares (~/Pictures y ~/Pictures/Avatars) y terminales instaladas
    Process {
        id: scan
        command: ["sh", "-c", "find \"$HOME/Pictures\" \"$HOME/Pictures/Avatars\" -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) ! -name 'wallpaper-dota-*' 2>/dev/null | sort -u | head -n 60; " + "echo '--'; for t in foot kitty alacritty wezterm ghostty konsole; do command -v $t >/dev/null && echo $t; done; " +
            // Temas de cursor: los que tienen carpeta cursors/
            "echo '--'; for d in /usr/share/icons \"$HOME/.local/share/icons\" \"$HOME/.icons\"; do for t in \"$d\"/*/; do " + "[ -d \"$t/cursors\" ] && basename \"$t\"; done; done 2>/dev/null | sort -u"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.split("--\n");
                win.avatars = (parts[0] || "").split("\n").filter(l => l !== "");
                win.terminals = (parts[1] || "").split("\n").filter(l => l !== "");
                win.cursorThemes = (parts[2] || "").split("\n").filter(l => l !== "" && l !== "default");
            }
        }
    }

    Item {
        id: keys
        focus: true
        Keys.onPressed: e => {
            if (win.capturing !== "") {
                win.capture(e);
                e.accepted = true;
            } else if (e.key === Qt.Key_Escape) {
                win.close();
                e.accepted = true;
            }
        }
    }

    // Fondo: clic fuera = cerrar
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        MouseArea {
            anchors.fill: parent
            onClicked: win.close()
        }
    }

    // ── Piezas ──
    component Section: Text {
        color: Theme.accentLight
        font.pixelSize: 12
        font.bold: true
        font.letterSpacing: 2.2
    }

    // Hueco equipado (abre su página a la derecha)
    component Slot: Rectangle {
        id: slot
        property string key
        property string value
        property string target
        default property alias art: artArea.data
        readonly property bool active: win.page === target
        height: 74
        color: "#050607"
        clip: true
        border.width: active ? 2 : 1
        border.color: active ? Theme.accentLight : (slotArea.containsMouse ? Theme.accent : "#050607")
        Item {
            id: artArea
            anchors.fill: parent
            anchors.margins: slot.border.width
        }
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 46
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "transparent"
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(0, 0, 0, 0.88)
                }
            }
            Column {
                x: 10
                anchors {
                    bottom: parent.bottom
                    bottomMargin: 6
                }
                Text {
                    text: slot.key
                    color: Theme.textMute
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 1.8
                }
                Text {
                    width: slot.width - 20
                    elide: Text.ElideRight
                    text: slot.value
                    color: Theme.text
                    font.pixelSize: 14
                    font.bold: true
                }
            }
        }
        MouseArea {
            id: slotArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: win.page = slot.target
        }
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
        Text {
            anchors.centerIn: parent
            text: mb.label
            color: mb.on ? Theme.text : Theme.textMute
            font.pixelSize: 12
            font.bold: true
            font.letterSpacing: 1.6
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: ShellState.mode = mb.mode
        }
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
            GradientStop {
                position: tal.rightSide ? 1 : 0
                color: tal.on ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.28) : Qt.rgba(0, 0, 0, 0.5)
            }
            GradientStop {
                position: tal.rightSide ? 0 : 1
                color: Qt.rgba(0, 0, 0, 0.5)
            }
        }
        Column {
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                right: parent.right
                leftMargin: 16
                rightMargin: 16
            }
            spacing: 2
            Text {
                width: parent.width
                horizontalAlignment: tal.rightSide ? Text.AlignLeft : Text.AlignRight
                text: tal.title
                color: tal.on ? Theme.text : Theme.textMute
                elide: Text.ElideRight
                font.pixelSize: 14
                font.bold: true
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
        MouseArea {
            id: talArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tal.picked()
        }
    }

    // ── Ventana ──
    Rectangle {
        anchors.centerIn: parent
        width: 1160
        height: 720
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
        MouseArea {
            anchors.fill: parent
        }

        TexturePanel {
            anchors {
                fill: parent
                margins: 5
            }
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
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Theme.edge
                }
                Row {
                    x: 18
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 18
                    Text {
                        text: "AJUSTES"
                        color: Theme.text
                        font.pixelSize: 20
                        font.bold: true
                        font.letterSpacing: 2
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: ({
                                talents: "ÁRBOL DE TALENTOS · COMPORTAMIENTO",
                                keys: "ATAJOS · TECLAS DE ANCIENT",
                                sys: "SISTEMA · ESTE EQUIPO"
                            })[win.page] ?? "LOADOUT · APARIENCIA"
                        color: Theme.accentLight
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 2.4
                    }
                }
                Text {
                    anchors {
                        right: parent.right
                        rightMargin: 18
                        verticalCenter: parent.verticalCenter
                    }
                    text: "✕"
                    color: Theme.textMute
                    font.pixelSize: 20
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.close()
                    }
                }
            }

            Row {
                anchors {
                    top: head.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: 18
                }
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
                        Text {
                            anchors.centerIn: parent
                            text: (Quickshell.env("USER") || "").toUpperCase()
                            color: Theme.text
                            font.pixelSize: 15
                            font.bold: true
                            font.letterSpacing: 2
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: parent.height - 30 - 30 - tabsCol.height - 30
                        border.width: 2
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
                        Image {
                            id: faceImg
                            anchors {
                                fill: parent
                                margins: 2
                            }
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
                            font.pixelSize: 80
                            font.bold: true
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 6
                        ModeButton {
                            width: (parent.width - 6) / 2
                            mode: "radiant"
                            label: "RADIANT"
                            tint: Theme.positive
                        }
                        ModeButton {
                            width: (parent.width - 6) / 2
                            mode: "dire"
                            label: "DIRE"
                            tint: "#e0583a"
                        }
                    }

                    // Pestañas: talentos, atajos, sistema
                    Column {
                        id: tabsCol
                        width: parent.width
                        spacing: 4
                        PageTab {
                            width: parent.width
                            label: "TALENTOS"
                            sub: "comportamiento"
                            active: win.page === "talents"
                            onClicked: win.page = "talents"
                        }
                        PageTab {
                            width: parent.width
                            label: "ATAJOS"
                            sub: "teclas"
                            active: win.page === "keys"
                            onClicked: win.page = "keys"
                        }
                        PageTab {
                            width: parent.width
                            label: "SISTEMA"
                            sub: "energía"
                            active: win.page === "sys"
                            onClicked: win.page = "sys"
                        }
                    }
                }

                // ─ Huecos equipados ─
                Column {
                    width: 260
                    height: parent.height
                    spacing: 10

                    Section {
                        text: "EQUIPADO"
                    }
                    Grid {
                        width: parent.width
                        columns: 3
                        spacing: 8

                        Slot {
                            width: (parent.width - 16) / 3
                            key: "FONDO"
                            target: "wallpaper"
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
                            width: (parent.width - 16) / 3
                            key: "TEMA"
                            target: "theme"
                            value: ShellState.mode === "dire" ? "Dire" : "Radiant"
                            Row {
                                anchors.fill: parent
                                Rectangle {
                                    width: parent.width / 3
                                    height: parent.height
                                    color: Theme.accent
                                }
                                Rectangle {
                                    width: parent.width / 3
                                    height: parent.height
                                    color: Theme.frameTop
                                }
                                TexturePanel {
                                    width: parent.width / 3
                                    height: parent.height
                                }
                            }
                        }
                        Slot {
                            width: (parent.width - 16) / 3
                            key: "AVATAR"
                            target: "avatar"
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
                            width: (parent.width - 16) / 3
                            key: "TERMINAL"
                            target: "terminal"
                            value: ShellState.terminal
                            Rectangle {
                                anchors.fill: parent
                                color: "#0a0c0e"
                                Text {
                                    x: 10
                                    y: 10
                                    text: "❯ _"
                                    color: Theme.positive
                                    font.family: "monospace"
                                    font.pixelSize: 16
                                    font.bold: true
                                }
                            }
                        }
                        Slot {
                            width: (parent.width - 16) / 3
                            key: "CURSOR"
                            target: "cursor"
                            value: Settings.data.cursorTheme || "—"
                            Text {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: -12
                                text: "➚"
                                color: Theme.accentLight
                                font.pixelSize: 24
                            }
                        }
                    }

                    Section {
                        text: "APPS FIJADAS"
                        topPadding: 8
                    }
                    Flow {
                        width: parent.width
                        spacing: 4
                        Repeater {
                            model: ShellState.pinnedApps
                            Rectangle {
                                required property string modelData
                                readonly property var entry: Apps.byId(modelData)
                                width: 56
                                height: 44
                                border.width: 1
                                border.color: "#050607"
                                gradient: Gradient {
                                    GradientStop {
                                        position: 0
                                        color: Apps.color(entry)
                                    }
                                    GradientStop {
                                        position: 1
                                        color: "#0a0c0e"
                                    }
                                }
                                Image {
                                    anchors.centerIn: parent
                                    width: 24
                                    height: 24
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
                            width: 56
                            height: 44
                            color: Qt.rgba(0, 0, 0, 0.4)
                            border.width: 1
                            border.color: win.page === "apps" ? Theme.accentLight : Theme.edge
                            Text {
                                anchors.centerIn: parent
                                text: "+"
                                color: Theme.textMute
                                font.pixelSize: 22
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.page = "apps"
                            }
                        }
                    }
                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "Clic derecho en una app para quitarla"
                        color: Theme.textMute
                        font.pixelSize: 12
                    }
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
                            GradientStop {
                                position: 0
                                color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22)
                            }
                            GradientStop {
                                position: 1
                                color: "transparent"
                            }
                        }
                        Text {
                            x: 14
                            anchors.verticalCenter: parent.verticalCenter
                            text: ({
                                    talents: "TALENTOS",
                                    keys: "ATAJOS",
                                    sys: "SISTEMA",
                                    wallpaper: "FONDO",
                                    theme: "TEMA",
                                    avatar: "AVATAR",
                                    terminal: "TERMINAL",
                                    cursor: "CURSOR",
                                    apps: "APPS FIJADAS"
                                })[win.page]
                            color: Theme.accentLight
                            font.pixelSize: 13
                            font.bold: true
                            font.letterSpacing: 2
                        }
                        Text {
                            anchors {
                                right: parent.right
                                rightMargin: 14
                                verticalCenter: parent.verticalCenter
                            }
                            text: ({
                                    talents: "elige un lado en cada nivel",
                                    keys: "los que cambies aquí valen solo con ancient",
                                    sys: Power.hasProfiles ? "perfil actual: " + Power.profile : "solo mientras ancient está activo",
                                    wallpaper: Wallpapers.list.length + " en ~/Pictures/Wallpapers",
                                    theme: "también con la R del HUD",
                                    avatar: "imágenes de ~/Pictures y ~/Pictures/Avatars",
                                    terminal: "la que abre Quick buy",
                                    cursor: "temas instalados · se aplica al momento",
                                    apps: "clic para fijar o quitar"
                                })[win.page]
                            color: Theme.textMute
                            font.pixelSize: 12
                        }
                    }

                    Item {
                        anchors {
                            top: pageHead.bottom
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                            margins: 14
                        }

                        // TALENTOS
                        Item {
                            anchors.fill: parent
                            visible: win.page === "talents"

                            Flickable {
                                id: tree
                                anchors.fill: parent
                                clip: true
                                contentWidth: width
                                contentHeight: levels.height + 20
                                boundsBehavior: Flickable.StopAtBounds

                                Rectangle {                      // tronco
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y: 10
                                    width: 4
                                    height: levels.height
                                    gradient: Gradient {
                                        GradientStop {
                                            position: 0
                                            color: Theme.accentLight
                                        }
                                        GradientStop {
                                            position: 1
                                            color: Qt.darker(Theme.accent, 1.8)
                                        }
                                    }
                                }

                                Column {
                                    id: levels
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y: 10
                                    spacing: 12
                                    Repeater {
                                        model: [
                                            {
                                                lvl: "65",
                                                cat: "SONIDOS",
                                                key: "sounds",
                                                l: ["Sonidos de ancient", "Bloqueo, avisos y modo"],
                                                r: ["Ninguno", "Silencio total"],
                                                rightIsTrue: false
                                            },
                                            {
                                                lvl: "60",
                                                cat: "UPDATES",
                                                key: "autoUpdates",
                                                l: ["Cada 30 minutos", "Cuenta las actualizaciones solo"],
                                                r: ["Solo a mano", "Clic en el oro de la tienda"],
                                                rightIsTrue: false
                                            },
                                            {
                                                lvl: "55",
                                                cat: "POPUPS",
                                                key: "notifBottom",
                                                l: ["Arriba a la derecha", "Debajo de la barra"],
                                                r: ["Abajo a la derecha", "Junto a la tienda"],
                                                rightIsTrue: true
                                            },
                                            {
                                                lvl: "50",
                                                cat: "BLOQUEO",
                                                key: "lockOnSuspend",
                                                l: ["Al suspender", "Pide contraseña al volver"],
                                                r: ["Nunca", "Vuelve sin contraseña"],
                                                rightIsTrue: false
                                            },
                                            {
                                                lvl: "45",
                                                cat: "MINIMIZAR",
                                                key: "minimizeBackpack",
                                                l: ["A la mochila", "Inventario del HUD"],
                                                r: ["Escritorio especial", "special:special (Super+S)"],
                                                rightIsTrue: false
                                            },
                                            {
                                                lvl: "40",
                                                cat: "LISTA",
                                                key: "windowListStart",
                                                l: ["Abierta al iniciar", "Lista de ventanas visible"],
                                                r: ["Cerrada", "Se abre con ☰"],
                                                rightIsTrue: false
                                            },
                                            {
                                                lvl: "35",
                                                cat: "VENTANAS",
                                                key: "floating",
                                                l: ["Mosaico automático", "Hyprland coloca las ventanas"],
                                                r: ["Ventanas flotantes", "Todas se abren sueltas"],
                                                rightIsTrue: true
                                            },
                                            {
                                                lvl: "30",
                                                cat: "HYPRLAND",
                                                key: "luaDispatch",
                                                l: ["Config en Lua", "Hyprland 0.55+"],
                                                r: ["Config clásica", "hyprland.conf"],
                                                rightIsTrue: false
                                            },
                                            {
                                                lvl: "25",
                                                cat: "MODO",
                                                key: "autoDire",
                                                l: ["Cambio manual", "R del HUD o Super+Tab"],
                                                r: ["Dire al jugar", "Al abrir Steam o un juego"],
                                                rightIsTrue: true
                                            },
                                            {
                                                lvl: "20",
                                                cat: "AVISOS",
                                                key: "quietDire",
                                                l: ["Avisos siempre", "Popups en los dos modos"],
                                                r: ["Silencio en Dire", "Solo críticos jugando"],
                                                rightIsTrue: true
                                            },
                                            {
                                                lvl: "15",
                                                cat: "HUD",
                                                key: "hudHover",
                                                l: ["Al bajar el ratón", "Borde inferior"],
                                                r: ["Con un atajo", "duran ipc hud"],
                                                rightIsTrue: false
                                            },
                                            {
                                                lvl: "10",
                                                cat: "RELOJ",
                                                key: "clock24",
                                                l: ["24 horas", "20:05"],
                                                r: ["12 horas", "8:05 PM"],
                                                rightIsTrue: false
                                            }
                                        ]
                                        Row {
                                            id: level
                                            required property var modelData
                                            readonly property bool value: Settings.data[modelData.key]
                                            readonly property bool rightOn: value === modelData.rightIsTrue
                                            spacing: 16
                                            Talent {
                                                title: level.modelData.l[0]
                                                desc: level.modelData.l[1]
                                                on: !level.rightOn
                                                onPicked: Settings.set(level.modelData.key, !level.modelData.rightIsTrue)
                                            }
                                            Rectangle {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: 58
                                                height: 58
                                                radius: 29
                                                border.width: 2
                                                border.color: Theme.accentLight
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
                                                Column {
                                                    anchors.centerIn: parent
                                                    Text {
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        text: level.modelData.lvl
                                                        color: Theme.text
                                                        font.pixelSize: 18
                                                        font.bold: true
                                                    }
                                                    Text {
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        text: level.modelData.cat
                                                        color: Theme.accentLight
                                                        font.pixelSize: 7
                                                        font.bold: true
                                                        font.letterSpacing: 1
                                                    }
                                                }
                                            }
                                            Talent {
                                                rightSide: true
                                                title: level.modelData.r[0]
                                                desc: level.modelData.r[1]
                                                on: level.rightOn
                                                onPicked: Settings.set(level.modelData.key, level.modelData.rightIsTrue)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ATAJOS
                        Item {
                            anchors.fill: parent
                            visible: win.page === "keys"

                            Rectangle {
                                id: keySearch
                                width: parent.width
                                height: 30
                                color: Theme.slot
                                border.width: 1
                                border.color: keyInput.activeFocus ? Theme.accent : Theme.edge
                                TextInput {
                                    id: keyInput
                                    anchors {
                                        fill: parent
                                        leftMargin: 10
                                        rightMargin: 10
                                    }
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Theme.text
                                    font.pixelSize: 14
                                    clip: true
                                    onTextChanged: win.keyQuery = text.toLowerCase()
                                    Keys.onEscapePressed: win.close()
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: keyInput.text === ""
                                        text: "Buscar acción o tecla…"
                                        color: Theme.textMute
                                        font.pixelSize: 14
                                    }
                                }
                            }

                            Flickable {
                                anchors {
                                    top: keySearch.bottom
                                    topMargin: 8
                                    left: parent.left
                                    right: parent.right
                                    bottom: keyFoot.top
                                    bottomMargin: 8
                                }
                                clip: true
                                contentWidth: width
                                contentHeight: keyList.height
                                boundsBehavior: Flickable.StopAtBounds

                                Column {
                                    id: keyList
                                    width: parent.width
                                    spacing: 4
                                    Repeater {
                                        model: Keybinds.actions.filter(a => win.keyQuery === "" || a.name.toLowerCase().includes(win.keyQuery) || Keybinds.combosFor(a).some(c => c.combo.toLowerCase().includes(win.keyQuery)))
                                        Column {
                                            id: krow
                                            required property var modelData
                                            required property int index
                                            readonly property var all: Keybinds.actions.filter(a => win.keyQuery === "" || a.name.toLowerCase().includes(win.keyQuery) || Keybinds.combosFor(a).some(c => c.combo.toLowerCase().includes(win.keyQuery)))
                                            readonly property bool firstOfGroup: index === 0 || all[index - 1].group !== modelData.group
                                            readonly property bool editing: win.capturing === modelData.id
                                            readonly property var combos: Keybinds.combosFor(modelData)
                                            readonly property var clash: Keybinds.conflicts(Settings.data.keybinds[modelData.id] || "", modelData)
                                            width: keyList.width
                                            spacing: 4

                                            Text {
                                                visible: krow.firstOfGroup
                                                topPadding: krow.index === 0 ? 0 : 8
                                                text: krow.modelData.group
                                                color: Theme.accentLight
                                                font.pixelSize: 11
                                                font.bold: true
                                                font.letterSpacing: 2.2
                                            }

                                            Rectangle {
                                                width: parent.width
                                                height: 46
                                                color: krow.editing ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2) : Qt.rgba(0, 0, 0, 0.35)
                                                border.width: 1
                                                border.color: krow.editing ? Theme.accentLight : (krow.clash.length ? Theme.danger : Theme.edgeDark)

                                                Column {
                                                    id: kname
                                                    x: 12
                                                    width: 140
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    Text {
                                                        width: parent.width
                                                        elide: Text.ElideRight
                                                        text: krow.modelData.name
                                                        color: Theme.text
                                                        font.pixelSize: 14
                                                        font.bold: true
                                                    }
                                                    Text {
                                                        width: parent.width
                                                        elide: Text.ElideRight
                                                        text: krow.modelData.desc
                                                        color: Theme.textMute
                                                        font.pixelSize: 11
                                                    }
                                                }

                                                // Normal: teclas actuales
                                                Row {
                                                    visible: !krow.editing
                                                    anchors {
                                                        left: kname.right
                                                        leftMargin: 10
                                                        verticalCenter: parent.verticalCenter
                                                    }
                                                    spacing: 8
                                                    Repeater {
                                                        model: krow.combos.slice(0, 2)
                                                        Row {
                                                            required property var modelData
                                                            spacing: 5
                                                            KeyChips {
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                combo: modelData.combo
                                                                edge: modelData.src === "ANCIENT" ? Theme.accent : Theme.edge
                                                            }
                                                            Rectangle {
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                width: srcText.implicitWidth + 10
                                                                height: 16
                                                                color: "transparent"
                                                                border.width: 1
                                                                border.color: srcText.color
                                                                Text {
                                                                    id: srcText
                                                                    anchors.centerIn: parent
                                                                    text: modelData.src
                                                                    color: modelData.src === "ANCIENT" ? Theme.accent : Theme.moon
                                                                    font.pixelSize: 8
                                                                    font.bold: true
                                                                    font.letterSpacing: 1.2
                                                                }
                                                            }
                                                        }
                                                    }
                                                    Text {
                                                        visible: krow.combos.length === 0
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: "sin atajo"
                                                        color: Theme.label
                                                        font.pixelSize: 12
                                                    }
                                                    Text {
                                                        visible: krow.clash.length > 0
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: "⚠ también: " + krow.clash.join(", ")
                                                        color: "#e07a6a"
                                                        font.pixelSize: 11
                                                        elide: Text.ElideRight
                                                        width: 150
                                                    }
                                                }

                                                // Cambiando: modificadores + tecla
                                                Row {
                                                    visible: krow.editing
                                                    anchors {
                                                        left: kname.right
                                                        leftMargin: 10
                                                        verticalCenter: parent.verticalCenter
                                                    }
                                                    spacing: 4
                                                    Repeater {
                                                        model: ["SUPER", "CTRL", "ALT", "SHIFT"]
                                                        Rectangle {
                                                            required property string modelData
                                                            readonly property bool on: win.capMods.includes(modelData)
                                                            width: modText.implicitWidth + 14
                                                            height: 24
                                                            color: on ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35) : "#0b0d10"
                                                            border.width: 1
                                                            border.color: on ? Theme.accentLight : Theme.edge
                                                            Text {
                                                                id: modText
                                                                anchors.centerIn: parent
                                                                text: modelData
                                                                color: parent.on ? Theme.text : Theme.textMute
                                                                font.family: "monospace"
                                                                font.pixelSize: 11
                                                                font.bold: true
                                                            }
                                                            MouseArea {
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                    win.toggleMod(modelData);
                                                                    keys.forceActiveFocus();
                                                                }
                                                            }
                                                        }
                                                    }
                                                    Text {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        leftPadding: 6
                                                        text: "+ pulsa la tecla…"
                                                        color: Theme.text
                                                        font.pixelSize: 13
                                                        font.bold: true
                                                    }
                                                }

                                                Rectangle {
                                                    anchors {
                                                        right: parent.right
                                                        rightMargin: 10
                                                        verticalCenter: parent.verticalCenter
                                                    }
                                                    width: editText.implicitWidth + 20
                                                    height: 26
                                                    color: Qt.rgba(0, 0, 0, 0.4)
                                                    border.width: 1
                                                    border.color: editArea.containsMouse ? Theme.accentLight : Theme.edge
                                                    Text {
                                                        id: editText
                                                        anchors.centerIn: parent
                                                        text: krow.editing ? "ESC" : "CAMBIAR"
                                                        color: Theme.textSoft
                                                        font.pixelSize: 10
                                                        font.bold: true
                                                        font.letterSpacing: 1.4
                                                    }
                                                    MouseArea {
                                                        id: editArea
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: krow.editing ? win.capturing = "" : win.startCapture(krow.modelData.id)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Leyenda y restablecer
                            Row {
                                id: keyFoot
                                anchors {
                                    left: parent.left
                                    bottom: parent.bottom
                                }
                                spacing: 8
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "ANCIENT"
                                    color: Theme.accent
                                    font.pixelSize: 9
                                    font.bold: true
                                    font.letterSpacing: 1.2
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "cambiado aquí"
                                    color: Theme.textMute
                                    font.pixelSize: 11
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    leftPadding: 8
                                    text: "DOTFILES"
                                    color: Theme.moon
                                    font.pixelSize: 9
                                    font.bold: true
                                    font.letterSpacing: 1.2
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "de tu keybinds.lua"
                                    color: Theme.textMute
                                    font.pixelSize: 11
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    leftPadding: 8
                                    text: "· Retroceso quita"
                                    color: Theme.textMute
                                    font.pixelSize: 11
                                }
                            }
                            Rectangle {
                                anchors {
                                    right: parent.right
                                    bottom: parent.bottom
                                }
                                width: resetText.implicitWidth + 20
                                height: 26
                                color: Qt.rgba(0, 0, 0, 0.4)
                                border.width: 1
                                border.color: resetArea.containsMouse ? Theme.accentLight : Theme.edge
                                Text {
                                    id: resetText
                                    anchors.centerIn: parent
                                    text: "RESTABLECER"
                                    color: Theme.textSoft
                                    font.pixelSize: 10
                                    font.bold: true
                                    font.letterSpacing: 1.4
                                }
                                MouseArea {
                                    id: resetArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Keybinds.resetAll()
                                }
                            }
                        }

                        // SISTEMA
                        Flickable {
                            anchors.fill: parent
                            visible: win.page === "sys"
                            clip: true
                            contentWidth: width
                            contentHeight: sysCol.height
                            boundsBehavior: Flickable.StopAtBounds

                            Column {
                                id: sysCol
                                width: parent.width
                                spacing: 2

                                Section {
                                    text: "ENERGÍA"
                                    bottomPadding: 4
                                }
                                OptionRow {
                                    width: sysCol.width
                                    label: "Bloquear"
                                    hint: "sin tocar el equipo"
                                    value: Settings.data.idleLock
                                    options: [
                                        {
                                            value: 0,
                                            text: "NUNCA"
                                        },
                                        {
                                            value: 2,
                                            text: "2 min"
                                        },
                                        {
                                            value: 5,
                                            text: "5 min"
                                        },
                                        {
                                            value: 10,
                                            text: "10 min"
                                        },
                                        {
                                            value: 15,
                                            text: "15 min"
                                        },
                                        {
                                            value: 30,
                                            text: "30 min"
                                        }
                                    ]
                                    onPicked: v => Settings.set("idleLock", v)
                                }
                                OptionRow {
                                    width: sysCol.width
                                    label: "Apagar la pantalla"
                                    value: Settings.data.idleDpms
                                    options: [
                                        {
                                            value: 0,
                                            text: "NUNCA"
                                        },
                                        {
                                            value: 5,
                                            text: "5 min"
                                        },
                                        {
                                            value: 10,
                                            text: "10 min"
                                        },
                                        {
                                            value: 15,
                                            text: "15 min"
                                        },
                                        {
                                            value: 30,
                                            text: "30 min"
                                        }
                                    ]
                                    onPicked: v => Settings.set("idleDpms", v)
                                }
                                OptionRow {
                                    width: sysCol.width
                                    label: "Suspender"
                                    value: Settings.data.idleSuspend
                                    options: [
                                        {
                                            value: 0,
                                            text: "NUNCA"
                                        },
                                        {
                                            value: 15,
                                            text: "15 min"
                                        },
                                        {
                                            value: 30,
                                            text: "30 min"
                                        },
                                        {
                                            value: 60,
                                            text: "1 h"
                                        }
                                    ]
                                    onPicked: v => Settings.set("idleSuspend", v)
                                }

                                Section {
                                    text: "PERFIL DE ENERGÍA"
                                    topPadding: 14
                                    bottomPadding: 4
                                }
                                Text {
                                    visible: !Power.hasProfiles
                                    width: sysCol.width
                                    wrapMode: Text.WordWrap
                                    text: "power-profiles-daemon no está activo: sudo systemctl enable --now power-profiles-daemon"
                                    color: Theme.textMute
                                    font.pixelSize: 12
                                }
                                OptionRow {
                                    visible: Power.hasProfiles
                                    width: sysCol.width
                                    label: "Perfil"
                                    hint: "en modo Radiant"
                                    value: Settings.data.powerProfile
                                    options: [
                                        {
                                            value: "power-saver",
                                            text: "AHORRO"
                                        },
                                        {
                                            value: "balanced",
                                            text: "EQUILIBRADO"
                                        },
                                        {
                                            value: "performance",
                                            text: "RENDIMIENTO"
                                        }
                                    ]
                                    onPicked: v => Settings.set("powerProfile", v)
                                }
                                OptionRow {
                                    visible: Power.hasProfiles
                                    width: sysCol.width
                                    label: "En modo Dire"
                                    hint: "al jugar"
                                    value: Settings.data.direPerformance
                                    options: [
                                        {
                                            value: true,
                                            text: "RENDIMIENTO"
                                        },
                                        {
                                            value: false,
                                            text: "EL MISMO"
                                        }
                                    ]
                                    onPicked: v => Settings.set("direPerformance", v)
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
                                    anchors {
                                        fill: parent
                                        margins: 4
                                    }
                                    color: "#050607"
                                    border.width: parent.on ? 2 : 1
                                    border.color: parent.on ? Theme.accentLight : "#050607"
                                    clip: true
                                    Image {
                                        anchors {
                                            fill: parent
                                            margins: parent.border.width
                                        }
                                        source: "file://" + modelData.path
                                        sourceSize.width: 400
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                    }
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        width: parent.width
                                        height: 4
                                        readonly property string m: Wallpapers.modeOf(modelData)
                                        color: m === "radiant" ? Theme.positive : m === "dire" ? "#e0583a" : Theme.textMute
                                    }
                                    Text {
                                        x: 6
                                        y: 4
                                        text: modelData.num
                                        color: Theme.text
                                        font.pixelSize: 13
                                        font.bold: true
                                        style: Text.Outline
                                        styleColor: "black"
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Wallpapers.apply(modelData)
                                    }
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
                                    width: 220
                                    height: 260
                                    color: "#050607"
                                    border.width: on ? 2 : 1
                                    border.color: on ? Theme.accentLight : Theme.edge
                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 10
                                        Row {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            spacing: 6
                                            Rectangle {
                                                width: 50
                                                height: 90
                                                color: modelData[3]
                                            }
                                            Rectangle {
                                                width: 50
                                                height: 90
                                                color: modelData[4]
                                            }
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: modelData[1]
                                            color: Theme.text
                                            font.pixelSize: 20
                                            font.bold: true
                                            font.letterSpacing: 2
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: modelData[2]
                                            color: Theme.textMute
                                            font.pixelSize: 12
                                        }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ShellState.mode = modelData[0]
                                    }
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
                                    anchors {
                                        fill: parent
                                        margins: 4
                                    }
                                    color: "#050607"
                                    border.width: 1
                                    border.color: avArea.containsMouse ? Theme.accentLight : "#050607"
                                    clip: true
                                    Image {
                                        anchors {
                                            fill: parent
                                            margins: 1
                                        }
                                        source: "file://" + modelData
                                        sourceSize.width: 200
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                    }
                                    MouseArea {
                                        id: avArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Settings.setFace(modelData)
                                    }
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
                                    Text {
                                        x: 14
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData
                                        color: Theme.text
                                        font.family: "monospace"
                                        font.pixelSize: 15
                                        font.bold: true
                                    }
                                    Text {
                                        anchors.right: parent.right
                                        anchors.rightMargin: 14
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: parent.on
                                        text: "EQUIPADA"
                                        color: Theme.accentLight
                                        font.pixelSize: 11
                                        font.bold: true
                                        font.letterSpacing: 1.6
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ShellState.terminal = modelData
                                    }
                                }
                            }
                        }

                        // CURSOR
                        Item {
                            anchors.fill: parent
                            visible: win.page === "cursor"

                            Row {
                                id: sizes
                                spacing: 6
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "TAMAÑO"
                                    color: Theme.textMute
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.letterSpacing: 1.6
                                    rightPadding: 6
                                }
                                Repeater {
                                    model: [24, 32, 48]
                                    Rectangle {
                                        required property int modelData
                                        readonly property bool on: Settings.data.cursorSize === modelData
                                        width: 56
                                        height: 30
                                        color: on ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25) : Qt.rgba(0, 0, 0, 0.4)
                                        border.width: 1
                                        border.color: on ? Theme.accentLight : Theme.edge
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData
                                            color: Theme.text
                                            font.family: "monospace"
                                            font.pixelSize: 13
                                            font.bold: true
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Settings.setCursor(Settings.data.cursorTheme, modelData)
                                        }
                                    }
                                }
                            }

                            ListView {
                                anchors {
                                    top: sizes.bottom
                                    topMargin: 10
                                    left: parent.left
                                    right: parent.right
                                    bottom: parent.bottom
                                }
                                clip: true
                                spacing: 4
                                model: win.cursorThemes
                                delegate: Rectangle {
                                    required property string modelData
                                    readonly property bool on: Settings.data.cursorTheme === modelData
                                    width: ListView.view.width
                                    height: 42
                                    color: on ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2) : Qt.rgba(0, 0, 0, 0.35)
                                    border.width: 1
                                    border.color: on ? Theme.accentLight : Theme.edgeDark
                                    Text {
                                        x: 14
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData
                                        color: Theme.text
                                        font.pixelSize: 14
                                        font.bold: true
                                    }
                                    Text {
                                        anchors.right: parent.right
                                        anchors.rightMargin: 14
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: parent.on
                                        text: "EQUIPADO"
                                        color: Theme.accentLight
                                        font.pixelSize: 11
                                        font.bold: true
                                        font.letterSpacing: 1.6
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Settings.setCursor(modelData, Settings.data.cursorSize)
                                    }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    visible: win.cursorThemes.length === 0
                                    text: "No hay temas de cursor instalados"
                                    color: Theme.textMute
                                    font.pixelSize: 14
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
                                    anchors {
                                        fill: parent
                                        leftMargin: 10
                                        rightMargin: 10
                                    }
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Theme.text
                                    font.pixelSize: 14
                                    clip: true
                                    onTextChanged: win.appQuery = text.toLowerCase()
                                    Keys.onEscapePressed: win.close()
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: appInput.text === ""
                                        text: "Buscar app…"
                                        color: Theme.textMute
                                        font.pixelSize: 14
                                    }
                                }
                            }
                            ListView {
                                anchors {
                                    top: appSearch.bottom
                                    topMargin: 8
                                    left: parent.left
                                    right: parent.right
                                    bottom: parent.bottom
                                }
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
                                        Image {
                                            width: 24
                                            height: 24
                                            source: Apps.icon(modelData)
                                            sourceSize: Qt.size(24, 24)
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.name
                                            color: Theme.text
                                            font.pixelSize: 14
                                        }
                                    }
                                    Text {
                                        anchors.right: parent.right
                                        anchors.rightMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: parent.pinned ? "◆ FIJADA" : "FIJAR"
                                        color: parent.pinned ? Theme.accentLight : Theme.textMute
                                        font.pixelSize: 11
                                        font.bold: true
                                        font.letterSpacing: 1.4
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Apps.togglePin(modelData)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
