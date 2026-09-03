import QtQuick
import QtQuick.Layouts
import "../theme"
import "../services"

Item {
    id: root

    readonly property var metricModel: [
        { token: "controlRadius", label: "CORNER RADIUS", minimum: 0, maximum: 12 },
        { token: "controlBorderWidth", label: "BORDER WIDTH", minimum: 0, maximum: 4 },
        { token: "cornerArmLength", label: "BRACKET LENGTH", minimum: 4, maximum: 24 }
    ]
    readonly property var cornerModel: [
        { token: "controllerCorners", label: "CONTROLLER" },
        { token: "volumeCorners", label: "VOLUME" },
        { token: "workspace2Corners", label: "WS2" },
        { token: "settingsCorners", label: "SETTINGS" },
        { token: "powerCorners", label: "POWER" }
    ]
    readonly property var frameModel: [
        { token: "weatherFrameVisible", label: "WEATHER FRAME" },
        { token: "weatherFrameDashed", label: "WEATHER DASHED" },
        { token: "clockFrameVisible", label: "CLOCK FRAME" },
        { token: "clockFrameDashed", label: "CLOCK DASHED" },
        { token: "systemTrayFrameVisible", label: "TRAY FRAME" },
        { token: "systemTrayFrameDashed", label: "TRAY DASHED" }
    ]
    readonly property var shapeTokens: [
        "controlRadius", "controlBorderWidth", "cornerArmLength",
        "showCorners", "dashedFrames",
        "controllerCorners", "volumeCorners", "workspace2Corners",
        "settingsCorners", "powerCorners",
        "weatherFrameVisible", "weatherFrameDashed",
        "clockFrameVisible", "clockFrameDashed",
        "systemTrayFrameVisible", "systemTrayFrameDashed"
    ]
    readonly property bool customized: shapeTokens.some(function(token) {
        return ThemeOverrideService.hasOverride(
            ThemeOverrideService.editingThemeId, token)
    })

    implicitWidth: 330
    implicitHeight: content.implicitHeight

    ColumnLayout {
        id: content
        width: parent.width
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: "CORNERS / SHAPE" + (root.customized ? "  •" : "")
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.sizeLabel
                font.weight: Theme.fontWeight
            }
            Chip {
                text: "RESET"
                accessibleName: "Reset corner and shape settings"
                bracketed: false
                showCorners: false
                fontSize: Theme.sizeMarker
                enabled: root.customized
                onClicked: ThemeOverrideService.resetTokens(root.shapeTokens)
            }
        }

        Repeater {
            model: root.metricModel
            delegate: RowLayout {
                required property var modelData
                readonly property int metricValue: Theme[modelData.token]
                Layout.fillWidth: true
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    text: modelData.label
                    color: Theme.teal
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.sizeMarker
                    font.weight: Theme.fontWeight
                }
                Chip {
                    text: "−"
                    accessibleName: "Decrease " + modelData.label.toLowerCase()
                    bracketed: false
                    showCorners: false
                    fontSize: Theme.sizeLabel
                    enabled: parent.metricValue > modelData.minimum
                    onClicked: ThemeOverrideService.setMetric(
                        modelData.token, parent.metricValue - 1)
                }
                Text {
                    Layout.preferredWidth: 28
                    horizontalAlignment: Text.AlignHCenter
                    text: parent.metricValue + " px"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.sizeMarker
                    font.weight: Theme.fontWeight
                }
                Chip {
                    text: "+"
                    accessibleName: "Increase " + modelData.label.toLowerCase()
                    bracketed: false
                    showCorners: false
                    fontSize: Theme.sizeLabel
                    enabled: parent.metricValue < modelData.maximum
                    onClicked: ThemeOverrideService.setMetric(
                        modelData.token, parent.metricValue + 1)
                }
                Chip {
                    text: "AUTO"
                    accessibleName: "Restore default " + modelData.label.toLowerCase()
                    bracketed: false
                    showCorners: false
                    fontSize: Theme.sizeMarker
                    enabled: ThemeOverrideService.hasOverride(
                        ThemeOverrideService.editingThemeId, modelData.token)
                    onClicked: ThemeOverrideService.removeColor(modelData.token)
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "CORNER BRACKETS"
            color: Theme.teal
            font.family: Theme.fontFamily
            font.pixelSize: Theme.sizeMarker
            font.weight: Theme.fontWeight
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 12
            rowSpacing: 4

            Repeater {
                model: root.cornerModel
                delegate: ToggleSwitch {
                    required property var modelData
                    Layout.fillWidth: true
                    text: modelData.label
                    accessibleName: "Show corners on " + modelData.label.toLowerCase()
                    checked: Theme[modelData.token]
                    onToggled: function(checked) {
                        ThemeOverrideService.setFlag(modelData.token, checked)
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "FRAMES"
            color: Theme.teal
            font.family: Theme.fontFamily
            font.pixelSize: Theme.sizeMarker
            font.weight: Theme.fontWeight
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 12
            rowSpacing: 4

            Repeater {
                model: root.frameModel
                delegate: ToggleSwitch {
                    required property var modelData
                    Layout.fillWidth: true
                    text: modelData.label
                    accessibleName: "Toggle " + modelData.label.toLowerCase()
                    checked: Theme[modelData.token]
                    onToggled: function(checked) {
                        ThemeOverrideService.setFlag(modelData.token, checked)
                    }
                }
            }
        }
    }
}