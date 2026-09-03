import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../components"

PanelWindow {
    id: root

    anchors { top: true; left: true }
    margins {
        left: root.screen
            ? (preferredLeftX + implicitWidth <= root.screen.width - 4
                ? preferredLeftX
                : Math.max(4, leftBoundaryX - implicitWidth))
            : 4
        top: root.screen
            ? Math.min(root.screen.height - implicitHeight - 4,
                       Math.max(Theme.barHeight + 4,
                                anchorY - implicitHeight / 2))
            : Theme.barHeight + 4
    }
    implicitWidth: 360
    implicitHeight: panel.implicitHeight + 24
    color: "transparent"
    visible: false
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    property real preferredLeftX: 0
    property real leftBoundaryX: 0
    property real anchorY: Theme.barHeight + 4
    property string title: "COLOR"
    property color colorValue: "#ffffff"
    property var editCallback: null

    function open(screen, nextPreferredLeftX, nextLeftBoundaryX, centerY,
                  pickerTitle, initialColor, callback) {
        root.screen = screen
        root.preferredLeftX = nextPreferredLeftX
        root.leftBoundaryX = nextLeftBoundaryX
        root.anchorY = centerY
        root.title = pickerTitle
        root.colorValue = initialColor
        root.editCallback = callback
        root.visible = true
        graceTimer.restart()
        Bus.colorPickerVisibilityChanged(true)
        Qt.callLater(function() { closeButton.forceActiveFocus() })
    }

    function close() {
        if (!root.visible) return
        root.visible = false
        root.editCallback = null
        Bus.colorPickerVisibilityChanged(false)
    }

    Component.onCompleted: {
        Bus.colorPickerRequested.connect(function(screen, nextPreferredLeftX,
                                                  nextLeftBoundaryX, centerY,
                                                  pickerTitle, initialColor,
                                                  callback) {
            root.open(screen, nextPreferredLeftX, nextLeftBoundaryX, centerY,
                      pickerTitle, initialColor, callback)
        })
        Bus.colorPickerDismissRequested.connect(root.close)
    }

    property bool inGrace: false
    Timer { id: graceTimer; interval: 1500; onTriggered: root.inGrace = false }
    onVisibleChanged: if (visible) inGrace = true

    HoverHandler {
        id: pickerHover
        onHoveredChanged: {
            if (hovered) pickerCloseTimer.stop()
            else pickerCloseTimer.restart()
        }
    }
    Timer {
        id: pickerCloseTimer
        interval: 400
        onTriggered: {
            if (!pickerHover.hovered && !root.inGrace) root.close()
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.close()
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
                    text: root.title.toUpperCase()
                    color: Theme.text
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.sizeLabel
                    font.weight: Theme.fontWeight
                }
                Chip {
                    id: closeButton
                    text: "X"
                    accessibleName: "Close color picker"
                    tooltip: "Close"
                    bracketed: false
                    showBorder: false
                    showCorners: false
                    fontSize: Theme.sizeLabel
                    onClicked: root.close()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.chromeDim
            }

            ColorPicker {
                Layout.fillWidth: true
                colorValue: root.colorValue
                onColorEdited: function(nextColor) {
                    root.colorValue = nextColor
                    if (typeof root.editCallback === "function")
                        root.editCallback(nextColor)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Chip {
                    text: "DONE"
                    accessibleName: "Finish choosing color"
                    bracketed: false
                    showCorners: false
                    fontSize: Theme.sizeMarker
                    onClicked: root.close()
                }
            }
        }
    }
}