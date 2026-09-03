import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"
import "../components"

// Nostromo-style power readout panel.
PanelWindow {
    id: root

    anchors { top: true; left: true }
    margins { top: Theme.barHeight + 4; left: Math.min(screen.width - implicitWidth - 4, Math.max(4, anchorX - implicitWidth / 2)) }
    implicitWidth: 130
    implicitHeight: panel.implicitHeight + 24
    color: "transparent"
    visible: false
    exclusionMode: ExclusionMode.Ignore

    property real anchorX: 0

    function open() { visible = true; graceTimer.restart() }
    function close() { visible = false }

    Component.onCompleted: {
        Bus.powerMenuRequested.connect(function(scr, cx) {
            root.screen = scr
            root.anchorX = cx
            root.open()
        })
    }

    property bool inGrace: false
    Timer { id: graceTimer; interval: 1500; onTriggered: root.inGrace = false }
    onVisibleChanged: if (visible) inGrace = true

    HoverHandler {
        id: hover
        onHoveredChanged: if (!hovered) closeTimer.restart()
    }
    Timer {
        id: closeTimer
        interval: 400
        onTriggered: if (!hover.hovered && !root.inGrace) root.close()
    }

    PopupSurface {
        id: panel
        anchors.fill: parent
        anchors.margins: 12
        implicitHeight: col.implicitHeight + 20

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            SectionHeader {
                Layout.alignment: Qt.AlignHCenter
                title: "System"
            }

            Repeater {
                model: [
                    { code: "PWR", label: "POWEROFF", cmd: "systemctl poweroff" },
                    { code: "RST", label: "REBOOT",   cmd: "systemctl reboot" },
                    { code: "EXT", label: "LOGOUT",   cmd: "hyprctl dispatch exit" }
                ]
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: rowLayout.implicitHeight + 8
                    color: rowHover.hovered ? Theme.controlHoverBg : "transparent"
                    border.color: modelData.code === "PWR" ? Theme.err : Theme.controlBorder
                    border.width: 1
                    radius: Theme.controlRadius

                    HoverHandler { id: rowHover }
                    TapHandler {
                        onTapped: {
                            cmdProc.command = ["sh", "-c", modelData.cmd]
                            cmdProc.running = true
                            root.close()
                        }
                    }

                    RowLayout {
                        id: rowLayout
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 10

                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: "[ " + modelData.code + " ]"
                            color: modelData.code === "PWR" && !rowHover.hovered
                                ? Theme.err
                                : rowHover.hovered ? Theme.controlHoverFg : Theme.controlFg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.sizeReadout
                            font.weight: Theme.fontWeight
                        }
                    }
                }
            }
        }
    }

    Process { id: cmdProc }
}
