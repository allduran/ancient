import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../config"
import "../../services"

// OSD de volumen y brillo, estilo barra de maná de Dota
PanelWindow {
    id: osd
    WlrLayershell.namespace: "ancient-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    anchors.bottom: true                  // solo abajo → centrado horizontalmente
    margins {
        bottom: 140
    }
    implicitWidth: 320
    implicitHeight: 48
    color: "transparent"
    visible: shown

    property bool shown: false
    property bool armed: false            // ignora los cambios al arrancar el shell
    property string kind: "volume"

    readonly property bool isVolume: kind === "volume"
    readonly property real level: isVolume ? Audio.volume : Brightness.value
    readonly property bool off: isVolume && Audio.muted

    function show(k) {
        if (!armed)
            return;
        kind = k;
        shown = true;
        hideTimer.restart();
    }

    Timer {
        interval: 1500
        running: true
        onTriggered: osd.armed = true
    }
    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: osd.shown = false
    }

    // Aparece cuando cambia algo, venga de donde venga
    Connections {
        target: Audio
        function onVolumeChanged() {
            osd.show("volume");
        }
        function onMutedChanged() {
            osd.show("volume");
        }
    }
    Connections {
        target: Brightness
        function onValueChanged() {
            osd.show("brightness");
        }
    }

    Rectangle {
        anchors.fill: parent
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

        // Filo dorado superior
        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: 2
            color: Theme.accent
        }

        // Hueco con el icono
        Rectangle {
            id: slot
            x: 6
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            height: 36
            color: Theme.slot
            border.width: 1
            border.color: Theme.edgeDark

            Text {
                anchors.centerIn: parent
                text: osd.isVolume ? (osd.off ? "✕" : "♪") : "☀"
                color: osd.off ? Theme.textMute : osd.isVolume ? Theme.text : Theme.accentLight
                font.pixelSize: 18
                font.bold: true
            }
        }

        // Barra
        Rectangle {
            id: track
            anchors {
                left: slot.right
                leftMargin: 8
                right: parent.right
                rightMargin: 10
                verticalCenter: parent.verticalCenter
            }
            height: 20
            color: Theme.slot
            border.width: 1
            border.color: Theme.edgeDark

            Rectangle {
                x: 1
                y: 1
                height: parent.height - 2
                width: (parent.width - 2) * Math.max(0, Math.min(1, osd.level))
                Behavior on width {
                    NumberAnimation {
                        duration: 120
                    }
                }
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: osd.off ? "#555555" : osd.isVolume ? Theme.manaTop : Theme.day
                    }
                    GradientStop {
                        position: 1
                        color: osd.off ? "#333333" : osd.isVolume ? Theme.manaBot : Qt.darker(Theme.day, 1.8)
                    }
                }

                // Brillo superior
                Rectangle {
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.25)
                }
            }

            // Divisiones cada 10 %
            Repeater {
                model: 9
                Rectangle {
                    required property int index
                    x: (index + 1) * track.width / 10
                    width: 1
                    height: track.height
                    color: Qt.rgba(0, 0, 0, 0.35)
                }
            }

            Text {
                anchors.centerIn: parent
                text: osd.off ? "MUTE" : Math.round(osd.level * 100) + " / 100"
                color: "white"
                font.pixelSize: 12
                font.bold: true
                style: Text.Outline
                styleColor: "#000000"
            }
        }
    }
}
