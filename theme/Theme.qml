pragma Singleton
import QtQuick
import Quickshell.Io
import "../services"

QtObject {
    id: root

    readonly property string selectionPath: Paths.themeSelectionPath
    property string currentThemeId: "cyberpunk"
    readonly property QtObject active: currentThemeId === "industrial" ? industrial : cyberpunk
    readonly property var availableThemes: [
        { id: "cyberpunk", name: "Cyberpunk", swatch: "#9b5cd9" },
        { id: "industrial", name: "Industrial", swatch: "#b8d5cc" }
    ]

    readonly property QtObject cyberpunk: Cyberpunk {}
    readonly property QtObject industrial: Industrial {}

    readonly property string variantId: active.variantId
    function resolve(token, fallback) {
        return ThemeOverrideService.value(currentThemeId, token, fallback)
    }

    function derive(token, fallback, baseToken, baseFallback, mode) {
        return ThemeOverrideService.derivedValue(
            currentThemeId, token, fallback, baseToken, baseFallback,
            active.polarity, bg, mode)
    }

    readonly property color bg: resolve("bg", active.bg)
    readonly property color bgElev: derive("bgElev", active.bgElev, "bg", active.bg, "surfaceElevated")
    readonly property color bgHi: derive("bgHi", active.bgHi, "bg", active.bg, "surfaceHighlight")
    readonly property color text: resolve("text", active.text)
    readonly property color trayBg: resolve("trayBg", active.trayBg)
    readonly property color trayFg: active.trayFg
    readonly property color amber: resolve("amber", active.amber)
    readonly property color amberHi: derive("amberHi", active.amberHi, "amber", active.amber, "emphasis")
    readonly property color amberDim: derive("amberDim", active.amberDim, "amber", active.amber, "muted")
    readonly property color chrome: resolve("chrome", active.chrome)
    readonly property color chromeHi: derive("chromeHi", active.chromeHi, "chrome", active.chrome, "emphasis")
    readonly property color chromeDim: derive("chromeDim", active.chromeDim, "chrome", active.chrome, "muted")
    readonly property color sun: resolve("sun", active.sun)
    readonly property color sunHi: derive("sunHi", active.sunHi, "sun", active.sun, "emphasis")
    readonly property color sunDim: derive("sunDim", active.sunDim, "sun", active.sun, "muted")
    readonly property color teal: resolve("teal", active.teal)
    readonly property color tealDim: derive("tealDim", active.tealDim, "teal", active.teal, "muted")
    readonly property color pink: resolve("pink", active.pink)
    readonly property color ok: resolve("ok", active.ok)
    readonly property color warn: resolve("warn", active.warn)
    readonly property color err: resolve("err", active.err)
    readonly property color moon: resolve("moon", active.moon)
    readonly property color moonDim: derive("moonDim", active.moonDim, "moon", active.moon, "muted")
    readonly property color graphRx: resolve("graphRx", active.graphRx)
    readonly property color graphTx: resolve("graphTx", active.graphTx)
    readonly property color chromaLeft: active.chromaLeft
    readonly property color chromaRight: active.chromaRight

    readonly property string fontFamily: active.fontFamily
    readonly property int fontWeight: active.fontWeight
    readonly property int sizeReadout: active.sizeReadout
    readonly property int sizeLabel: active.sizeLabel
    readonly property int sizeMarker: active.sizeMarker
    readonly property int sizeIconLarge: active.sizeIconLarge
    readonly property real labelLetterSpacing: active.labelLetterSpacing
    readonly property real labelOpacity: active.labelOpacity
    readonly property bool chromaSplitEnabled: active.chromaSplitEnabled
    readonly property real readoutBloomOpacity: active.readoutBloomOpacity

    readonly property int barHeight: active.barHeight
    readonly property int gutter: active.gutter
    readonly property int chipPadH: active.chipPadH
    readonly property int chipPadV: active.chipPadV
    readonly property int controlRadius: resolve("controlRadius", active.controlRadius)
    readonly property int controlBorderWidth: resolve("controlBorderWidth", active.controlBorderWidth)
    readonly property int cornerArmLength: resolve("cornerArmLength", active.cornerArmLength)
    readonly property bool showCorners: resolve("showCorners", active.showCorners)
    readonly property bool dashedFrames: resolve("dashedFrames", active.dashedFrames)
    readonly property bool controllerCorners: resolve("controllerCorners", showCorners)
    readonly property bool volumeCorners: resolve("volumeCorners", showCorners)
    readonly property bool workspace2Corners: resolve("workspace2Corners", showCorners)
    readonly property bool settingsCorners: resolve("settingsCorners", showCorners)
    readonly property bool powerCorners: resolve("powerCorners", showCorners)
    readonly property bool weatherFrameVisible: resolve("weatherFrameVisible", true)
    readonly property bool weatherFrameDashed: resolve("weatherFrameDashed", dashedFrames)
    readonly property bool clockFrameVisible: resolve("clockFrameVisible", true)
    readonly property bool clockFrameDashed: resolve("clockFrameDashed", dashedFrames)
    readonly property bool systemTrayFrameVisible: resolve("systemTrayFrameVisible", true)
    readonly property bool systemTrayFrameDashed: resolve("systemTrayFrameDashed", false)
    readonly property color controlFg: variantId === "industrial" ? text : amber
    readonly property color controlHoverFg: variantId === "industrial" ? text : bg
    readonly property color controlHoverBg: variantId === "industrial" ? bgHi : amber
    readonly property color controlActiveFg: variantId === "industrial" ? text : bg
    readonly property color controlActiveBg: variantId === "industrial" ? amberDim : amber
    readonly property color controlBorder: chrome
    readonly property color controlFocus: amberHi

    readonly property int durFast: active.durFast
    readonly property int durMedium: active.durMedium
    readonly property int durBreath: active.durBreath
    readonly property real bloomStrength: active.bloomStrength
    readonly property QtObject effects: active.effects

    signal themeChanged(string themeId)
    signal paletteChanged(string themeId, string token)

    property Connections overrideConnections: Connections {
        target: ThemeOverrideService
        function onPaletteChanged(themeId, token) {
            root.paletteChanged(themeId, token)
        }
    }

    function isKnown(themeId) {
        return themeId === "cyberpunk" || themeId === "industrial"
    }

    function selectTheme(themeId, persist) {
        const nextId = isKnown(themeId) ? themeId : "cyberpunk"
        if (currentThemeId !== nextId) {
            currentThemeId = nextId
            themeChanged(nextId)
        }
        if (persist !== false) {
            themeWriter.command = ["sh", "-c",
                "tmp=\"$1.tmp\"; printf '%s' \"$2\" > \"$tmp\" && mv \"$tmp\" \"$1\"",
                "sh", selectionPath, nextId]
            themeWriter.running = true
        }
    }

    property FileView themeState: FileView {
        id: themeState
        path: root.selectionPath
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: root.selectTheme(text().trim(), false)
    }

    property Process themeWriter: Process {
        id: themeWriter
        running: false
    }
}
