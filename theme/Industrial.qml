import QtQuick

QtObject {
    readonly property string id: "industrial"
    readonly property string name: "Industrial"
    readonly property string variantId: "industrial"
    readonly property string polarity: "light"

    readonly property color bg:        "#eef1ed"
    readonly property color bgElev:    "#f8faf7"
    readonly property color bgHi:      "#dfe5df"
    readonly property color text:      "#26312f"
    readonly property color trayBg:    "#26312f"
    readonly property color trayFg:    "#f8faf7"

    readonly property color amber:     "#476d67"
    readonly property color amberHi:   "#315953"
    readonly property color amberDim:  "#b8d5cc"

    readonly property color chrome:    "#697773"
    readonly property color chromeHi:  "#33433f"
    readonly property color chromeDim: "#cbd3ce"

    readonly property color sun:       "#966b22"
    readonly property color sunHi:     "#754f0e"
    readonly property color sunDim:    "#ddc58e"

    readonly property color teal:      "#3f6762"
    readonly property color tealDim:   "#5b706c"
    readonly property color pink:      "#8c514b"
    readonly property color ok:        "#3f6b4f"
    readonly property color warn:      "#825e17"
    readonly property color err:       "#9b3f3f"

    readonly property color moon:      "#536771"
    readonly property color moonDim:   "#b8c5ca"
    readonly property color graphRx:   "#3f6762"
    readonly property color graphTx:   "#8c514b"
    readonly property color chromaLeft:  "#8c514b"
    readonly property color chromaRight: "#536771"

    readonly property string fontFamily: "BlexMono Nerd Font Mono"
    readonly property int fontWeight: Font.Medium
    readonly property int sizeReadout: 18
    readonly property int sizeLabel: 12
    readonly property int sizeMarker: 10
    readonly property int sizeIconLarge: 32
    readonly property real labelLetterSpacing: 1.0
    readonly property real labelOpacity: 0.78
    readonly property bool chromaSplitEnabled: false
    readonly property real readoutBloomOpacity: 0.08

    readonly property int barHeight: 48
    readonly property int gutter: 18
    readonly property int chipPadH: 10
    readonly property int chipPadV: 4
    readonly property int controlRadius: 3
    readonly property int controlBorderWidth: 1
    readonly property int cornerArmLength: 10
    readonly property bool showCorners: false
    readonly property bool dashedFrames: false
    readonly property color controlFg: text
    readonly property color controlHoverFg: text
    readonly property color controlHoverBg: bgHi
    readonly property color controlActiveFg: text
    readonly property color controlActiveBg: amberDim
    readonly property color controlBorder: chrome
    readonly property color controlFocus: amberHi

    readonly property int durFast: 100
    readonly property int durMedium: 180
    readonly property int durBreath: 8000
    readonly property real bloomStrength: 0.12

    readonly property QtObject effects: QtObject {
        readonly property bool scanlines: false
        readonly property bool vignette: false
        readonly property bool flicker: false
        readonly property bool rollBar: false
        readonly property bool bloom: true
    }
}