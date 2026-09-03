import QtQuick
import QtQuick.Layouts
import "../theme"

Item {
    id: root

    property color colorValue: "#ffffff"
    property real hue: 0
    property real saturation: 0
    property real brightness: 1
    property bool internalUpdate: false
    property color pendingColor: colorValue
    property bool hexValid: true
    signal colorEdited(color colorValue)

    implicitWidth: 300
    implicitHeight: pickerLayout.implicitHeight

    function clamp(value, minimum, maximum) {
        return Math.max(minimum, Math.min(maximum, value))
    }

    function channelHex(channel) {
        return Math.round(clamp(channel, 0, 1) * 255).toString(16).padStart(2, "0").toUpperCase()
    }

    function toHex(value) {
        return "#" + channelHex(value.r) + channelHex(value.g) + channelHex(value.b)
    }

    function syncFromColor() {
        if (internalUpdate) return
        const nextHue = colorValue.hsvHue
        if (nextHue >= 0) hue = nextHue
        saturation = colorValue.hsvSaturation
        brightness = colorValue.hsvValue
        if (!hexInput.activeFocus) hexInput.text = toHex(colorValue)
        hexValid = true
    }

    function queueColor() {
        internalUpdate = true
        colorValue = Qt.hsva(hue, saturation, brightness, 1)
        pendingColor = colorValue
        internalUpdate = false
        hexInput.text = toHex(colorValue)
        hexValid = true
        if (!previewTimer.running) previewTimer.start()
    }

    function commitHex() {
        const normalized = hexInput.text.trim().toUpperCase()
        if (!/^#[0-9A-F]{6}$/.test(normalized)) {
            hexValid = false
            return
        }
        hexValid = true
        internalUpdate = true
        colorValue = normalized
        pendingColor = colorValue
        internalUpdate = false
        syncFromColor()
        colorEdited(colorValue)
    }

    onColorValueChanged: syncFromColor()
    Component.onCompleted: syncFromColor()

    Timer {
        id: previewTimer
        interval: 16
        repeat: false
        onTriggered: root.colorEdited(root.pendingColor)
    }

    ColumnLayout {
        id: pickerLayout
        width: parent.width
        spacing: 8

        FocusScope {
            id: saturationValueControl
            Layout.fillWidth: true
            implicitHeight: 150
            activeFocusOnTab: true
            Accessible.role: Accessible.Slider
            Accessible.name: "Color saturation and brightness"
            Accessible.description: Math.round(root.saturation * 100) + "% saturation, "
                                    + Math.round(root.brightness * 100) + "% brightness"

            Rectangle {
                anchors.fill: parent
                color: Qt.hsva(root.hue, 1, 1, 1)
                radius: Theme.controlRadius
            }
            Rectangle {
                anchors.fill: parent
                radius: Theme.controlRadius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "#ffffff" }
                    GradientStop { position: 1; color: "#00ffffff" }
                }
            }
            Rectangle {
                anchors.fill: parent
                radius: Theme.controlRadius
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0; color: "#00000000" }
                    GradientStop { position: 1; color: "#ff000000" }
                }
                border.color: saturationValueControl.activeFocus ? Theme.controlFocus : Theme.controlBorder
                border.width: saturationValueControl.activeFocus ? 2 : 1
            }

            Rectangle {
                width: 12
                height: 12
                radius: 6
                x: root.saturation * (parent.width - width)
                y: (1 - root.brightness) * (parent.height - height)
                color: "transparent"
                border.color: root.brightness > 0.6 ? "#101010" : "#ffffff"
                border.width: 2
            }

            function setPosition(xPosition, yPosition) {
                root.saturation = root.clamp(xPosition / width, 0, 1)
                root.brightness = 1 - root.clamp(yPosition / height, 0, 1)
                root.queueColor()
            }

            MouseArea {
                anchors.fill: parent
                preventStealing: true
                onPressed: function(mouse) {
                    saturationValueControl.forceActiveFocus()
                    saturationValueControl.setPosition(mouse.x, mouse.y)
                }
                onPositionChanged: function(mouse) {
                    if (pressed) saturationValueControl.setPosition(mouse.x, mouse.y)
                }
            }

            Keys.onPressed: function(event) {
                const step = event.modifiers & Qt.ShiftModifier ? 0.05 : 0.01
                if (event.key === Qt.Key_Left) root.saturation = root.clamp(root.saturation - step, 0, 1)
                else if (event.key === Qt.Key_Right) root.saturation = root.clamp(root.saturation + step, 0, 1)
                else if (event.key === Qt.Key_Up) root.brightness = root.clamp(root.brightness + step, 0, 1)
                else if (event.key === Qt.Key_Down) root.brightness = root.clamp(root.brightness - step, 0, 1)
                else return
                root.queueColor()
                event.accepted = true
            }
        }

        FocusScope {
            id: hueControl
            Layout.fillWidth: true
            implicitHeight: 24
            activeFocusOnTab: true
            Accessible.role: Accessible.Slider
            Accessible.name: "Color hue"
            Accessible.description: Math.round(root.hue * 360) + " degrees"

            Rectangle {
                anchors.fill: parent
                radius: Theme.controlRadius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.00; color: "#ff0000" }
                    GradientStop { position: 0.17; color: "#ffff00" }
                    GradientStop { position: 0.33; color: "#00ff00" }
                    GradientStop { position: 0.50; color: "#00ffff" }
                    GradientStop { position: 0.67; color: "#0000ff" }
                    GradientStop { position: 0.83; color: "#ff00ff" }
                    GradientStop { position: 1.00; color: "#ff0000" }
                }
                border.color: hueControl.activeFocus ? Theme.controlFocus : Theme.controlBorder
                border.width: hueControl.activeFocus ? 2 : 1
            }

            Rectangle {
                width: 5
                height: parent.height + 4
                y: -2
                x: root.hue * (parent.width - width)
                color: "transparent"
                border.color: Theme.text
                border.width: 2
            }

            function setPosition(xPosition) {
                root.hue = root.clamp(xPosition / width, 0, 1)
                root.queueColor()
            }

            MouseArea {
                anchors.fill: parent
                preventStealing: true
                onPressed: function(mouse) {
                    hueControl.forceActiveFocus()
                    hueControl.setPosition(mouse.x)
                }
                onPositionChanged: function(mouse) {
                    if (pressed) hueControl.setPosition(mouse.x)
                }
            }

            Keys.onPressed: function(event) {
                const step = event.modifiers & Qt.ShiftModifier ? 10 / 360 : 1 / 360
                if (event.key === Qt.Key_Left || event.key === Qt.Key_Down)
                    root.hue = root.clamp(root.hue - step, 0, 1)
                else if (event.key === Qt.Key_Right || event.key === Qt.Key_Up)
                    root.hue = root.clamp(root.hue + step, 0, 1)
                else return
                root.queueColor()
                event.accepted = true
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                implicitWidth: 34
                implicitHeight: 30
                radius: Theme.controlRadius
                color: root.colorValue
                border.color: Theme.controlBorder
                border.width: 1
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 30
                radius: Theme.controlRadius
                color: Theme.bgElev
                border.color: root.hexValid ? Theme.controlBorder : Theme.err
                border.width: root.hexValid ? 1 : 2

                TextInput {
                    id: hexInput
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text
                    selectionColor: Theme.controlActiveBg
                    selectedTextColor: Theme.controlActiveFg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.sizeLabel
                    font.weight: Theme.fontWeight
                    maximumLength: 7
                    activeFocusOnTab: true
                    Accessible.name: "Hex color"
                    onEditingFinished: root.commitHex()
                }
            }
        }

        Text {
            visible: !root.hexValid
            text: "USE #RRGGBB"
            color: Theme.err
            font.family: Theme.fontFamily
            font.pixelSize: Theme.sizeMarker
            font.weight: Theme.fontWeight
        }
    }
}