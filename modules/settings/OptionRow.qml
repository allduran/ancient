import QtQuick
import "../../config"

// Fila de ajuste: nombre (y pista) a la izquierda, opciones en botones a la derecha
Item {
    id: opt
    property string label
    property string hint: ""
    property var options: []            // [{ value, text }]
    property var value
    signal picked(var v)

    width: parent ? parent.width : 400
    height: 46

    Column {
        anchors.verticalCenter: parent.verticalCenter
        Text {
            text: opt.label
            color: Theme.text
            font.pixelSize: 14
            font.bold: true
        }
        Text {
            visible: opt.hint !== ""
            text: opt.hint
            color: Theme.textMute
            font.pixelSize: 11
        }
    }

    Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        Repeater {
            model: opt.options
            Rectangle {
                required property var modelData
                readonly property bool on: opt.value === modelData.value
                width: optText.implicitWidth + 18
                height: 28
                color: on ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.28) : Qt.rgba(0, 0, 0, 0.45)
                border.width: 1
                border.color: on ? Theme.accentLight : (optArea.containsMouse ? Theme.accent : Theme.edge)
                Text {
                    id: optText
                    anchors.centerIn: parent
                    text: modelData.text
                    color: parent.on ? Theme.text : Theme.textMute
                    font.pixelSize: 12
                    font.bold: true
                }
                MouseArea {
                    id: optArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: opt.picked(modelData.value)
                }
            }
        }
    }
}
