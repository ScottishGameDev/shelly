import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../services"

Item {
    id: root

    required property string token
    required property string label
    property var variants: []
    property real pickerRightX: 0
    property real pickerLeftBoundaryX: 0
    readonly property bool customized: ThemeOverrideService.hasOverride(
        ThemeOverrideService.editingThemeId, token)
    readonly property bool isSurface: token === "bg"
    readonly property bool isStructural: token === "chrome"
                                   || token === "graphRx" || token === "graphTx"
    readonly property real contrastThreshold: isStructural ? 3.0 : 4.5
    readonly property real contrastRatio: isSurface
        ? ThemeOverrideService.contrastRatio(Theme.text, Theme.bg)
        : ThemeOverrideService.contrastRatio(Theme[token], Theme.bg)
    readonly property bool contrastWarning: customized
        && contrastRatio < contrastThreshold

    implicitWidth: 330
    implicitHeight: content.implicitHeight

    function openPicker(nextToken, anchorItem) {
        if (nextToken !== token && !ThemeOverrideService.hasOverride(
                ThemeOverrideService.editingThemeId, nextToken))
            ThemeOverrideService.setVariantColor(nextToken, Theme[nextToken])

        const point = anchorItem.mapToItem(null,
                                           anchorItem.width / 2,
                                           anchorItem.height / 2)
        const tokenLabel = nextToken === token
            ? label : variants.find(function(variant) {
                return variant.token === nextToken
            }).label
        Bus.colorPickerRequested(
            anchorItem.QsWindow.window.screen,
            pickerRightX,
            pickerLeftBoundaryX,
            point.y,
            label + " / " + tokenLabel,
            Theme[nextToken],
            function(colorValue) {
                if (nextToken === token)
                    ThemeOverrideService.setBaseColor(token, colorValue)
                else
                    ThemeOverrideService.setVariantColor(nextToken, colorValue)
            })
    }

    ColumnLayout {
        id: content
        width: parent.width
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                id: baseSwatch
                implicitWidth: 26
                implicitHeight: 26
                radius: Theme.controlRadius
                color: Theme[root.token]
                border.color: Theme.controlBorder
                border.width: 1

                TapHandler { onTapped: root.openPicker(root.token, baseSwatch) }
            }
            Text {
                Layout.fillWidth: true
                text: root.label + (root.customized ? "  •" : "")
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.sizeLabel
                font.weight: Theme.fontWeight
            }
            Chip {
                id: editButton
                text: "EDIT"
                accessibleName: "Edit " + root.label
                bracketed: false
                showCorners: false
                fontSize: Theme.sizeMarker
                onClicked: root.openPicker(root.token, editButton)
            }
            Chip {
                text: "RESET"
                accessibleName: "Reset " + root.label
                bracketed: false
                showCorners: false
                fontSize: Theme.sizeMarker
                enabled: root.customized || root.variants.some(function(variant) {
                    return ThemeOverrideService.hasOverride(
                        ThemeOverrideService.editingThemeId, variant.token)
                })
                onClicked: ThemeOverrideService.resetFamily(
                    root.token, root.variants.map(function(variant) { return variant.token }))
            }
        }

        RowLayout {
            visible: root.variants.length > 0
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: root.variants
                delegate: RowLayout {
                    required property var modelData
                    spacing: 4

                    Rectangle {
                        id: variantSwatch
                        implicitWidth: 18
                        implicitHeight: 18
                        radius: Theme.controlRadius
                        color: Theme[modelData.token]
                        border.color: Theme.controlBorder
                        border.width: 1
                        TapHandler {
                            onTapped: root.openPicker(modelData.token, variantSwatch)
                        }
                    }
                    Chip {
                        readonly property bool unlocked: ThemeOverrideService.hasOverride(
                            ThemeOverrideService.editingThemeId, modelData.token)
                        text: modelData.label + " / " + (unlocked ? "CUSTOM" : "AUTO")
                        accessibleName: (unlocked ? "Lock " : "Unlock ") + modelData.label
                        bracketed: false
                        showCorners: false
                        fontSize: Theme.sizeMarker
                        onClicked: {
                            if (unlocked) {
                                ThemeOverrideService.lockVariant(modelData.token)
                            } else {
                                root.openPicker(modelData.token, parent)
                            }
                        }
                    }
                }
            }
        }

        Text {
            visible: root.contrastWarning
            Layout.fillWidth: true
            text: "CONTRAST " + root.contrastRatio.toFixed(2) + ":1 / TARGET "
                  + root.contrastThreshold.toFixed(1) + ":1"
            color: Theme.warn
            font.family: Theme.fontFamily
            font.pixelSize: Theme.sizeMarker
            font.weight: Theme.fontWeight
            wrapMode: Text.Wrap
        }
    }
}