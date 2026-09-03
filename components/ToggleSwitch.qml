import QtQuick
import "../theme"

Item {
    id: root

    property string text: ""
    property string accessibleName: text
    property bool checked: false
    property bool available: true
    signal toggled(bool checked)

    activeFocusOnTab: enabled && available
    implicitWidth: 154
    implicitHeight: 34
    opacity: available ? 1.0 : 0.48

    Accessible.role: Accessible.CheckBox
    Accessible.name: accessibleName
    Accessible.checked: checked

    function toggle() {
        if (!available) return
        toggled(!checked)
    }

    HoverHandler { id: hover }
    TapHandler {
        enabled: root.available
        onTapped: {
            root.forceActiveFocus()
            root.toggle()
        }
    }
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.toggle()
            event.accepted = true
        }
    }

    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.sizeLabel
        font.weight: Theme.fontWeight
    }

    Rectangle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 42
        height: 22
        radius: Theme.controlRadius
        color: root.checked ? Theme.controlActiveBg : Theme.bgHi
        border.color: root.activeFocus ? Theme.controlFocus : Theme.controlBorder
        border.width: root.activeFocus ? 2 : 1

        Rectangle {
            width: 14
            height: 14
            radius: Theme.controlRadius
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - width - 4 : 4
            color: root.checked ? Theme.controlActiveFg : Theme.chromeHi

            Behavior on x {
                NumberAnimation { duration: Theme.durFast; easing.type: Easing.OutCubic }
            }
        }
    }
}