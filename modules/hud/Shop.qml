import QtQuick
import "../../config"
import "../../services"
import "../common"

// Tienda: oro = actualizaciones; SHOP = Armería; Quick buy = actualizar
Rectangle {
    width: 260
    height: 150
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
            margins: 6
            bottomMargin: 0
        }
        shade: 0.35
        border.width: 1
        border.color: Theme.edgeDark

        Column {
            anchors {
                fill: parent
                margins: 10
            }
            spacing: 8

            Row {
                width: parent.width
                height: 40
                spacing: 6

                // Oro
                Rectangle {
                    width: parent.width - 92
                    height: 40
                    color: Qt.rgba(0, 0, 0, 0.5)
                    border.width: 1
                    border.color: Theme.edge
                    Row {
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14
                            height: 14
                            radius: 7
                            color: "#f0c75e"
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Updates.count
                            color: "#f0c75e"
                            font.family: "monospace"
                            font.pixelSize: 18
                            font.bold: true
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Updates.count === 1 ? "actualización" : "actualizaciones"
                            color: Theme.textMute
                            font.pixelSize: 11
                        }
                    }
                }

                // SHOP → Armería
                Rectangle {
                    width: 86
                    height: 40
                    border.width: 1
                    border.color: Theme.edgeDark
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: Theme.accent
                        }
                        GradientStop {
                            position: 1
                            color: Qt.darker(Theme.accent, 1.8)
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "SHOP"
                        color: "#0a0c0e"
                        font.pixelSize: 15
                        font.bold: true
                        font.letterSpacing: 1.5
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ShellState.armoryOpen = true
                    }
                }
            }

            // Quick buy → actualizar
            Rectangle {
                width: parent.width
                height: parent.height - 48
                color: quickArea.containsMouse && Updates.count > 0 ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
                border.width: 1
                border.color: Theme.edge
                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    text: "<font color='" + Theme.accentLight + "'><b>QUICK BUY</b></font>&nbsp;&nbsp;" + (Updates.count > 0 ? "Actualizar sistema" : "Sistema al día")
                    textFormat: Text.StyledText
                    color: Theme.textSoft
                    font.pixelSize: 12
                }
                MouseArea {
                    id: quickArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: Updates.count > 0
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Updates.run()
                }
            }
        }
    }
}
