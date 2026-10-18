import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../config"
import "../../services"
import "../common"

// Selector completo de emojis (se abre con Tab desde la rueda)
PanelWindow {
    id: picker
    visible: ShellState.emojiPickerOpen

    WlrLayershell.namespace: "ancient-emoji"
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

    readonly property int cols: 12
    property string query: ""
    property int tab: 0
    property int sel: 0

    readonly property var items: query !== "" ? Emoji.search(query) : Emoji.inGroup(Emoji.groups[tab][0])
    readonly property var current: items[sel] ?? null
    onItemsChanged: sel = 0

    onVisibleChanged: {
        if (!visible)
            return;
        searchInput.text = "";
        tab = 0;
        sel = 0;
        Qt.callLater(() => searchInput.forceActiveFocus());
    }

    function close() {
        ShellState.emojiPickerOpen = false;
    }
    function choose(item, andType) {
        if (!item)
            return;
        close();
        Emoji.pick(item.e, andType);
    }
    function move(d) {
        sel = Math.max(0, Math.min(items.length - 1, sel + d));
        grid.positionViewAtIndex(sel, GridView.Contain);
    }

    // Fondo: clic fuera = cerrar
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)
        MouseArea {
            anchors.fill: parent
            onClicked: picker.close()
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 700
        height: 600
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
            shade: 0.4
            accentTop: true
            border.width: 1
            border.color: Theme.edgeDark

            Column {
                anchors.fill: parent

                // Cabecera
                Rectangle {
                    width: parent.width
                    height: 50
                    color: Qt.rgba(0, 0, 0, 0.3)
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: Theme.edge
                    }

                    Text {
                        x: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: "EMOJIS"
                        color: Theme.text
                        font.pixelSize: 16
                        font.bold: true
                        font.letterSpacing: 1.4
                    }

                    Rectangle {
                        anchors {
                            right: parent.right
                            rightMargin: 14
                            verticalCenter: parent.verticalCenter
                        }
                        width: 320
                        height: 30
                        color: Theme.slot
                        border.width: 1
                        border.color: searchInput.activeFocus ? Theme.accent : Theme.edge

                        TextInput {
                            id: searchInput
                            anchors {
                                fill: parent
                                leftMargin: 10
                                rightMargin: 10
                            }
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.text
                            font.pixelSize: 14
                            clip: true
                            onTextChanged: picker.query = text

                            Keys.onPressed: e => {
                                if (e.key === Qt.Key_Escape)
                                    picker.close();
                                else if (e.key === Qt.Key_Right)
                                    picker.move(1);
                                else if (e.key === Qt.Key_Left)
                                    picker.move(-1);
                                else if (e.key === Qt.Key_Down)
                                    picker.move(picker.cols);
                                else if (e.key === Qt.Key_Up)
                                    picker.move(-picker.cols);
                                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)
                                    picker.choose(picker.current, !(e.modifiers & Qt.ShiftModifier));
                                else if (e.key === Qt.Key_Tab && picker.query === "")
                                    picker.tab = (picker.tab + 1) % Emoji.groups.length;
                                else if (e.key === Qt.Key_Backtab && picker.query === "")
                                    picker.tab = (picker.tab + Emoji.groups.length - 1) % Emoji.groups.length;
                                else
                                    return;
                                e.accepted = true;
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: searchInput.text === ""
                                text: "Buscar: corazón, risa, fuego…"
                                color: Theme.textMute
                                font.pixelSize: 14
                            }
                        }
                    }
                }

                // Pestañas
                Flow {
                    id: tabsFlow
                    width: parent.width
                    leftPadding: 14
                    rightPadding: 14
                    topPadding: 10
                    spacing: 3
                    opacity: picker.query === "" ? 1 : 0.4
                    Repeater {
                        model: Emoji.groups
                        Rectangle {
                            required property var modelData
                            required property int index
                            width: tabText.implicitWidth + 18
                            height: 26
                            color: Qt.rgba(0, 0, 0, 0.4)
                            border.width: 1
                            border.color: picker.tab === index ? Theme.accent : Theme.edge
                            Text {
                                id: tabText
                                anchors.centerIn: parent
                                text: modelData[1]
                                color: picker.tab === index ? Theme.text : Theme.textMute
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 1.1
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    searchInput.text = "";
                                    picker.tab = index;
                                    searchInput.forceActiveFocus();
                                }
                            }
                        }
                    }
                }

                // Cuadrícula
                Item {
                    width: parent.width
                    height: parent.height - 50 - tabsFlow.height - 70
                    GridView {
                        id: grid
                        anchors {
                            fill: parent
                            margins: 14
                            topMargin: 10
                        }
                        clip: true
                        cellWidth: 52
                        cellHeight: 52
                        model: picker.items
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: Rectangle {
                            id: cell
                            required property var modelData
                            required property int index
                            readonly property bool selected: index === picker.sel
                            width: 48
                            height: 48
                            color: selected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25) : Qt.rgba(0, 0, 0, 0.4)
                            border.width: 1
                            border.color: selected ? Theme.accentLight : Theme.edgeDark
                            Text {
                                anchors.centerIn: parent
                                text: cell.modelData.e
                                font.pixelSize: 26
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: picker.sel = cell.index
                                onClicked: picker.choose(cell.modelData, true)
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: picker.items.length === 0
                            text: Emoji.all.length ? "SIN RESULTADOS" : "FALTA assets/emoji.json"
                            color: Theme.textMute
                            font.pixelSize: 13
                            font.bold: true
                            font.letterSpacing: 1.5
                        }
                    }
                }

                // Pie: emoji elegido
                Rectangle {
                    width: parent.width
                    height: 70
                    color: Qt.rgba(0, 0, 0, 0.35)
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Theme.edge
                    }

                    Row {
                        x: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 14
                        Rectangle {
                            width: 50
                            height: 50
                            color: Qt.rgba(0, 0, 0, 0.5)
                            border.width: 2
                            border.color: Theme.accentLight
                            Text {
                                anchors.centerIn: parent
                                text: picker.current ? picker.current.e : ""
                                font.pixelSize: 32
                            }
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Text {
                                width: 220
                                elide: Text.ElideRight
                                text: picker.current ? picker.current.n.charAt(0).toUpperCase() + picker.current.n.slice(1) : ""
                                color: Theme.text
                                font.pixelSize: 15
                                font.bold: true
                            }
                            Text {
                                text: picker.query !== "" ? picker.items.length + " resultados" : Emoji.groups[picker.tab][1].toLowerCase()
                                color: Theme.textMute
                                font.pixelSize: 11
                            }
                        }
                    }
                    Text {
                        anchors {
                            right: parent.right
                            rightMargin: 14
                            verticalCenter: parent.verticalCenter
                        }
                        text: "←↑↓→ mover · ⏎ pegar · Shift ⏎ copiar · Tab · Esc"
                        color: Theme.textMute
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}
