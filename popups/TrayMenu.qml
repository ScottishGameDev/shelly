import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import "../theme"
import "../components"

PanelWindow {
    id: root

    property var menu: null
    property real anchorX: 0
    property real anchorY: 0
    

    screen: Quickshell.screens[0]
    anchors { top: true; left: true }
    margins {
        top: anchorY
        left: Math.max(4, anchorX)
    }
    implicitWidth: menuCol.implicitWidth + 2
    implicitHeight: menuCol.implicitHeight + 2
    color: "transparent"
    visible: false
    exclusionMode: ExclusionMode.Ignore

    Connections {
        target: Bus
        function onTrayMenuRequested(scr, x, y, m) {
            root.screen = scr
            root.anchorX = x
            root.anchorY = y
            var isIterable = m && (m.length !== undefined || m.count !== undefined)
            console.log("TrayMenu requested: menu type=", typeof m, "iterable=", isIterable)
            if (!isIterable) {
                root.menu = null
                root.visible = false
                return
            }
            root.menu = m
            console.log("TrayMenu requested: menu type=", typeof m, "len=", m ? (m.length !== undefined ? m.length : (m.count !== undefined ? m.count : "?")) : "null")
            root.visible = true
        }
    }

    // Close on click outside
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    PopupSurface {
        anchors.fill: parent
        focus: root.visible

        Keys.onPressed: {
            if (event.key === Qt.Key_Escape) {
                root.visible = false
                event.accepted = true
            }
        }

        Column {
            id: menuCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            padding: 1
            spacing: 0

            Repeater {
                model: root.menu
                delegate: Item {
                    id: row
                    property bool hasModel: modelData !== null && modelData !== undefined
                    property bool isSep: hasModel && modelData.isSeparator === true
                    property bool enabledFlag: hasModel && modelData.enabled === true
                    property string textString: hasModel && modelData.text !== undefined ? modelData.text : ""

                    visible: hasModel && !isSep
                    implicitWidth: rowText ? rowText.implicitWidth + Theme.chipPadH * 2 : 0
                    implicitHeight: hasModel ? (isSep ? 9 : Theme.barHeight - 16) : 0

                    Rectangle {
                        anchors.fill: parent
                        color: rowHover.hovered ? Theme.bgHi : "transparent"
                    }

                    HoverHandler { id: rowHover }

                    Text {
                        id: rowText
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.chipPadH
                        text: textString
                        color: !enabledFlag
                            ? Theme.chrome
                            : rowHover.hovered ? Theme.controlHoverFg : Theme.controlFg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.sizeReadout
                        font.weight: Theme.fontWeight
                    }

                    TapHandler {
                        enabled: enabledFlag && !isSep
                        onTapped: {
                            if (hasModel && typeof modelData.triggered === 'function') modelData.triggered()
                            root.visible = false
                        }
                    }
                }
            }
        }
    }

    // Tap outside to dismiss
    TapHandler {
        onTapped: root.visible = false
    }
}