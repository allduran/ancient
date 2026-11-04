import QtQuick
import "../../config"

// Pestaña de la columna del héroe en Ajustes (talentos, atajos, sistema…)
Rectangle {
    id: pt
    property string label
    property string sub
    property bool active
    signal clicked

    height: 40
    border.width: active ? 2 : 1
    border.color: active ? Theme.accentLight : (ptArea.containsMouse ? Theme.accent : Theme.edge)
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

    Text {
        x: 14
        anchors.verticalCenter: parent.verticalCenter
        text: pt.label
        color: pt.active ? Theme.text : Theme.textSoft
        font.pixelSize: 14
        font.bold: true
        font.letterSpacing: 2
    }
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: pt.sub
        color: Theme.textMute
        font.pixelSize: 11
    }
    MouseArea {
        id: ptArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: pt.clicked()
    }
}
