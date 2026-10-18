import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../config"
import "../../services"
import "../common"

// Courier: historial del portapapeles al estilo de la tienda de Dota
PanelWindow {
    id: courier
    visible: ShellState.clipboardOpen

    WlrLayershell.namespace: "ancient-clipboard"
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

    // ── Estado ──
    property string query: ""
    property int tab: 0                 // 0 todo · 1 texto · 2 imágenes · 3 fijados
    property int sel: 0
    readonly property var tabs: ["TODO", "TEXTO", "IMÁGENES", "◆ FIJADOS"]

    readonly property var items: {
        const q = query.toLowerCase();
        return Clipboard.entries.filter(e => {
            if (tab === 1 && e.kind === "IMAGEN")
                return false;
            if (tab === 2 && e.kind !== "IMAGEN")
                return false;
            if (tab === 3 && !e.pinned)
                return false;
            return q === "" || e.text.toLowerCase().includes(q);
        });
    }
    readonly property var current: items[sel] ?? null
    onCurrentChanged: Clipboard.load(current)
    onItemsChanged: sel = Math.min(sel, Math.max(0, items.length - 1))

    onVisibleChanged: {
        if (!visible)
            return;
        query = "";
        searchInput.text = "";
        tab = 0;
        sel = 0;
        Clipboard.refresh();
        Qt.callLater(() => searchInput.forceActiveFocus());
    }

    function close() {
        ShellState.clipboardOpen = false;
    }

    // Cierra primero (el foco vuelve a la ventana) y luego pega
    function use(e, andPaste) {
        if (!e)
            return;
        pending.entry = e;
        pending.andPaste = andPaste;
        close();
        pending.restart();
    }
    Timer {
        id: pending
        property var entry: null
        property bool andPaste: true
        interval: 150
        onTriggered: Clipboard.use(entry, andPaste)
    }

    // Aspecto de cada tipo de objeto
    function look(kind) {
        switch (kind) {
        case "ENLACE":
            return { top: "#1f4a6e", bot: "#0b1d2c", glyph: "↗" };
        case "CÓDIGO":
            return { top: "#2e5226", bot: "#14240f", glyph: "</>" };
        case "IMAGEN":
            return { top: "#2c2c2c", bot: "#0d0d0d", glyph: "▣" };
        default:
            return { top: "#3a3428", bot: "#14120d", glyph: "≡" };
        }
    }

    // ── Piezas ──
    component Key: Rectangle {
        property string label
        width: Math.max(16, keyText.implicitWidth + 6)
        height: 16
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

    component ActionButton: Rectangle {
        id: ab
        property string label
        property string key
        property color topColor: Theme.frameTop
        property color bottomColor: Theme.frameBot
        property color textColor: Theme.text
        signal clicked
        height: 34
        border.width: 1
        border.color: abArea.containsMouse ? Theme.accentLight : Theme.edgeDark
        gradient: Gradient {
            GradientStop { position: 0; color: ab.topColor }
            GradientStop { position: 1; color: ab.bottomColor }
        }
        Row {
            anchors.centerIn: parent
            spacing: 8
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: ab.label
                color: ab.textColor
                font.pixelSize: 12; font.bold: true; font.letterSpacing: 1.2
            }
            Key { anchors.verticalCenter: parent.verticalCenter; label: ab.key }
        }
        MouseArea {
            id: abArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ab.clicked()
        }
    }

    // ── Fondo oscurecido: clic fuera = cerrar ──
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)
        MouseArea {
            anchors.fill: parent
            onClicked: courier.close()
        }
    }

    // ── Panel ──
    Rectangle {
        id: frame
        anchors.centerIn: parent
        width: 780
        height: 600
        border.width: 1
        border.color: Theme.frameEdge
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.frameTop }
            GradientStop { position: 1; color: Theme.frameBot }
        }
        MouseArea { anchors.fill: parent }   // los clics dentro no cierran

        TexturePanel {
            anchors { fill: parent; margins: 5 }
            shade: 0.4
            accentTop: true
            border.width: 1
            border.color: Theme.edgeDark

            Column {
                anchors.fill: parent

                // Cabecera
                Rectangle {
                    width: parent.width
                    height: 52
                    color: Qt.rgba(0, 0, 0, 0.3)
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.edge }

                    Column {
                        x: 14
                        anchors.verticalCenter: parent.verticalCenter
                        Text { text: "COURIER"; color: Theme.text; font.pixelSize: 17; font.bold: true; font.letterSpacing: 1.4 }
                        Text {
                            text: "PORTAPAPELES · " + Clipboard.entries.length + " OBJETOS"
                            color: Theme.accentLight
                            font.pixelSize: 11; font.bold: true; font.letterSpacing: 1.8
                        }
                    }

                    // Búsqueda
                    Rectangle {
                        anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                        width: 260
                        height: 30
                        color: Theme.slot
                        border.width: 1
                        border.color: searchInput.activeFocus ? Theme.accent : Theme.edge

                        TextInput {
                            id: searchInput
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.text
                            font.pixelSize: 14
                            clip: true
                            onTextChanged: { courier.query = text; courier.sel = 0; }

                            Keys.onPressed: e => {
                                const ctrl = e.modifiers & Qt.ControlModifier;
                                if (e.key === Qt.Key_Escape) {
                                    courier.close();
                                } else if (e.key === Qt.Key_Down) {
                                    courier.sel = Math.min(courier.sel + 1, courier.items.length - 1);
                                } else if (e.key === Qt.Key_Up) {
                                    courier.sel = Math.max(courier.sel - 1, 0);
                                } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                                    courier.use(courier.current, !(e.modifiers & Qt.ShiftModifier));
                                } else if (e.key === Qt.Key_Tab) {
                                    courier.tab = (courier.tab + 1) % 4;
                                    courier.sel = 0;
                                } else if (e.key === Qt.Key_Delete) {
                                    if (courier.current) Clipboard.remove(courier.current);
                                } else if (ctrl && e.key === Qt.Key_P) {
                                    Clipboard.togglePin(courier.current);
                                } else if (courier.query === "" && e.key >= Qt.Key_1 && e.key <= Qt.Key_9) {
                                    courier.use(courier.items[e.key - Qt.Key_1], true);   // 1–9: pegar directo
                                } else {
                                    return;
                                }
                                e.accepted = true;
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: searchInput.text === ""
                                text: "Buscar…"
                                color: Theme.textMute
                                font.pixelSize: 14
                            }
                        }
                    }
                }

                // Pestañas
                Row {
                    leftPadding: 14
                    topPadding: 10
                    spacing: 4
                    Repeater {
                        model: courier.tabs
                        Rectangle {
                            required property string modelData
                            required property int index
                            width: tabText.implicitWidth + 24
                            height: 26
                            color: Qt.rgba(0, 0, 0, 0.4)
                            border.width: 1
                            border.color: courier.tab === index ? Theme.accent : Theme.edge
                            Text {
                                id: tabText
                                anchors.centerIn: parent
                                text: modelData
                                color: courier.tab === index ? Theme.text : Theme.textMute
                                font.pixelSize: 11; font.bold: true; font.letterSpacing: 1.3
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { courier.tab = index; courier.sel = 0; searchInput.forceActiveFocus(); }
                            }
                        }
                    }
                }

                // Cuerpo: lista + vista previa
                Item {
                    width: parent.width
                    height: parent.height - 52 - 36 - 30
                    Row {
                        anchors { fill: parent; margins: 14; topMargin: 10 }
                        spacing: 12

                        // Lista
                        ListView {
                            id: listView
                            width: 430
                            height: parent.height
                            clip: true
                            spacing: 3
                            model: courier.items
                            currentIndex: courier.sel
                            highlightMoveDuration: 0
                            boundsBehavior: Flickable.StopAtBounds

                            delegate: Rectangle {
                                id: row
                                required property var modelData
                                required property int index
                                readonly property bool selected: index === courier.sel
                                readonly property var lk: courier.look(modelData.kind)
                                width: listView.width
                                height: 46
                                color: selected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2) : Qt.rgba(0, 0, 0, 0.35)
                                border.width: 1
                                border.color: selected ? Theme.accentLight : Theme.edgeDark

                                Row {
                                    anchors { fill: parent; leftMargin: 6; rightMargin: 10 }
                                    spacing: 10

                                    Key {
                                        anchors.verticalCenter: parent.verticalCenter
                                        label: row.index < 9 ? String(row.index + 1) : ""
                                        opacity: row.index < 9 ? 1 : 0
                                    }

                                    // Hueco del objeto
                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 34; height: 34
                                        clip: true
                                        border.width: 1
                                        border.color: Theme.edgeDark
                                        color: row.modelData.kind === "COLOR" ? row.modelData.text.trim() : "transparent"
                                        gradient: row.modelData.kind === "COLOR" ? null : slotGrad
                                        Gradient {
                                            id: slotGrad
                                            GradientStop { position: 0; color: row.lk.top }
                                            GradientStop { position: 1; color: row.lk.bot }
                                        }
                                        Text {
                                            anchors.centerIn: parent
                                            visible: row.modelData.kind !== "COLOR" && row.modelData.kind !== "IMAGEN"
                                            text: row.lk.glyph
                                            color: Theme.text
                                            font.pixelSize: row.lk.glyph.length > 1 ? 10 : 16; font.bold: true
                                        }
                                        Image {
                                            anchors { fill: parent; margins: 2 }
                                            visible: row.modelData.kind === "IMAGEN"
                                            source: visible ? Clipboard.thumb(row.modelData) : ""
                                            sourceSize: Qt.size(64, 64)
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 16 - 34 - 20 - 24
                                        Text {
                                            width: parent.width
                                            text: row.modelData.text
                                            elide: Text.ElideRight
                                            maximumLineCount: 1
                                            color: Theme.text
                                            font.pixelSize: 14
                                            font.family: row.modelData.kind === "CÓDIGO" || row.modelData.kind === "COLOR" ? "monospace" : Qt.application.font.family
                                        }
                                        Text {
                                            text: row.modelData.info
                                            color: Theme.textMute
                                            font.pixelSize: 11
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: row.modelData.pinned
                                        text: "◆"
                                        color: Theme.accentLight
                                        font.pixelSize: 12
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { courier.sel = row.index; searchInput.forceActiveFocus(); }
                                    onDoubleClicked: courier.use(row.modelData, true)
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: courier.items.length === 0
                                text: Clipboard.entries.length ? "SIN RESULTADOS" : "EL COURIER ESTÁ VACÍO"
                                color: Theme.textMute
                                font.pixelSize: 13; font.bold: true; font.letterSpacing: 1.5
                            }
                        }

                        // Vista previa (ficha de tienda)
                        Rectangle {
                            width: parent.width - 430 - 12
                            height: parent.height
                            color: Qt.rgba(0, 0, 0, 0.5)
                            border.width: 1
                            border.color: Theme.edge

                            Rectangle {
                                id: previewHead
                                width: parent.width
                                height: 34
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) }
                                    GradientStop { position: 1; color: "transparent" }
                                }
                                Text {
                                    x: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: courier.current ? courier.current.kind : "VACÍO"
                                    color: Theme.accentLight
                                    font.pixelSize: 12; font.bold: true; font.letterSpacing: 1.6
                                }
                                Text {
                                    anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                                    text: !courier.current ? "" : courier.current.kind === "IMAGEN" ? courier.current.info : Clipboard.fullText.length + " caracteres"
                                    color: Theme.textMute
                                    font.pixelSize: 11
                                }
                            }

                            // Contenido
                            Rectangle {
                                anchors { top: previewHead.bottom; left: parent.left; right: parent.right; bottom: actions.top; margins: 12 }
                                color: "#07090a"
                                border.width: 1
                                border.color: Theme.edgeDark
                                clip: true

                                Image {
                                    anchors { fill: parent; margins: 6 }
                                    visible: courier.current !== null && courier.current.kind === "IMAGEN"
                                    source: visible ? Clipboard.thumb(courier.current) : ""
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                }
                                Rectangle {
                                    anchors { fill: parent; margins: 12 }
                                    visible: courier.current !== null && courier.current.kind === "COLOR"
                                    color: visible ? courier.current.text.trim() : "transparent"
                                }
                                Text {
                                    anchors { fill: parent; margins: 12 }
                                    visible: courier.current !== null && courier.current.kind !== "IMAGEN" && courier.current.kind !== "COLOR"
                                    text: Clipboard.fullText
                                    wrapMode: Text.WrapAnywhere
                                    elide: Text.ElideRight
                                    color: Theme.text
                                    font.family: "monospace"
                                    font.pixelSize: 13
                                    lineHeight: 1.3
                                }
                            }

                            // Acciones
                            Column {
                                id: actions
                                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 12 }
                                spacing: 6
                                ActionButton {
                                    width: parent.width
                                    label: "PEGAR"; key: "⏎"
                                    topColor: Theme.accent; bottomColor: Qt.darker(Theme.accent, 1.8)
                                    textColor: "#0a0c0e"
                                    onClicked: courier.use(courier.current, true)
                                }
                                Row {
                                    width: parent.width
                                    spacing: 6
                                    ActionButton {
                                        width: (parent.width - 6) / 2
                                        label: courier.current && courier.current.pinned ? "◆ QUITAR" : "◆ FIJAR"
                                        key: "Ctrl P"
                                        opacity: courier.current && courier.current.kind !== "IMAGEN" ? 1 : 0.4
                                        onClicked: Clipboard.togglePin(courier.current)
                                    }
                                    ActionButton {
                                        width: (parent.width - 6) / 2
                                        label: "BORRAR"; key: "Del"
                                        topColor: Theme.dangerTop; bottomColor: Theme.dangerBot
                                        onClicked: if (courier.current) Clipboard.remove(courier.current)
                                    }
                                }
                            }
                        }
                    }
                }

                // Pie
                Rectangle {
                    width: parent.width
                    height: 30
                    color: Qt.rgba(0, 0, 0, 0.35)
                    Rectangle { width: parent.width; height: 1; color: Theme.edge }
                    Text {
                        x: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: "↑↓ elegir    1–9 pegar directo    ⏎ pegar    Shift ⏎ solo copiar    Tab pestaña    Ctrl P fijar    Del borrar    Esc cerrar"
                        color: Theme.textMute
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}
