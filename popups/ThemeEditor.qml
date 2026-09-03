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
    implicitWidth: 430
    implicitHeight: root.screen
        ? Math.min(760, root.screen.height - Theme.barHeight - 12)
        : 700
    color: "transparent"
    visible: false
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    property real anchorX: 0
    property bool closingAfterSave: false
    property bool pickerOpen: false
    readonly property var colorFamilies: [
        { token: "bg", label: "SURFACES", variants: [
            { token: "bgElev", label: "ELEVATED" },
            { token: "bgHi", label: "HIGHLIGHT" }
        ] },
        { token: "text", label: "CONTENT", variants: [] },
        { token: "trayBg", label: "SYSTEM TRAY", variants: [] },
        { token: "amber", label: "ACCENT", variants: [
            { token: "amberHi", label: "HIGH" },
            { token: "amberDim", label: "DIM" }
        ] },
        { token: "chrome", label: "STRUCTURE", variants: [
            { token: "chromeHi", label: "HIGH" },
            { token: "chromeDim", label: "DIM" }
        ] },
        { token: "sun", label: "SOLAR / INFO", variants: [
            { token: "sunHi", label: "HIGH" },
            { token: "sunDim", label: "DIM" }
        ] },
        { token: "teal", label: "TELEMETRY", variants: [
            { token: "tealDim", label: "DIM" }
        ] },
        { token: "pink", label: "SECONDARY ACCENT", variants: [] },
        { token: "ok", label: "SUCCESS", variants: [] },
        { token: "warn", label: "WARNING", variants: [] },
        { token: "err", label: "ERROR", variants: [] },
        { token: "moon", label: "LUNAR", variants: [
            { token: "moonDim", label: "DIM" }
        ] },
        { token: "graphRx", label: "GRAPH / RECEIVE", variants: [] },
        { token: "graphTx", label: "GRAPH / TRANSMIT", variants: [] }
    ]

    function open(screen, centerX) {
        if (visible || ThemeOverrideService.saving) return
        root.screen = screen
        root.anchorX = centerX
        root.closingAfterSave = false
        if (!ThemeOverrideService.beginEdit(Theme.currentThemeId)) return
        visible = true
        graceTimer.restart()
        Qt.callLater(function() { closeButton.forceActiveFocus() })
    }

    function cancelAndClose() {
        if (ThemeOverrideService.saving) return
        Bus.colorPickerDismissRequested()
        ThemeOverrideService.cancel()
        visible = false
    }

    function finishSave() {
        root.closingAfterSave = true
        Bus.colorPickerDismissRequested()
        ThemeOverrideService.cancel()
        visible = false
    }

    Component.onCompleted: {
        Bus.themeEditorRequested.connect(function(screen, centerX) {
            root.open(screen, centerX)
        })
    }

    property bool inGrace: false
    Timer { id: graceTimer; interval: 1500; onTriggered: root.inGrace = false }
    onVisibleChanged: if (visible) inGrace = true

    HoverHandler {
        id: editorHover
        onHoveredChanged: {
            if (hovered) editorCloseTimer.stop()
            else if (!root.pickerOpen) editorCloseTimer.restart()
        }
    }
    Timer {
        id: editorCloseTimer
        interval: 400
        onTriggered: {
            if (!editorHover.hovered && !root.pickerOpen && !root.inGrace)
                root.cancelAndClose()
        }
    }

    Connections {
        target: Bus
        function onColorPickerVisibilityChanged(visible) {
            root.pickerOpen = visible
            if (visible) editorCloseTimer.stop()
        }
    }

    Connections {
        target: ThemeOverrideService
        function onSaveSucceeded() { root.finishSave() }
    }

    Connections {
        target: Theme
        function onCurrentThemeIdChanged() {
            if (root.visible
                    && Theme.currentThemeId !== ThemeOverrideService.editingThemeId)
                root.cancelAndClose()
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible && !ThemeOverrideService.saving
        onActivated: root.cancelAndClose()
    }

    PopupSurface {
        anchors.fill: parent
        anchors.margins: 12

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: Theme.variantId === "industrial" ? "THEME / EDIT" : "── THEME EDIT ──"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.sizeReadout
                        font.weight: Theme.fontWeight
                    }
                    Text {
                        text: Theme.active.name.toUpperCase()
                              + (ThemeOverrideService.dirty ? "  • UNSAVED" : "")
                        color: ThemeOverrideService.dirty ? Theme.warn : Theme.teal
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.sizeMarker
                        font.weight: Theme.fontWeight
                    }
                }

                Chip {
                    id: closeButton
                    text: "X"
                    accessibleName: "Cancel theme editing"
                    tooltip: "Cancel"
                    bracketed: false
                    showBorder: false
                    showCorners: false
                    fontSize: Theme.sizeLabel
                    enabled: !ThemeOverrideService.saving
                    onClicked: root.cancelAndClose()
                }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.chromeDim }

            Flickable {
                id: paletteScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: familyColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: familyColumn
                    width: paletteScroll.width
                    spacing: 10

                    ThemeShapeEditor {
                        Layout.fillWidth: true
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Theme.chromeDim
                    }

                    Repeater {
                        model: root.colorFamilies
                        delegate: ColumnLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 8

                            ColorTokenEditor {
                                Layout.fillWidth: true
                                token: modelData.token
                                label: modelData.label
                                variants: modelData.variants
                                pickerRightX: root.margins.left + root.implicitWidth + 8
                                pickerLeftBoundaryX: root.margins.left - 8
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 1
                                color: Theme.chromeDim
                            }
                        }
                    }
                }
            }

            Text {
                visible: ThemeOverrideService.errorMessage.length > 0
                Layout.fillWidth: true
                text: ThemeOverrideService.errorMessage
                color: Theme.err
                wrapMode: Text.Wrap
                font.family: Theme.fontFamily
                font.pixelSize: Theme.sizeMarker
                font.weight: Theme.fontWeight
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Chip {
                    text: "RESET THEME"
                    accessibleName: "Reset active theme colors"
                    bracketed: false
                    showCorners: false
                    fontSize: Theme.sizeMarker
                    enabled: !ThemeOverrideService.saving
                    onClicked: ThemeOverrideService.resetTheme()
                }
                Item { Layout.fillWidth: true }
                Chip {
                    text: "CANCEL"
                    accessibleName: "Cancel theme editing"
                    bracketed: false
                    showCorners: false
                    fontSize: Theme.sizeMarker
                    enabled: !ThemeOverrideService.saving
                    onClicked: root.cancelAndClose()
                }
                Chip {
                    text: ThemeOverrideService.saving ? "SAVING" : "SAVE"
                    accessibleName: "Save theme colors"
                    bracketed: false
                    showCorners: false
                    fontSize: Theme.sizeMarker
                    active: ThemeOverrideService.dirty
                    enabled: ThemeOverrideService.dirty && !ThemeOverrideService.saving
                    onClicked: ThemeOverrideService.save()
                }
            }
        }
    }
}