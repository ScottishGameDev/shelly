import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"

PanelWindow {
    id: root

    anchors { top: true; left: true }
    margins {
        top: Theme.barHeight + 4
        left: root.screen
            ? Math.min(root.screen.width - implicitWidth - 4,
                       Math.max(4, anchorX - implicitWidth / 2))
            : 4
    }
    implicitWidth: 390
    implicitHeight: panel.implicitHeight + 24
    color: "transparent"
    visible: false
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    property real anchorX: 0

    function open() {
        visible = true
        graceTimer.restart()
        ModeService.modeState.reload()
        WallpaperService.freezeState.reload()
        Qt.callLater(function() { closeButton.forceActiveFocus() })
    }

    function close() {
        visible = false
    }

    function toggle() {
        if (visible) close()
        else open()
    }

    Component.onCompleted: {
        Bus.controlCenterRequested.connect(function(scr, cx) {
            root.screen = scr
            root.anchorX = cx
            root.toggle()
        })
    }

    property bool inGrace: false
    Timer { id: graceTimer; interval: 1500; onTriggered: root.inGrace = false }
    onVisibleChanged: if (visible) inGrace = true

    HoverHandler {
        id: controlHover
        onHoveredChanged: {
            if (hovered) controlCloseTimer.stop()
            else controlCloseTimer.restart()
        }
    }
    Timer {
        id: controlCloseTimer
        interval: 400
        onTriggered: {
            if (!controlHover.hovered && !root.inGrace) root.close()
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.close()
    }

    component SectionLabel: Text {
        color: Theme.teal
        font.family: Theme.fontFamily
        font.pixelSize: Theme.sizeLabel
        font.weight: Theme.fontWeight
        font.letterSpacing: Theme.labelLetterSpacing
    }

    component ThemeChoice: Rectangle {
        id: choice
        required property string themeId
        required property string label
        required property color swatch
        readonly property bool selected: Theme.currentThemeId === themeId
        signal chosen()

        activeFocusOnTab: true
        Accessible.role: Accessible.RadioButton
        Accessible.name: label + " theme"
        Accessible.checked: selected
        Layout.fillWidth: true
        implicitHeight: 38
        radius: Theme.controlRadius
        color: selected ? Theme.controlActiveBg
                        : choiceHover.hovered ? Theme.controlHoverBg : "transparent"
        border.color: activeFocus ? Theme.controlFocus
                                  : selected ? Theme.amberHi : Theme.controlBorder
        border.width: activeFocus ? 2 : 1

        HoverHandler { id: choiceHover }
        TapHandler {
            onTapped: {
                choice.forceActiveFocus()
                choice.chosen()
            }
        }
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                choice.chosen()
                event.accepted = true
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            Rectangle {
                implicitWidth: 18
                implicitHeight: 18
                radius: Theme.controlRadius
                color: choice.swatch
                border.color: Theme.chromeHi
                border.width: 1
            }
            Text {
                Layout.fillWidth: true
                text: choice.label
                color: choice.selected ? Theme.controlActiveFg : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.sizeLabel
                font.weight: Theme.fontWeight
            }
            Text {
                text: choice.selected ? "●" : "○"
                color: choice.selected ? Theme.amberHi : Theme.chrome
                font.family: Theme.fontFamily
                font.pixelSize: Theme.sizeLabel
            }
        }
    }

    PopupSurface {
        id: panel
        anchors.fill: parent
        anchors.margins: 12
        implicitHeight: content.implicitHeight + 28

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: Theme.variantId === "industrial" ? "CONTROL / 01" : "── CONTROL ──"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.sizeReadout
                    font.weight: Theme.fontWeight
                }
                Chip {
                    id: closeButton
                    text: "X"
                    accessibleName: "Close control center"
                    tooltip: "Close"
                    bracketed: false
                    showBorder: false
                    showCorners: false
                    fontSize: Theme.sizeLabel
                    onClicked: root.close()
                }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.chromeDim }

            SectionLabel { text: "OPERATING MODE" }
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Chip {
                    Layout.fillWidth: true
                    text: "DESKTOP"
                    accessibleName: "Desktop mode"
                    bracketed: false
                    showCorners: false
                    fontSize: Theme.sizeMarker
                    active: ModeService.currentMode === "0"
                    onClicked: ModeService.setMode("desk")
                }
                Chip {
                    Layout.fillWidth: true
                    text: "NOTIFICATIONS"
                    accessibleName: "Notifications mode"
                    bracketed: false
                    showCorners: false
                    fontSize: Theme.sizeMarker
                    active: ModeService.currentMode === "2"
                    onClicked: ModeService.setMode("notifications")
                }
                Chip {
                    Layout.fillWidth: true
                    text: "GAME"
                    accessibleName: "Game mode"
                    bracketed: false
                    showCorners: false
                    fontSize: Theme.sizeMarker
                    active: ModeService.currentMode === "1"
                    onClicked: ModeService.setMode("game")
                }
            }

            SectionLabel { text: "WALLPAPER" }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Chip {
                    text: "◀"
                    accessibleName: "Previous wallpaper"
                    tooltip: "Previous wallpaper"
                    bracketed: false
                    showCorners: false
                    onClicked: WallpaperService.previous()
                }
                Chip {
                    text: "▶"
                    accessibleName: "Next wallpaper"
                    tooltip: "Next wallpaper"
                    bracketed: false
                    showCorners: false
                    onClicked: WallpaperService.next()
                }
                Item { Layout.fillWidth: true }
                ToggleSwitch {
                    text: "AUTO-CYCLE"
                    checked: WallpaperService.autoCycle
                    onToggled: function(checked) { WallpaperService.setAutoCycle(checked) }
                }
            }

            SectionLabel { text: "THEME" }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ThemeChoice {
                    themeId: "cyberpunk"
                    label: "CYBERPUNK"
                    swatch: "#9b5cd9"
                    onChosen: Theme.selectTheme(themeId)
                }
                ThemeChoice {
                    themeId: "industrial"
                    label: "INDUSTRIAL"
                    swatch: "#b8d5cc"
                    onChosen: Theme.selectTheme(themeId)
                }
            }

            Chip {
                Layout.fillWidth: true
                text: "EDIT " + Theme.active.name.toUpperCase()
                      + (ThemeOverrideService.isCustomized(Theme.currentThemeId) ? "  •" : "")
                accessibleName: "Edit active theme colors"
                bracketed: false
                showCorners: false
                fontSize: Theme.sizeLabel
                onClicked: {
                    const screen = root.screen
                    const centerX = root.anchorX
                    root.close()
                    Bus.themeEditorRequested(screen, centerX)
                }
            }

            SectionLabel { text: "VISUAL EFFECTS" }
            RowLayout {
                Layout.fillWidth: true

                ToggleSwitch {
                    Layout.fillWidth: true
                    text: ModeService.gameMode ? "FX / GAME OVERRIDE" : "FX ENABLED"
                    accessibleName: "Visual effects"
                    checked: Fx.userEnabled
                    available: !ModeService.gameMode
                    onToggled: function(checked) { Fx.userEnabled = checked }
                }
                Text {
                    visible: ModeService.gameMode
                    text: "PAUSED"
                    color: Theme.warn
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.sizeMarker
                    font.weight: Theme.fontWeight
                }
            }
        }
    }
}