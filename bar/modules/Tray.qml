import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import "../../theme"
import "../../components"
import "../../popups"
import "../../services"


// SYS :: [CTLR] [VOL] [WS2] [SETTINGS] <standard tray icons>
RowLayout {
    id: root
    spacing: 8
    property var trayHideList: ["spotify"]

    LabelCode { code: "SYS" }

    // ── Controller bluetooth status ───────────────────────
    Process {
        id: ctlPoll
        command: ["bash", Paths.script("controller_status.sh"), Config.controllerAddress]
        running: Config.controllerEnabled
        stdout: StdioCollector { onStreamFinished: ctl.connected = (text.trim() === "1") }
    }
    Timer {
        interval: 1500; running: Config.controllerEnabled; repeat: true
        onTriggered: ctlPoll.running = true
    }
    Chip {
        id: ctl
        visible: Config.controllerEnabled
        property bool connected: false
        text: connected ? "CTLR ▸ ON" : "CTLR ▸ ––"
        bracketed: false
        showBorder: false
        showCorners: Theme.controllerCorners
        onClicked: if (connected) ctlAction.running = true
    }
    Process {
        id: ctlAction
        command: ["bash", Paths.script("controller_disconnect.sh"), Config.controllerAddress]
    }

    // ── Audio mixer shortcut ──────────────────────────────────────
    Chip {
        id: volChip
        text: "VOL \u25B8 MIX"
        bracketed: false
        showBorder: false
        showCorners: Theme.volumeCorners
        onClicked: vuctl.running = true
        onRightClicked: {
            let p = volChip.mapToItem(null, volChip.width / 2, 0)
            Bus.showRequested(volChip.QsWindow.window.screen, p.x)
        }
    }
    Process {
        id: vuctl
        command: Config.volumeCommand
    }

    // ── WS2 dropdown ──────────────────────────────────────
    Chip {
        id: ws2Chip
        visible: Config.workspace2Enabled
        text: "WS2 \u25BE"
        bracketed: false
        showBorder: false
        showCorners: Theme.workspace2Corners
        onClicked: {
            let p = ws2Chip.mapToItem(null, ws2Chip.width / 2, 0)
            Bus.ws2MenuRequested(ws2Chip.QsWindow.window.screen, p.x)
        }
        onRightClicked: {
            let p = ws2Chip.mapToItem(null, ws2Chip.width / 2, 0)
            Bus.ws2MenuRequested(ws2Chip.QsWindow.window.screen, p.x)
        }
    }

    // ── Consolidated controls ────────────────────────────
    Chip {
        id: controlCenterChip
        text: "⚙"
        accessibleName: "Open control center"
        tooltip: "Control center"
        bracketed: false
        showBorder: false
        showCorners: Theme.settingsCorners
        onClicked: {
            let p = controlCenterChip.mapToItem(null, controlCenterChip.width / 2, 0)
            Bus.controlCenterRequested(controlCenterChip.QsWindow.window.screen, p.x)
        }
    }

    // ── Standard SNI tray icons ───────────────────────────
    // Block-list: items whose id matches any of these substrings are hidden.
    // Spotify is filtered because it ships a broken pixmap and we already
    // surface its state via the Music module.
    Rectangle {
        implicitWidth: nativeTrayRow.implicitWidth > 0 ? nativeTrayRow.implicitWidth + 8 : 0
        implicitHeight: Theme.barHeight - 4
        visible: implicitWidth > 0
        color: Theme.trayBg
        border.width: 0
        radius: Theme.controlRadius

        DashFrame {
            anchors.fill: parent
            visible: Theme.systemTrayFrameVisible
            dashed: Theme.systemTrayFrameDashed
            pad: 0
        }

        Row {
            id: nativeTrayRow
            anchors.centerIn: parent

            Repeater {
                model: SystemTray.items
                delegate: Item {
            id: trayItem
            required property SystemTrayItem modelData
            readonly property bool hidden: {
                const id = (modelData.id || "").toLowerCase()
                for (let i = 0; i < root.trayHideList.length; i++) {
                    if (id.indexOf(root.trayHideList[i]) !== -1) return true
                }
                return false
            }
            visible: !hidden
            implicitWidth:  hidden ? 0 : Theme.barHeight - 12
            implicitHeight: hidden ? 0 : Theme.barHeight - 12

            Image {
                anchors.fill: parent
                anchors.margins: 4
                source: modelData.icon
                sourceSize.width: parent.width - 8
                sourceSize.height: parent.height - 8
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            // Add this inside your Repeater delegate, alongside the Image
            QsMenuAnchor {
                id: menuAnchor
                menu: modelData.menu
                anchor.window: trayItem.QsWindow.window
                anchor.rect: {
                    let win = trayItem.QsWindow.window
                    let p = trayItem.mapToItem(win.contentItem, 0, 0)
                    return Qt.rect(p.x - 50, p.y + trayItem.height, trayItem.width, trayItem.height)
                }
            }

            TrayMenu { id: trayMenu }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: function(m) {
                    if (m.button === Qt.RightButton && modelData.hasMenu) {
                        var mm = modelData.menu
                        if (!mm) {
                            console.log("Tray: right-click; menu is null")
                        } else {
                            console.log("Tray: right-click; menu type=", typeof mm, "len=", mm.length !== undefined ? mm.length : (mm.count !== undefined ? mm.count : "?"))
                        }
                        let win = trayItem.QsWindow.window
                        let p = trayItem.mapToItem(win.contentItem, 0, 0)
                        var isIterable = mm && (mm.length !== undefined || mm.count !== undefined)
                        if (!isIterable) {
                            console.log("tray not iterable")
                            try {
                                if (menuAnchor.menu && typeof menuAnchor.menu.open === 'function') {
                                    menuAnchor.menu.open()
                                    console.log("menuAnchor.menu.open()")
                                } else if (typeof menuAnchor.open === 'function') {
                                    menuAnchor.open()
                                    console.log("menuAnchor.open()")
                                } else {
                                    console.log("Tray: native menu present but cannot open via anchor, falling back to TrayMenu")
                                    Bus.trayMenuRequested(win.screen, p.x, p.y + trayItem.height, modelData.menu)
                                    console.log("menuAnchor.menu.open()")
                                }
                            } catch (e) {
                                console.log("Tray: error opening native menu:", e)
                                Bus.trayMenuRequested(win.screen, p.x, p.y + trayItem.height, modelData.menu)
                            }
                        } else {
                            Bus.trayMenuRequested(win.screen, p.x, p.y + trayItem.height, modelData.menu)
                        }
                    } else {
                        modelData.activate()
                    }
                }
            }
                }
            }
        }
    }
}
