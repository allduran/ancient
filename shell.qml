// ancient — shell de Quickshell creado con 'duran new'
import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {
    id: root
    property bool barVisible: true

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.barVisible
            anchors { top: true; left: true; right: true }
            implicitHeight: 32
            color: "#16161e"

            Text {
                anchors.centerIn: parent
                text: "ancient"
                color: "#c0caf5"
                font.pixelSize: 14
            }
        }
    }

    // duran ipc bar
    IpcHandler {
        target: "bar"
        function toggle(): void { root.barVisible = !root.barVisible }
    }
}
