import QtQuick
import "../../config"

// Combinación dibujada como teclas: SUPER + V
Row {
    id: kchips
    property string combo
    property color edge: Theme.edge
    spacing: 3

    Repeater {
        model: kchips.combo === "" ? [] : kchips.combo.split(" + ")
        Row {
            required property string modelData
            required property int index
            spacing: 3
            Text {
                visible: index > 0
                anchors.verticalCenter: parent.verticalCenter
                text: "+"
                color: Theme.label
                font.family: "monospace"
                font.pixelSize: 11
                font.bold: true
            }
            Rectangle {
                width: kt.implicitWidth + 14
                height: 22
                color: "#0b0d10"
                border.width: 1
                border.color: kchips.edge
                Text {
                    id: kt
                    anchors.centerIn: parent
                    text: modelData
                    color: Theme.text
                    font.family: "monospace"
                    font.pixelSize: 11
                    font.bold: true
                }
            }
        }
    }
}
