import QtQuick
import QtQuick.Effects
import "../theme"

// Readout text: the load-bearing values (time, temperature, song title).
// Set `glow: true` to halo the text in its own colour.
// Set `chromaSplit: true` for RGB subpixel ghosting (chromatic aberration).
// `bloom` adds a soft outer phosphor halo (always on for CRT feel).
Item {
    id: root
    property string text: ""
    property color  color: Theme.teal
    property bool   glow: false
    property real   glowStrength: 0.9
    property real   glowRadius: 14
    property bool   chromaSplit: false
    property real   chromaOffset: 1.0
    property bool   bloom: true
    property alias  font: main.font
    property alias  elide: main.elide
    property alias  horizontalAlignment: main.horizontalAlignment
    property alias  verticalAlignment: main.verticalAlignment

    implicitWidth:  main.implicitWidth  + (chromaSplit ? chromaOffset * 2 : 0)
    implicitHeight: main.implicitHeight

    // Soft phosphor bloom (behind everything)
    Text {
        anchors.centerIn: parent
        visible: root.bloom && Fx.bloom
        text: root.text
        color: root.color
        font: main.font
        opacity: Theme.readoutBloomOpacity
        z: -1
        layer.enabled: visible
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: 32
            blur: 1.0
        }
    }

    // Red ghost (offset left)
    Text {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: -root.chromaOffset
        visible: root.chromaSplit && Theme.chromaSplitEnabled
        text: root.text
        color: Theme.chromaLeft
        opacity: 0.55
        font: main.font
    }
    // Blue ghost (offset right)
    Text {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.chromaOffset
        visible: root.chromaSplit && Theme.chromaSplitEnabled
        text: root.text
        color: Theme.chromaRight
        opacity: 0.55
        font: main.font
    }
    // Main text on top
    Text {
        id: main
        anchors.centerIn: parent
        width: parent.width > 0 ? parent.width : implicitWidth
        text: root.text
        color: root.color
        font.family: Theme.fontFamily
        font.pixelSize: Theme.sizeReadout
        font.weight: Theme.fontWeight
        verticalAlignment: Text.AlignVCenter

        // Sharp inner glow
        layer.enabled: root.glow
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.color
            shadowOpacity: root.glowStrength
            shadowBlur: 1.0
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            blurMax: root.glowRadius
        }
    }
}
