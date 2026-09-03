import QtQuick

QtObject {
    readonly property string id: "cyberpunk"
    readonly property string name: "Cyberpunk"
    readonly property string variantId: "cyberpunk"
    readonly property string polarity: "dark"

    readonly property color bg:        "#07090b"
    readonly property color bgElev:    "#0e1418"
    readonly property color bgHi:      "#16202a"
    readonly property color text:      "#d5dce2"
    readonly property color trayBg:    "#030507"
    readonly property color trayFg:    "#d5dce2"

    readonly property color amber:     "#9b5cd9"
    readonly property color amberHi:   "#c89cf0"
    readonly property color amberDim:  "#4a2a7a"

    readonly property color chrome:    "#63002d"
    readonly property color chromeHi:  "#d30060"
    readonly property color chromeDim: "#000000"

    readonly property color sun:       "#d97a3c"
    readonly property color sunHi:     "#f0a468"
    readonly property color sunDim:    "#7a4622"

    readonly property color teal:      "#6b9aa8"
    readonly property color tealDim:   "#3a5560"
    readonly property color pink:      "#b06860"
    readonly property color ok:        "#7aa86b"
    readonly property color warn:      "#d9a13c"
    readonly property color err:       "#c44e3a"

    readonly property color moon:      "#c8ccd0"
    readonly property color moonDim:   "#5a5e62"
    readonly property color graphRx:   "#6b99a8"
    readonly property color graphTx:   "#9b5cd9"
    readonly property color chromaLeft:  "#ff3a3a"
    readonly property color chromaRight: "#3aaaff"

    readonly property string fontFamily: "BlexMono Nerd Font Mono"
    readonly property int fontWeight: Font.Bold
    readonly property int sizeReadout: 18
    readonly property int sizeLabel: 12
    readonly property int sizeMarker: 10
    readonly property int sizeIconLarge: 32
    readonly property real labelLetterSpacing: 2.0
    readonly property real labelOpacity: 0.9
    readonly property bool chromaSplitEnabled: true
    readonly property real readoutBloomOpacity: 0.22

    readonly property int barHeight: 48
    readonly property int gutter: 15
    readonly property int chipPadH: 10
    readonly property int chipPadV: 4
    readonly property int controlRadius: 2
    readonly property int controlBorderWidth: 2
    readonly property int cornerArmLength: 10
    readonly property bool showCorners: true
    readonly property bool dashedFrames: true
    readonly property color controlFg: amber
    readonly property color controlHoverFg: bg
    readonly property color controlHoverBg: amber
    readonly property color controlActiveFg: bg
    readonly property color controlActiveBg: amber
    readonly property color controlBorder: chrome
    readonly property color controlFocus: amberHi

    readonly property int durFast: 120
    readonly property int durMedium: 240
    readonly property int durBreath: 8000
    readonly property real bloomStrength: 0.35

    readonly property QtObject effects: QtObject {
        readonly property bool scanlines: true
        readonly property bool vignette: true
        readonly property bool flicker: true
        readonly property bool rollBar: true
        readonly property bool bloom: true
    }
}