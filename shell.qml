// ancient — shell de Quickshell creado con 'duran new'
import Quickshell
import Quickshell.Io
import QtQuick
import "modules/bar/"

ShellRoot {
    id: root
    property bool barVisible: true

    Variants {
        model: Quickshell.screens

        Scope {
            id: perScreen
            required property var modelData

            Bar {
                modelData: perScreen.modelData
                visible: root.barVisible
            }
            WindowList {
                modelData: perScreen.modelData
            }
        }
    }

    // duran ipc bar
    IpcHandler {
        target: "bar"
        function toggle(): void {
            root.barVisible = !root.barVisible;
        }
    }
}
