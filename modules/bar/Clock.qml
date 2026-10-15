import Quickshell
import QtQuick
import "../../config"

Text {
    // Reloj del sistema; se actualiza cada minuto
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    text: Qt.formatDateTime(clock.date, "HH:mm")
    color: Theme.text
    font.pixelSize: 16
    font.bold: true
}
