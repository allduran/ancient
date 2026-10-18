import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Shapes
import "../../config"
import "../../services"

// Selector de fondos: galería de fin de partida de Dota
PanelWindow {
    id: picker
    visible: ShellState.wallpaperOpen
    screen: Quickshell.screens.find(s => Hyprland.focusedMonitor && s.name === Hyprland.focusedMonitor.name) ?? null

    WlrLayershell.namespace: "ancient-wallpapers"
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

    property int tab: 0                 // 0 todos · 1 radiant · 2 dire · 3 sin asignar
    property int sel: 0
    readonly property var tabs: ["TODOS", "RADIANT", "DIRE", "SIN ASIGNAR"]
    readonly property int bigW: Math.min(820, Math.round(width * 0.43))
    readonly property int cardH: Math.min(500, Math.round(height * 0.46))

    readonly property var items: Wallpapers.list.filter(w => {
        const m = Wallpapers.modeOf(w);
        return tab === 0 || (tab === 1 && m === "radiant") || (tab === 2 && m === "dire") || (tab === 3 && m === "");
    })
    readonly property var current: items[sel] ?? null

    onVisibleChanged: {
        if (!visible)
            return;
        tab = 0;
        Wallpapers.refresh();
        sel = Math.max(0, items.findIndex(w => w.path === Wallpapers.current));
        Qt.callLater(() => {
            strip.positionViewAtIndex(sel, ListView.Center);
            keys.forceActiveFocus();
        });
    }
    onItemsChanged: sel = Math.min(sel, Math.max(0, items.length - 1))

    function close() {
        ShellState.wallpaperOpen = false;
    }
    function move(d) {
        sel = Math.max(0, Math.min(items.length - 1, sel + d));
    }
    function applyCurrent() {
        if (!current)
            return;
        Wallpapers.apply(current);
        close();
    }
    function modeColor(m) {
        return m === "radiant" ? Theme.positive : m === "dire" ? "#e0583a" : Theme.textMute;
    }

    // ── Teclas ──
    Item {
        id: keys
        focus: true
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape)
                picker.close();
            else if (e.key === Qt.Key_Left)
                picker.move(-1);
            else if (e.key === Qt.Key_Right)
                picker.move(1);
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)
                picker.applyCurrent();
            else if (e.key === Qt.Key_Tab)
                picker.tab = (picker.tab + 1) % 4;
            else if (e.key === Qt.Key_R && picker.current)
                Wallpapers.assign(picker.current, "radiant");
            else if (e.key === Qt.Key_D && picker.current)
                Wallpapers.assign(picker.current, "dire");
            else
                return;
            e.accepted = true;
        }
    }

    // ── Fondo ──
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.05, 0.045, 0.08, 0.94)
        MouseArea {
            anchors.fill: parent
            onClicked: keys.forceActiveFocus()
        }
    }
    Rectangle {                         // brillo violeta arriba, como la pantalla de Dota
        anchors.horizontalCenter: parent.horizontalCenter
        y: -height / 2
        width: parent.width * 1.2
        height: parent.height * 0.9
        radius: width / 2
        opacity: 0.35
        gradient: Gradient {
            GradientStop { position: 0.5; color: "#5a3c8c" }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    component Key: Rectangle {
        property string label
        width: Math.max(18, keyText.implicitWidth + 8)
        height: 18
        color: "#0b0d10"
        border.width: 1
        border.color: Theme.edge
        Text {
            id: keyText
            anchors.centerIn: parent
            text: parent.label
            color: Theme.textSoft
            font.family: "monospace"; font.pixelSize: 10; font.bold: true
        }
    }

    // Pestañas
    Row {
        x: 80
        y: 56
        spacing: 18
        Repeater {
            model: picker.tabs
            Row {
                required property string modelData
                required property int index
                spacing: 18
                Text {
                    text: modelData
                    color: picker.tab === index ? Theme.text : Theme.textMute
                    font.pixelSize: 14; font.bold: true; font.letterSpacing: 2
                    Rectangle {
                        visible: picker.tab === index
                        anchors { left: parent.left; right: parent.right; top: parent.bottom; topMargin: 4 }
                        height: 2
                        color: Theme.accent
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: picker.tab = index
                    }
                }
                Text {
                    visible: index < picker.tabs.length - 1
                    text: "/"
                    color: Theme.label
                    font.pixelSize: 14
                }
            }
        }
    }

    Text {
        anchors { right: parent.right; rightMargin: 70; top: parent.top; topMargin: 50 }
        text: "✕"
        color: Theme.textMute
        font.pixelSize: 22
        MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: picker.close() }
    }

    // Marcador: fondos de Radiant · posición · fondos de Dire
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 96
        spacing: 30
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Wallpapers.count("radiant")
            color: Theme.positive
            font.pixelSize: 60; font.bold: true
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "FONDOS"
                color: Theme.textMute
                font.pixelSize: 12; font.bold: true; font.letterSpacing: 2.4
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: picker.items.length ? (picker.sel + 1) + " / " + picker.items.length : "0"
                color: Theme.text
                font.family: "monospace"; font.pixelSize: 24; font.bold: true
            }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Wallpapers.count("dire")
            color: "#e0583a"
            font.pixelSize: 60; font.bold: true
        }
    }

    Row {
        anchors { right: parent.right; rightMargin: 80 }
        y: 116
        spacing: 10
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 300
            height: 3
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: Theme.accent }
            }
        }
        Text {
            text: ShellState.mode === "dire" ? "Modo Dire" : "Modo Radiant"
            color: Theme.accentLight
            font.pixelSize: 28; font.bold: true
        }
    }

    // ── Tira de cartas ──
    ListView {
        id: strip
        anchors { left: parent.left; right: parent.right }
        y: 210
        height: picker.cardH + 70
        orientation: ListView.Horizontal
        spacing: 10
        model: picker.items
        currentIndex: picker.sel
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: (width - picker.bigW) / 2
        preferredHighlightEnd: (width + picker.bigW) / 2
        highlightMoveDuration: 250
        boundsBehavior: Flickable.StopAtBounds
        interactive: false

        delegate: Item {
            id: card
            required property var modelData
            required property int index
            readonly property bool big: index === picker.sel
            readonly property string mode: Wallpapers.modeOf(modelData)
            readonly property bool isCurrent: modelData.path === Wallpapers.current

            width: big ? picker.bigW : 92
            height: strip.height
            opacity: big ? 1 : Math.abs(index - picker.sel) === 1 ? 0.9 : 0.7
            Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            // Nombre
            Text {
                id: title
                width: parent.width
                height: 30
                horizontalAlignment: card.big ? Text.AlignLeft : Text.AlignHCenter
                verticalAlignment: Text.AlignBottom
                text: card.big ? card.modelData.name.replace(/\.\w+$/, "").replace(/-/g, " ").toUpperCase() : "#" + card.modelData.num
                elide: Text.ElideRight
                color: card.big ? Theme.text : Theme.textMute
                font.pixelSize: card.big ? 22 : 12
                font.bold: true
                font.letterSpacing: card.big ? 1.4 : 0.5
            }
            Text {
                visible: card.big
                anchors { right: parent.right; bottom: title.bottom }
                text: card.modelData.name
                color: Theme.textMute
                font.family: "monospace"; font.pixelSize: 12
            }

            // Carta
            Rectangle {
                id: frame
                y: 40
                width: parent.width
                height: picker.cardH
                color: "#050607"
                clip: true
                border.width: card.big ? 2 : 1
                border.color: card.big ? Theme.accentLight : "#050607"

                Image {
                    id: img
                    anchors { fill: parent; margins: frame.border.width }
                    source: "file://" + card.modelData.path
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 900
                    asynchronous: true
                }

                // Filo del modo
                Rectangle {
                    width: parent.width
                    height: 3
                    color: picker.modeColor(card.mode)
                    visible: !card.big
                }

                // Sombra inferior
                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: 120
                    gradient: Gradient {
                        GradientStop { position: 0; color: "transparent" }
                        GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.85) }
                    }
                }

                // Triángulo con el número
                Item {
                    id: badge
                    x: card.big ? 18 : (parent.width - width) / 2
                    y: parent.height - (card.big ? 58 : 70)
                    width: card.big ? 46 : 30
                    height: card.big ? 40 : 26
                    Shape {
                        anchors.fill: parent
                        ShapePath {
                            fillColor: card.big ? Theme.accentLight : picker.modeColor(card.mode)
                            strokeColor: "transparent"
                            startX: 0; startY: 0
                            PathLine { x: badge.width; y: 0 }
                            PathLine { x: badge.width / 2; y: badge.height }
                            PathLine { x: 0; y: 0 }
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: card.big ? 4 : 2
                        text: card.modelData.num
                        color: "#14110c"
                        font.pixelSize: card.big ? 16 : 12; font.bold: true
                    }
                }

                // Pequeña: modo
                Text {
                    visible: !card.big
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 12 }
                    text: card.mode === "" ? "—" : card.mode.toUpperCase()
                    color: Theme.text
                    font.family: "monospace"; font.pixelSize: 10; font.bold: true
                }

                // Grande: datos, actual y asignación
                Column {
                    visible: card.big
                    x: badge.x + badge.width + 14
                    anchors { bottom: parent.bottom; bottomMargin: 16 }
                    spacing: 2
                    Text {
                        text: Wallpapers.sizeText(card.modelData.size)
                        color: Theme.text
                        font.family: "monospace"; font.pixelSize: 15; font.bold: true
                    }
                    Text {
                        text: card.mode === "" ? "Radiant y Dire" : "Solo " + (card.mode === "radiant" ? "Radiant" : "Dire")
                        color: Theme.textMute
                        font.pixelSize: 12
                    }
                }

                Rectangle {
                    visible: card.big && card.isCurrent
                    x: 14; y: 12
                    width: currentText.implicitWidth + 20
                    height: 24
                    color: Qt.rgba(0, 0, 0, 0.6)
                    border.width: 1
                    border.color: Theme.accent
                    Text {
                        id: currentText
                        anchors.centerIn: parent
                        text: "★ FONDO ACTUAL"
                        color: Theme.accentLight
                        font.pixelSize: 11; font.bold: true; font.letterSpacing: 1.6
                    }
                }

                Row {
                    visible: card.big
                    anchors { right: parent.right; rightMargin: 16; bottom: parent.bottom; bottomMargin: 18 }
                    spacing: 6
                    Repeater {
                        model: [["radiant", "RADIANT", "R"], ["dire", "DIRE", "D"]]
                        Rectangle {
                            required property var modelData
                            readonly property bool on: card.mode === modelData[0]
                            width: modeText.implicitWidth + 22
                            height: 30
                            color: on ? (modelData[0] === "radiant" ? Qt.rgba(0.18, 0.32, 0.15, 0.8) : Qt.rgba(0.43, 0.16, 0.12, 0.8)) : Qt.rgba(0, 0, 0, 0.5)
                            border.width: 1
                            border.color: on ? picker.modeColor(modelData[0]) : Theme.edge
                            Text {
                                id: modeText
                                anchors.centerIn: parent
                                text: (parent.on ? "✓ " : "") + modelData[1] + "  " + modelData[2]
                                color: parent.on ? Theme.text : Theme.textMute
                                font.pixelSize: 12; font.bold: true; font.letterSpacing: 1.4
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Wallpapers.assign(card.modelData, modelData[0])
                            }
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: frame
                anchors.topMargin: 40
                z: -1
                cursorShape: Qt.PointingHandCursor
                onClicked: picker.sel = card.index
                onDoubleClicked: { picker.sel = card.index; picker.applyCurrent(); }
            }
        }
    }

    Text {
        anchors.centerIn: strip
        visible: picker.items.length === 0
        text: Wallpapers.list.length ? "NO HAY FONDOS EN ESTA PESTAÑA" : "AÑADE FONDOS A ~/Pictures/Wallpapers (wallpaper-dota-1.jpg, -2…)"
        color: Theme.textMute
        font.pixelSize: 15; font.bold: true; font.letterSpacing: 1.5
    }

    // Flechas
    component Arrow: Rectangle {
        property string glyph
        signal clicked
        width: 44
        height: 80
        color: Qt.rgba(0, 0, 0, 0.5)
        border.width: 1
        border.color: arrowArea.containsMouse ? Theme.accent : Theme.edge
        Text { anchors.centerIn: parent; text: parent.glyph; color: Theme.text; font.pixelSize: 26 }
        MouseArea { id: arrowArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
    }
    Arrow { x: 24; y: strip.y + 40 + (picker.cardH - height) / 2; glyph: "‹"; onClicked: picker.move(-1) }
    Arrow { x: parent.width - width - 24; y: strip.y + 40 + (picker.cardH - height) / 2; glyph: "›"; onClicked: picker.move(1) }

    // Carpeta
    Column {
        x: 80
        anchors { bottom: bottomBar.top; bottomMargin: 30 }
        spacing: 4
        Text { text: "Carpeta  " + Wallpapers.dir.replace(Quickshell.env("HOME"), "~"); color: Theme.moon; font.pixelSize: 13 }
        Text { text: "Radiant se usa en modo general · Dire en modo juego · sin asignar = los dos"; color: Theme.textMute; font.pixelSize: 13 }
    }

    // ── Barra inferior ──
    Rectangle {
        id: bottomBar
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 90
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.rgba(0.16, 0.12, 0.27, 0.6) }
            GradientStop { position: 0.3; color: Qt.rgba(0.08, 0.06, 0.12, 0.9) }
            GradientStop { position: 0.7; color: Qt.rgba(0.08, 0.06, 0.12, 0.9) }
            GradientStop { position: 1; color: Qt.rgba(0.16, 0.12, 0.27, 0.6) }
        }
        Rectangle { width: parent.width; height: 1; color: "#3b3450" }

        Row {
            x: 80
            anchors.verticalCenter: parent.verticalCenter
            spacing: 22
            Repeater {
                model: [["← →", "elegir"], ["⏎", "aplicar"], ["R D", "asignar a modo"], ["Tab", "pestaña"], ["Esc", "cerrar"]]
                Row {
                    required property var modelData
                    spacing: 6
                    Key { anchors.verticalCenter: parent.verticalCenter; label: modelData[0] }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: modelData[1]; color: Theme.textMute; font.pixelSize: 13 }
                }
            }
        }

        Rectangle {
            anchors { right: parent.right; rightMargin: 80; verticalCenter: parent.verticalCenter }
            width: 240
            height: 56
            border.width: 1
            border.color: applyArea.containsMouse ? "#c8f0b0" : "#050607"
            gradient: Gradient {
                GradientStop { position: 0; color: "#6fbf4a" }
                GradientStop { position: 1; color: "#2f6a24" }
            }
            Text {
                anchors.centerIn: parent
                text: "APLICAR"
                color: "#f4ffe8"
                font.pixelSize: 24; font.bold: true; font.letterSpacing: 3
            }
            MouseArea {
                id: applyArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: picker.applyCurrent()
            }
        }
    }
}
