import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls as Controls
import "../theme"

// Interactive terminal-style chip with hard-step hover invert.
// Use for: workspaces, FCST, power options, media controls, +WS.
Rectangle {
    id: root

    property string text: ""
    property string accessibleName: text
    property string tooltip: ""
    property color  fg: Theme.controlFg
    property color  bg: "transparent"
    property color  fgHover: Theme.controlHoverFg
    property color  bgHover: Theme.controlHoverBg
    property bool   active: false      // sticky highlighted state
    property bool   bracketed: true    // wrap text in [ ... ]
    property bool   showBorder: true   // set false to suppress the outline box
    property bool   showCorners: false  // corner-bracket framing instead of full border
    property int    padH: Theme.chipPadH
    property int    padV: Theme.chipPadV
    property int    fontSize: Theme.sizeReadout

    signal clicked(var mouse)
    signal rightClicked(var mouse)

    activeFocusOnTab: enabled
    Accessible.role: Accessible.Button
    Accessible.name: accessibleName
    Accessible.description: tooltip

    color: tap.pressed ? Theme.bgHi
                       : hover.hovered ? bgHover
                       : active ? Theme.controlActiveBg : bg
    border.color: activeFocus ? Theme.controlFocus
                              : active ? Theme.amberHi : Theme.controlBorder
    border.width: showBorder || activeFocus ? Theme.controlBorderWidth : 0
    radius: Theme.controlRadius
    implicitHeight: Theme.barHeight - 8
    implicitWidth:  label.implicitWidth  + padH * 2
    opacity: enabled ? 1.0 : 0.48

    HoverHandler { id: hover }

    TapHandler {
        id: tap
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onTapped: function(eventPoint, button) {
            root.forceActiveFocus()
            if (button === Qt.RightButton) root.rightClicked(eventPoint)
            else root.clicked(eventPoint)
        }
    }

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.clicked(null)
            event.accepted = true
        }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.bracketed ? ("[ " + root.text + " ]") : root.text
        color: hover.hovered ? root.fgHover
                             : active ? Theme.controlActiveFg : root.fg
        font.family: Theme.fontFamily
        font.pixelSize: root.fontSize
        font.letterSpacing: 1.0
        font.weight: Theme.fontWeight
    }

    Rectangle {
        id: tooltipItem
        parent: Controls.Overlay.overlay
        visible: root.tooltip.length > 0 && hover.hovered
        enabled: false
        width: tooltipText.implicitWidth + 12
        height: tooltipText.implicitHeight + 8
        z: 10000
        color: Theme.bgElev
        border.color: Theme.chrome
        border.width: 1
        radius: Theme.controlRadius
        readonly property point cursorPosition: root.mapToItem(
            tooltipItem.parent, hover.point.position.x, hover.point.position.y)
        x: Math.min(cursorPosition.x + 16, parent.width - width - 4)
        y: Math.min(cursorPosition.y + 18, parent.height - height - 4)

        Text {
            id: tooltipText
            anchors.centerIn: parent
            text: root.tooltip
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.sizeMarker
            font.weight: Theme.fontWeight
        }
    }

    // External amber halo when active (rendered as drop-shadow on the rect)
    layer.enabled: root.active

    CornerBracket {
        anchors.fill: parent
        visible: root.showCorners
        color: root.active ? Theme.amberHi : Theme.chrome
        armLength: Theme.cornerArmLength
        z: 2
    }
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Theme.amberHi
        shadowOpacity: 0.95
        shadowBlur: 1.0
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
        blurMax: 24
    }
}
