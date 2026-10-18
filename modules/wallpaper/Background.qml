import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../services"

// Fondo de escritorio: lo pinta ancient (sin hyprpaper ni swww), con fundido al cambiar
PanelWindow {
    id: bg
    required property var modelData
    screen: modelData

    WlrLayershell.namespace: "ancient-wallpaper"
    WlrLayershell.layer: WlrLayer.Background
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "#0a0c0e"

    readonly property string src: Wallpapers.current !== "" ? "file://" + Wallpapers.current : ""
    property bool aFront: true          // qué imagen está delante
    property string loading: ""         // "a" | "b" mientras carga la nueva

    // La nueva se carga detrás y, cuando está lista, pasa delante con un fundido
    onSrcChanged: {
        if (aFront) {
            loading = "b";
            b.source = src;
        } else {
            loading = "a";
            a.source = src;
        }
    }

    Component.onCompleted: a.source = src

    component Layer: Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        sourceSize: Qt.size(bg.modelData.width, bg.modelData.height)
        Behavior on opacity {
            NumberAnimation {
                duration: 600
                easing.type: Easing.InOutQuad
            }
        }
    }

    Layer {
        id: a
        opacity: bg.aFront ? 1 : 0
        onStatusChanged: if (status === Image.Ready && bg.loading === "a") {
            bg.aFront = true;
            bg.loading = "";
        }
    }
    Layer {
        id: b
        opacity: bg.aFront ? 0 : 1
        onStatusChanged: if (status === Image.Ready && bg.loading === "b") {
            bg.aFront = false;
            bg.loading = "";
        }
    }
}
