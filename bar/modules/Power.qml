import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../theme"
import "../../components"

// Power button: opens PowerMenu via signal bus.
Item {
    id: root
    implicitWidth: btn.implicitWidth
    implicitHeight: Theme.barHeight

    Chip {
        id: btn
        anchors.verticalCenter: parent.verticalCenter
        text: "⏻"
        bracketed: false
        showBorder: false
        showCorners: Theme.powerCorners
        fontSize: 32
        onClicked: {
            let p = btn.mapToItem(null, btn.width / 2, 0)
            Bus.powerMenuRequested(btn.QsWindow.window.screen, p.x)
        }
        onRightClicked: {
            let p = btn.mapToItem(null, btn.width / 2, 0)
            Bus.powerMenuRequested(btn.QsWindow.window.screen, p.x)
        }
    }
}
