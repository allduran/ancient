import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../config"
import "../../services"
import "../bar"
import "../common"

// Armería: lanzador estilo tienda de Dota
PanelWindow {
    id: armory
    visible: ShellState.armoryOpen

    WlrLayershell.namespace: "ancient-armory"
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
    property int tab: 0                 // 0 = apps · 1 = acciones
    property int catIndex: 0
    property int sel: 0

    readonly property var actionList: [
        {
            name: "Captura de zona",
            hint: "CAPTURA",
            run: () => Capture.startSelect("area")
        },
        {
            name: "Captura de pantalla",
            hint: "CAPTURA",
            run: () => Capture.run("screen")
        },
        {
            name: "Captura de ventana",
            hint: "CAPTURA",
            run: () => Capture.run("window")
        },
        {
            name: "Grabar zona",
            hint: "VÍDEO",
            run: () => Capture.startSelect("record-area")
        },
        {
            name: "Cambiar modo Radiant / Dire",
            hint: "MODO",
            run: () => ShellState.mode = (ShellState.mode === "dire" ? "radiant" : "dire")
        },
        {
            name: "Borrar notificaciones",
            hint: "AVISOS",
            run: () => Notifs.clearAll()
        },
        {
            name: "Lista de ventanas",
            hint: "BARRA",
            run: () => ShellState.windowListOpen = !ShellState.windowListOpen
        },
        {
            name: "Bloquear",
            hint: "SESIÓN",
            run: () => Session.lock()
        },
        {
            name: "Suspender",
            hint: "SESIÓN",
            run: () => Session.suspend()
        },
        {
            name: "Abandonar la partida…",
            hint: "SESIÓN",
            run: () => Session.menuOpen = true
        },
    ]

    readonly property var items: tab === 0 ? Apps.search(query, Apps.categories[catIndex]) : actionList.filter(a => a.name.toLowerCase().includes(query.trim().toLowerCase()))
    readonly property var current: items.length > 0 ? items[Math.min(sel, items.length - 1)] : null

    onItemsChanged: sel = 0
    onVisibleChanged: {
        if (!visible)
            return;
        query = "";
        searchInput.text = "";
        tab = 0;
        catIndex = 0;
        sel = 0;
        searchInput.forceActiveFocus();
    }

    function close() {
        ShellState.armoryOpen = false;
    }

    // Cierra primero y ejecuta después (si no, saldría en las capturas)
    function runAfterClose(fn) {
        pending.fn = fn;
        close();
        pending.restart();
    }
    function launchApp(e) {
        runAfterClose(() => Apps.launch(e));
    }
    function activate(item) {
        if (!item)
            return;
        if (tab === 0)
            launchApp(item);
        else
            runAfterClose(item.run);
    }

    Timer {
        id: pending
        property var fn: null
        interval: 150
        onTriggered: if (fn)
            fn()
    }

    // ── Piezas reutilizables ──
    component SectionTitle: Text {
        color: Theme.textMute
        font.pixelSize: 11
        font.bold: true
        font.letterSpacing: 1.6
        leftPadding: 10
        topPadding: 10
        bottomPadding: 6
    }

    component QuickButton: Rectangle {
        id: qb
        property string text
        property bool danger: false
        signal clicked
        width: qbText.implicitWidth + 28
        height: 30
        color: danger ? Theme.dangerBot : (qbArea.containsMouse ? Theme.frameTop : Theme.slot)
        border.width: 1
        border.color: danger ? Theme.danger : (qbArea.containsMouse ? Theme.accent : Theme.edge)
        Text {
            id: qbText
            anchors.centerIn: parent
            text: qb.text
            color: qb.danger ? "#f4d8d0" : Theme.textSoft
            font.pixelSize: 13
        }
        MouseArea {
            id: qbArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: qb.clicked()
        }
    }

    // ── Fondo oscurecido: clic fuera = cerrar ──
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)
        MouseArea {
            anchors.fill: parent
            onClicked: armory.close()
        }
    }

    // ── Panel ──
    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: 1000
        height: 620
        TexturePanel {
            anchors.fill: parent
            shade: 0.45
        }
        border.width: 1
        border.color: Theme.frameEdge

        MouseArea {
            anchors.fill: parent
        }    // los clics dentro no cierran

        // ═══ Cabecera ═══
        TexturePanel {
            id: header
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 1
            }
            height: 46
            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: 2
                color: Theme.accent
            }

            Text {
                id: title
                anchors {
                    left: parent.left
                    leftMargin: 14
                    verticalCenter: parent.verticalCenter
                }
                text: "ARMORY"
                color: Theme.accentLight
                font.pixelSize: 20
                font.bold: true
                font.letterSpacing: 3
            }

            // Buscador
            Rectangle {
                anchors {
                    left: title.right
                    leftMargin: 14
                    right: tabs.left
                    rightMargin: 14
                    verticalCenter: parent.verticalCenter
                }
                height: 30
                color: Theme.slot
                border.width: 1
                border.color: searchInput.activeFocus ? Theme.accent : Theme.edge

                Text {
                    id: lens
                    anchors {
                        left: parent.left
                        leftMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    text: "⌕"
                    color: Theme.accentLight
                    font.pixelSize: 16
                }
                TextInput {
                    id: searchInput
                    anchors {
                        left: lens.right
                        leftMargin: 8
                        right: parent.right
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    color: Theme.text
                    font.pixelSize: 15
                    clip: true
                    onTextChanged: armory.query = text

                    Keys.onPressed: e => {
                        if (e.key === Qt.Key_Escape) {
                            armory.close();
                            e.accepted = true;
                        } else if (e.key === Qt.Key_Down) {
                            armory.sel = Math.min(armory.sel + 1, armory.items.length - 1);
                            e.accepted = true;
                        } else if (e.key === Qt.Key_Up) {
                            armory.sel = Math.max(armory.sel - 1, 0);
                            e.accepted = true;
                        } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                            armory.activate(armory.current);
                            e.accepted = true;
                        } else if (e.key === Qt.Key_Tab) {
                            armory.tab = 1 - armory.tab;
                            e.accepted = true;
                        } else if (e.key === Qt.Key_P && (e.modifiers & Qt.ControlModifier) && armory.tab === 0) {
                            Apps.togglePin(armory.current);
                            e.accepted = true;
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: searchInput.text === ""
                        text: armory.tab === 0 ? "Buscar aplicaciones…" : "Buscar acciones…"
                        color: Theme.textMute
                        font.pixelSize: 15
                    }
                }
            }

            // Pestañas
            Row {
                id: tabs
                anchors {
                    right: esc.left
                    rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                Repeater {
                    model: ["APPS", "ACCIONES"]
                    Rectangle {
                        required property string modelData
                        required property int index
                        readonly property bool on: armory.tab === index
                        width: tabText.implicitWidth + 28
                        height: 30
                        color: on ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2) : Theme.slot
                        border.width: 1
                        border.color: on ? Theme.accent : Theme.edge
                        Text {
                            id: tabText
                            anchors.centerIn: parent
                            text: modelData
                            color: parent.on ? Theme.text : Theme.textMute
                            font.pixelSize: 12
                            font.bold: true
                            font.letterSpacing: 1.5
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                armory.tab = index;
                                searchInput.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            Text {
                id: esc
                anchors {
                    right: parent.right
                    rightMargin: 14
                    verticalCenter: parent.verticalCenter
                }
                text: "ESC"
                color: Theme.textMute
                font.family: "monospace"
                font.pixelSize: 11
            }
        }

        // ═══ Pie: Quick ═══
        TexturePanel {
            id: quick
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                margins: 1
            }
            height: 48
            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                height: 1
                color: Theme.edge
            }

            Row {
                anchors {
                    left: parent.left
                    leftMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                spacing: 6
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "QUICK"
                    color: Theme.accentLight
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1.6
                    rightPadding: 8
                }
                QuickButton {
                    text: "Bloquear"
                    onClicked: armory.runAfterClose(() => Session.lock())
                }
                QuickButton {
                    text: "Suspender"
                    onClicked: armory.runAfterClose(() => Session.suspend())
                }
                QuickButton {
                    text: "Abandonar…"
                    danger: true
                    onClicked: armory.runAfterClose(() => Session.menuOpen = true)
                }
            }

            Text {
                anchors {
                    right: parent.right
                    rightMargin: 14
                    verticalCenter: parent.verticalCenter
                }
                text: Quickshell.env("USER")
                color: Theme.textMute
                font.pixelSize: 12
            }
        }

        // ═══ Cuerpo ═══
        Item {
            anchors {
                top: header.bottom
                bottom: quick.top
                left: parent.left
                right: parent.right
                margins: 1
            }

            // ── Izquierda: sugeridas ──
            Rectangle {
                id: leftPane
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                }
                width: 250
                color: Qt.rgba(0, 0, 0, 0.25)
                Rectangle {
                    anchors {
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: 1
                    color: Theme.edge
                }

                Column {
                    width: parent.width

                    SectionTitle {
                        text: "FIJADAS"
                        color: Theme.accentLight
                    }
                    Grid {
                        x: 10
                        columns: 4
                        spacing: 3
                        Repeater {
                            model: ShellState.pinnedApps
                            Portrait {
                                required property string modelData
                                readonly property var entry: Apps.byId(modelData)
                                width: 54
                                height: 30
                                icon: Apps.icon(entry)
                                tint: Apps.color(entry)
                                barColor: Apps.windowCount(entry) > 0 ? Apps.color(entry) : "transparent"
                                onClicked: armory.launchApp(entry)
                            }
                        }
                    }

                    SectionTitle {
                        text: "RECIENTES"
                    }
                    Grid {
                        x: 10
                        columns: 4
                        spacing: 3
                        Repeater {
                            model: ShellState.recentApps.slice(0, 4)
                            Portrait {
                                required property string modelData
                                readonly property var entry: Apps.byId(modelData)
                                width: 54
                                height: 30
                                icon: Apps.icon(entry)
                                tint: Apps.color(entry)
                                onClicked: armory.launchApp(entry)
                            }
                        }
                    }
                    Text {
                        visible: ShellState.recentApps.length === 0
                        leftPadding: 10
                        text: "Todavía nada"
                        color: Theme.textMute
                        font.pixelSize: 12
                    }

                    SectionTitle {
                        text: "CATEGORÍAS"
                    }
                    Repeater {
                        model: Apps.categories
                        Rectangle {
                            required property var modelData
                            required property int index
                            readonly property bool on: armory.tab === 0 && armory.catIndex === index
                            x: 6
                            width: leftPane.width - 12
                            height: 26
                            color: on ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : "transparent"
                            Rectangle {
                                width: 2
                                height: parent.height
                                color: Theme.accent
                                visible: parent.on
                            }
                            Text {
                                anchors {
                                    left: parent.left
                                    leftMargin: 10
                                    verticalCenter: parent.verticalCenter
                                }
                                text: modelData.label
                                color: parent.on ? Theme.text : Theme.textSoft
                                font.pixelSize: 14
                            }
                            Text {
                                anchors {
                                    right: parent.right
                                    rightMargin: 8
                                    verticalCenter: parent.verticalCenter
                                }
                                text: Apps.count(modelData)
                                color: parent.on ? Theme.accentLight : Theme.textMute
                                font.family: "monospace"
                                font.pixelSize: 12
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    armory.tab = 0;
                                    armory.catIndex = index;
                                    searchInput.forceActiveFocus();
                                }
                            }
                        }
                    }
                }
            }

            // ── Derecha: tooltip ──
            Rectangle {
                id: rightPane
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    right: parent.right
                }
                width: 300
                color: Qt.rgba(0, 0, 0, 0.3)
                Rectangle {
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: 1
                    color: Theme.edge
                }

                Rectangle {
                    id: tip
                    visible: armory.current !== null
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: 12
                    }
                    height: tipCol.implicitHeight
                    color: Theme.slot
                    border.width: 1
                    border.color: Theme.frameEdge

                    Column {
                        id: tipCol
                        width: parent.width

                        // Cabecera del tooltip
                        TexturePanel {
                            width: parent.width
                            height: 60
                            edgeBottom: true
                            Portrait {
                                id: bigPortrait
                                x: 10
                                anchors.verticalCenter: parent.verticalCenter
                                width: 64
                                height: 40
                                visible: armory.tab === 0
                                icon: armory.tab === 0 ? Apps.icon(armory.current) : ""
                                tint: Apps.color(armory.tab === 0 ? armory.current : null)
                                barColor: Apps.color(armory.tab === 0 ? armory.current : null)
                            }
                            Column {
                                anchors {
                                    left: armory.tab === 0 ? bigPortrait.right : parent.left
                                    leftMargin: 10
                                    right: parent.right
                                    rightMargin: 8
                                    verticalCenter: parent.verticalCenter
                                }
                                spacing: 3
                                Text {
                                    width: parent.width
                                    elide: Text.ElideRight
                                    text: armory.current ? armory.current.name : ""
                                    color: Theme.positive
                                    font.pixelSize: 16
                                    font.bold: true
                                }
                                Text {
                                    text: "◆ " + (armory.current ? (armory.tab === 0 ? Apps.categoryLabel(armory.current) : armory.current.hint) : "")
                                    color: Theme.accentLight
                                    font.family: "monospace"
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }
                        }

                        // Cuerpo del tooltip (solo apps)
                        Column {
                            visible: armory.tab === 0
                            width: parent.width
                            padding: 10
                            spacing: 8

                            Text {
                                width: parent.width - 20
                                wrapMode: Text.Wrap
                                text: armory.current && armory.tab === 0 ? (armory.current.comment || armory.current.genericName || "Abrir la aplicación.") : ""
                                color: Theme.textSoft
                                font.pixelSize: 13
                            }

                            // Acciones del .desktop: "+ Nueva ventana", etc.
                            Repeater {
                                model: armory.current && armory.tab === 0 ? armory.current.actions : []
                                Text {
                                    required property var modelData
                                    text: "<font color='" + Theme.positive + "'>+</font> " + modelData.name
                                    textFormat: Text.StyledText
                                    color: actArea.containsMouse ? Theme.accentLight : Theme.text
                                    font.pixelSize: 13
                                    font.bold: true
                                    MouseArea {
                                        id: actArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            const a = modelData;
                                            armory.runAfterClose(() => a.execute());
                                        }
                                    }
                                }
                            }

                            Text {
                                readonly property int n: Apps.windowCount(armory.current)
                                text: (n > 0 ? "Abierta en " + n + (n === 1 ? " ventana" : " ventanas") : "No está abierta") + (Apps.isPinned(armory.current) ? " · Fijada" : "")
                                color: Theme.textMute
                                font.pixelSize: 11
                            }
                        }
                    }
                }

                // Atajos
                Column {
                    anchors {
                        left: parent.left
                        leftMargin: 14
                        bottom: parent.bottom
                        bottomMargin: 12
                    }
                    spacing: 2
                    Repeater {
                        model: [["ENTER", "abrir"], ["↑ ↓", "moverse"], ["TAB", "apps / acciones"], ["CTRL+P", "fijar en la barra"]]
                        Text {
                            required property var modelData
                            text: "<font color='" + Theme.accentLight + "'>" + modelData[0] + "</font>  " + modelData[1]
                            textFormat: Text.StyledText
                            color: Theme.textMute
                            font.family: "monospace"
                            font.pixelSize: 11
                        }
                    }
                }
            }

            // ── Centro: lista ──
            Item {
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: leftPane.right
                    right: rightPane.left
                }

                TexturePanel {
                    id: listHeader
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    height: 28
                    shade: 0.2
                    edgeBottom: true
                    Text {
                        anchors {
                            left: parent.left
                            leftMargin: 10
                            verticalCenter: parent.verticalCenter
                        }
                        text: armory.tab === 0 ? Apps.categories[armory.catIndex].label.toUpperCase() : "ACCIONES"
                        color: Theme.text
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1.6
                    }
                    Text {
                        anchors {
                            right: parent.right
                            rightMargin: 10
                            verticalCenter: parent.verticalCenter
                        }
                        text: armory.items.length
                        color: Theme.textMute
                        font.family: "monospace"
                        font.pixelSize: 11
                    }
                }

                ListView {
                    id: list
                    anchors {
                        top: listHeader.bottom
                        topMargin: 4
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                    }
                    clip: true
                    model: armory.items
                    currentIndex: armory.sel
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                    delegate: Item {
                        id: rowItem
                        required property var modelData
                        required property int index
                        readonly property bool on: armory.sel === index
                        width: list.width
                        height: 30

                        // Fila seleccionada: degradado + filo de acento
                        Rectangle {
                            anchors.fill: parent
                            visible: rowItem.on
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop {
                                    position: 0
                                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22)
                                }
                                GradientStop {
                                    position: 0.8
                                    color: "transparent"
                                }
                            }
                            Rectangle {
                                width: 2
                                height: parent.height
                                color: Theme.accent
                            }
                        }

                        // Mini retrato (apps) o rombo (acciones)
                        Rectangle {
                            id: mini
                            x: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: 36
                            height: 22
                            color: armory.tab === 0 ? Qt.darker(Apps.color(rowItem.modelData), 2.6) : Theme.slot
                            border.width: 1
                            border.color: Theme.edgeDark
                            Image {
                                anchors.centerIn: parent
                                visible: armory.tab === 0
                                width: 16
                                height: 16
                                sourceSize: Qt.size(32, 32)
                                source: armory.tab === 0 ? Apps.icon(rowItem.modelData) : ""
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: armory.tab === 1
                                text: "◆"
                                color: Theme.accentLight
                                font.pixelSize: 11
                            }
                        }

                        Text {
                            anchors {
                                left: mini.right
                                leftMargin: 10
                                right: tag.left
                                rightMargin: 8
                                verticalCenter: parent.verticalCenter
                            }
                            elide: Text.ElideRight
                            text: rowItem.modelData.name
                            color: rowItem.on ? Theme.text : Theme.textSoft
                            font.pixelSize: 14
                            font.bold: rowItem.on
                        }

                        // "Precio": categoría o tipo de acción
                        Text {
                            id: tag
                            anchors {
                                right: parent.right
                                rightMargin: 10
                                verticalCenter: parent.verticalCenter
                            }
                            text: armory.tab === 0 ? Apps.categoryLabel(rowItem.modelData).toUpperCase() : rowItem.modelData.hint
                            color: rowItem.on ? Theme.accentLight : Theme.textMute
                            font.family: "monospace"
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: armory.sel = rowItem.index
                            onClicked: armory.activate(rowItem.modelData)
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: armory.items.length === 0
                    text: "Nada coincide con «" + armory.query + "»"
                    color: Theme.textMute
                    font.pixelSize: 13
                }
            }
        }
    }
}
