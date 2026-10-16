import QtQuick
import "../../config"
import "../../services"

// Chip "sonando ahora" en la franja
Rectangle {
    id: chip
    visible: Media.active
    width: row.implicitWidth + 12
    height: 24
    border.width: 1
    border.color: ShellState.mediaOpen ? Theme.accentLight : Theme.accent
    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop {
            position: 0
            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22)
        }
        GradientStop {
            position: 1
            color: Qt.rgba(0, 0, 0, 0.35)
        }
    }

    Row {
        id: row
        x: 2
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        // Mini portada
        Rectangle {
            width: 30
            height: 18
            color: Theme.slot
            border.width: 1
            border.color: Theme.edgeDark
            clip: true
            Image {
                anchors.fill: parent
                anchors.margins: 1
                source: Media.player ? Media.player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(60, 60)
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Media.player && Media.player.isPlaying ? "❚❚" : "▶"
            color: Theme.accentLight
            font.pixelSize: 9
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 200)
            elide: Text.ElideRight
            text: Media.player ? Media.player.trackTitle : ""
            color: Theme.text
            font.pixelSize: 13
            font.bold: true
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 140)
            elide: Text.ElideRight
            text: Media.player && Media.player.trackArtist ? "· " + Media.player.trackArtist : ""
            color: Theme.textMute
            font.pixelSize: 12
        }

        // Barrita de progreso
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 60
            height: 3
            color: Theme.edgeDark
            Rectangle {
                width: parent.width * Media.progress
                height: parent.height
                color: Theme.accent
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: e => {
            if (e.button === Qt.MiddleButton)
                Media.toggle();
                // clic central: play/pausa
            else
                ShellState.mediaOpen = !ShellState.mediaOpen;         // clic: abrir panel
        }
        onWheel: w => w.angleDelta.y > 0 ? Media.previous() : Media.next()
    }
}
