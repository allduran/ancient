import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../../config"

// Lista de ventanas abiertas, estilo "last hits" de Dota
PanelWindow {
    id: list
    required property var modelData
    screen: modelData

    WlrLayershell.namespace: "ancient-windows"
    exclusionMode: ExclusionMode.Ignore         // no empuja las ventanas
    anchors {
        top: true
        left: true
    }
    margins {
        top: Theme.stripHeight + 4
        left: 6
    }
    implicitWidth: 260
    implicitHeight: column.implicitHeight + 2
    color: "transparent"
    visible: ShellState.windowListOpen && windows.length > 0

    // Ventanas de ESTE monitor
    readonly property var windows: Hyprland.toplevels.values.filter(t => t.workspace && t.workspace.monitor && t.workspace.monitor.name === list.modelData.name)

    readonly property var numerals: ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]

    function iconFor(t) {
        const appId = t.wayland ? t.wayland.appId : (t.lastIpcObject["class"] || "");
        const entry = DesktopEntries.heuristicLookup(appId);
        return Quickshell.iconPath(entry ? entry.icon : appId, "application-x-executable");
    }

    // Fondo del panel
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.04, 0.05, 0.06, 0.88)
        border.width: 1
        border.color: Theme.edge
    }

    Column {
        id: column
        x: 1
        y: 1
        width: parent.width - 2

        // Cabecera
        Rectangle {
            width: parent.width
            height: 20
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
            Text {
                anchors {
                    left: parent.left
                    leftMargin: 8
                    verticalCenter: parent.verticalCenter
                }
                text: (ShellState.windowListCollapsed ? "▶" : "▼") + "  OPEN WINDOWS"
                color: Theme.textSoft
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 1.5
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: ShellState.windowListCollapsed = !ShellState.windowListCollapsed
            }
        }

        // Filas
        Repeater {
            model: list.windows

            Item {
                id: rowItem
                required property var modelData
                readonly property int wsId: modelData.workspace ? modelData.workspace.id : 0
                readonly property color player: Theme.playerColors[Math.max(0, wsId - 1) % 5]
                readonly property bool isActive: modelData.wayland ? modelData.wayland.activated : false

                width: column.width
                height: 20
                visible: !ShellState.windowListCollapsed

                // Fondo: color de jugador que se desvanece hacia la derecha
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 0.0
                            color: Qt.rgba(rowItem.player.r, rowItem.player.g, rowItem.player.b, rowItem.isActive ? 0.45 : 0.25)
                        }
                        GradientStop {
                            position: 0.7
                            color: "transparent"
                        }
                    }
                }

                // Filo dorado si es la ventana activa
                Rectangle {
                    width: 2
                    height: parent.height
                    color: Theme.gold
                    visible: rowItem.isActive
                }

                // Mini retrato
                Rectangle {
                    id: mini
                    x: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30
                    height: 16
                    color: Qt.darker(rowItem.player, 3)
                    border.width: 1
                    border.color: Theme.edgeDark
                    Image {
                        anchors.centerIn: parent
                        width: 14
                        height: 14
                        sourceSize: Qt.size(28, 28)
                        source: list.iconFor(rowItem.modelData)
                    }
                }

                // Título
                Text {
                    anchors {
                        left: mini.right
                        leftMargin: 8
                        right: wsLabel.left
                        rightMargin: 6
                        verticalCenter: parent.verticalCenter
                    }
                    text: rowItem.modelData.title
                    elide: Text.ElideRight
                    color: rowItem.isActive ? Theme.text : Theme.textSoft
                    font.pixelSize: 12
                    font.bold: rowItem.isActive
                }

                // Escritorio (donde Dota pone los números)
                Text {
                    id: wsLabel
                    anchors {
                        right: parent.right
                        rightMargin: 8
                        verticalCenter: parent.verticalCenter
                    }
                    text: list.numerals[rowItem.wsId - 1] ?? String(rowItem.wsId)
                    color: Theme.goldLight
                    font.pixelSize: 11
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (rowItem.modelData.wayland)
                        rowItem.modelData.wayland.activate()
                }
            }
        }
    }
}
