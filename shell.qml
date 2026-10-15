// ancient — shell de Quickshell creado con 'duran new'
import Quickshell
import Quickshell.Io
import QtQuick
import "modules/bar/"
import "modules/notifications"
import "modules/capture"
import "modules/osd"
import "services"

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
            RegionSelector {
                modelData: perScreen.modelData
            }
        }
    }

    // Popups de notificación (uno solo, en el monitor enfocado)
    NotificationPopups {}
    Osd {}

    // duran ipc bar
    IpcHandler {
        target: "bar"
        function toggle(): void {
            root.barVisible = !root.barVisible;
        }
    }

    // duran ipc notifs_clear
    IpcHandler {
        target: "notifs"
        function clear(): void {
            Notifs.clearAll();
        }
    }

    // duran ipc shot_* / rec_*
    IpcHandler {
        target: "capture"
        function screen(): void {
            Capture.run("screen");
        }
        function region(): void {
            Capture.startSelect("area");
        }
        function window(): void {
            Capture.run("window");
        }
        function record(): void {
            Capture.startSelect("record-area");
        }
        function recordScreen(): void {
            Capture.run("record-screen");
        }
        function recordSound(): void {
            Capture.run("record-sound");
        }
    }

    // duran ipc volume_* / bright_*
    IpcHandler {
        target: "osd"
        function volumeUp(): void {
            Audio.up();
        }
        function volumeDown(): void {
            Audio.down();
        }
        function mute(): void {
            Audio.toggleMute();
        }
        function brightnessUp(): void {
            Brightness.up();
        }
        function brightnessDown(): void {
            Brightness.down();
        }
    }
}
