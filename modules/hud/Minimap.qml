import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../../config"
import "../../services"

// Minimapa: escritorios del grupo actual con sus ventanas dibujadas a escala
Rectangle {
    id: map
    width: 250
    height: 236
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

    readonly property var mon: Hyprland.focusedMonitor
    readonly property int activeId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    readonly property int base: activeId > 0 ? Math.floor((activeId - 1) / 5) * 5 : 0
    readonly property var numerals: ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]

    // Ventanas de un escritorio (special = todas las de id negativo)
    function windowsOf(id) {
        return Hyprland.toplevels.values.filter(t => t.workspace && t.lastIpcObject.at && (id < 0 ? t.workspace.id < 0 : t.workspace.id === id));
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 6
        color: "#0c140e"
        border.width: 1
        border.color: Theme.edgeDark

        Grid {
            anchors.fill: parent
            anchors.margins: 6
            columns: 3
            spacing: 4

            Repeater {
                model: 6

                Rectangle {
                    id: tile
                    required property int index
                    readonly property int wsId: index < 5 ? map.base + index + 1 : -1
                    readonly property bool isActive: wsId === map.activeId
                    readonly property color player: Theme.playerColors[index % 5]

                    width: (parent.width - 8) / 3
                    height: (parent.height - 4) / 2
                    clip: true
                    color: isActive ? Qt.rgba(player.r, player.g, player.b, 0.12) : "transparent"
                    border.width: 1
                    border.color: isActive ? Theme.text : "#2a3a2a"

                    // Ventanas a escala
                    Repeater {
                        model: map.mon ? map.windowsOf(tile.wsId) : []
                        Rectangle {
                            required property var modelData
                            x: (modelData.lastIpcObject.at[0] - map.mon.x) / map.mon.width * tile.width
                            y: (modelData.lastIpcObject.at[1] - map.mon.y) / map.mon.height * tile.height
                            width: modelData.lastIpcObject.size[0] / map.mon.width * tile.width
                            height: modelData.lastIpcObject.size[1] / map.mon.height * tile.height
                            color: Qt.rgba(tile.player.r, tile.player.g, tile.player.b, 0.4)
                            border.width: 1
                            border.color: Qt.rgba(tile.player.r, tile.player.g, tile.player.b, 0.8)
                        }
                    }

                    Text {
                        anchors {
                            left: parent.left
                            bottom: parent.bottom
                            leftMargin: 3
                            bottomMargin: 1
                        }
                        text: tile.wsId < 0 ? "S" : (map.numerals[tile.wsId - 1] ?? tile.wsId)
                        color: tile.isActive ? Theme.text : Theme.textMute
                        font.family: "monospace"
                        font.pixelSize: 9
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: tile.wsId > 0
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Settings.focusWorkspace(tile.wsId)
                    }
                }
            }
        }
    }
}
