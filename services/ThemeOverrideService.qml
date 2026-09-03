pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    readonly property string overridesPath: Paths.themeOverridesPath
    readonly property string helperPath: Paths.script("theme_overrides.py")
    readonly property var knownThemes: ["cyberpunk", "industrial"]
    readonly property var colorTokens: [
        "bg", "bgElev", "bgHi", "text", "trayBg",
        "amber", "amberHi", "amberDim",
        "chrome", "chromeHi", "chromeDim",
        "sun", "sunHi", "sunDim",
        "teal", "tealDim", "pink", "ok", "warn", "err",
        "moon", "moonDim", "graphRx", "graphTx"
    ]
    readonly property var metricTokens: [
        "controlRadius", "controlBorderWidth", "cornerArmLength"
    ]
    readonly property var flagTokens: [
        "showCorners", "dashedFrames",
        "controllerCorners", "volumeCorners", "workspace2Corners",
        "settingsCorners", "powerCorners",
        "weatherFrameVisible", "weatherFrameDashed",
        "clockFrameVisible", "clockFrameDashed",
        "systemTrayFrameVisible", "systemTrayFrameDashed"
    ]
    readonly property var knownTokens: colorTokens.concat(metricTokens, flagTokens)

    property var storedThemes: ({})
    property var workingOverrides: ({})
    property var openingOverrides: ({})
    property string editingThemeId: ""
    property bool dirty: false
    property bool saving: false
    property string errorMessage: ""
    property int revision: 0

    signal paletteChanged(string themeId, string token)
    signal saveSucceeded()
    signal saveFailed(string message)

    function cloneMap(source) {
        const result = {}
        if (!source) return result
        const keys = Object.keys(source)
        for (let index = 0; index < keys.length; index++)
            result[keys[index]] = source[keys[index]]
        return result
    }

    function mapsEqual(left, right) {
        const leftKeys = Object.keys(left || {}).sort()
        const rightKeys = Object.keys(right || {}).sort()
        if (leftKeys.length !== rightKeys.length) return false
        for (let index = 0; index < leftKeys.length; index++) {
            const key = leftKeys[index]
            if (key !== rightKeys[index] || left[key] !== right[key]) return false
        }
        return true
    }

    function normalizeColor(value) {
        const text = String(value).toUpperCase()
        return /^#[0-9A-F]{6}$/.test(text) ? text : ""
    }

    function metricBounds(token) {
        if (token === "controlRadius") return { minimum: 0, maximum: 12 }
        if (token === "controlBorderWidth") return { minimum: 0, maximum: 4 }
        if (token === "cornerArmLength") return { minimum: 4, maximum: 24 }
        return null
    }

    function normalizeValue(token, value) {
        if (colorTokens.indexOf(token) !== -1) return normalizeColor(value)
        if (flagTokens.indexOf(token) !== -1)
            return typeof value === "boolean" ? value : undefined
        const bounds = metricBounds(token)
        if (!bounds || typeof value !== "number" || !Number.isFinite(value))
            return undefined
        const rounded = Math.round(value)
        return rounded >= bounds.minimum && rounded <= bounds.maximum
            ? rounded : undefined
    }

    function isKnownTheme(themeId) {
        return knownThemes.indexOf(themeId) !== -1
    }

    function isKnownToken(token) {
        return knownTokens.indexOf(token) !== -1
    }

    function persistedOverrides(themeId) {
        return cloneMap(storedThemes[themeId] || {})
    }

    function effectiveOverrides(themeId) {
        return editingThemeId === themeId ? workingOverrides : (storedThemes[themeId] || {})
    }

    function value(themeId, token, fallback) {
        revision
        const overrides = effectiveOverrides(themeId)
        return overrides[token] !== undefined ? overrides[token] : fallback
    }

    function blend(first: color, second: color, amount: real): color {
        const ratio = Math.max(0, Math.min(1, amount))
        return Qt.rgba(
            first.r + (second.r - first.r) * ratio,
            first.g + (second.g - first.g) * ratio,
            first.b + (second.b - first.b) * ratio,
            1)
    }

    function linearChannel(channel: real): real {
        return channel <= 0.04045
            ? channel / 12.92
            : Math.pow((channel + 0.055) / 1.055, 2.4)
    }

    function luminance(value: color): real {
        return 0.2126 * linearChannel(value.r)
             + 0.7152 * linearChannel(value.g)
             + 0.0722 * linearChannel(value.b)
    }

    function contrastRatio(foreground: color, background: color): real {
        const first = luminance(foreground)
        const second = luminance(background)
        const lighter = Math.max(first, second)
        const darker = Math.min(first, second)
        return (lighter + 0.05) / (darker + 0.05)
    }

    function derivedValue(themeId, token, fallback, baseToken, baseFallback,
                          polarity, background, mode) {
        revision
        const overrides = effectiveOverrides(themeId)
        if (overrides[token] !== undefined) return overrides[token]
        if (overrides[baseToken] === undefined) return fallback

        const base = overrides[baseToken]
        if (mode === "emphasis")
            return blend(base, polarity === "dark" ? "#ffffff" : "#000000", 0.22)
        if (mode === "muted") return blend(base, background, 0.55)
        if (mode === "surfaceElevated")
            return blend(base, polarity === "dark" ? "#ffffff" : "#ffffff",
                         polarity === "dark" ? 0.035 : 0.52)
        if (mode === "surfaceHighlight")
            return blend(base, polarity === "dark" ? "#ffffff" : "#000000",
                         polarity === "dark" ? 0.09 : 0.06)
        return baseFallback
    }

    function hasOverride(themeId, token) {
        revision
        return effectiveOverrides(themeId)[token] !== undefined
    }

    function isCustomized(themeId) {
        revision
        return Object.keys(storedThemes[themeId] || {}).length > 0
    }

    function beginEdit(themeId) {
        if (!isKnownTheme(themeId) || saving) return false
        editingThemeId = themeId
        openingOverrides = persistedOverrides(themeId)
        workingOverrides = cloneMap(openingOverrides)
        dirty = false
        errorMessage = ""
        revision++
        paletteChanged(themeId, "*")
        return true
    }

    function setColor(token, color) {
        return setValue(token, color)
    }

    function setValue(token, value) {
        if (!editingThemeId || !isKnownToken(token)) return false
        const normalized = normalizeValue(token, value)
        if (normalized === undefined || normalized === "") return false
        const next = cloneMap(workingOverrides)
        next[token] = normalized
        workingOverrides = next
        dirty = !mapsEqual(workingOverrides, openingOverrides)
        revision++
        paletteChanged(editingThemeId, token)
        return true
    }

    function setMetric(token, value) {
        return metricTokens.indexOf(token) !== -1 && setValue(token, value)
    }

    function setFlag(token, value) {
        return flagTokens.indexOf(token) !== -1 && setValue(token, value)
    }

    function removeColor(token) {
        if (!editingThemeId || !isKnownToken(token)) return
        const next = cloneMap(workingOverrides)
        delete next[token]
        workingOverrides = next
        dirty = !mapsEqual(workingOverrides, openingOverrides)
        revision++
        paletteChanged(editingThemeId, token)
    }

    function setBaseColor(token, color) {
        return setColor(token, color)
    }

    function setVariantColor(token, color) {
        return setColor(token, color)
    }

    function lockVariant(token) {
        removeColor(token)
    }

    function resetFamily(baseToken, variantTokens) {
        if (!editingThemeId) return
        const next = cloneMap(workingOverrides)
        delete next[baseToken]
        const variants = variantTokens || []
        for (let index = 0; index < variants.length; index++)
            delete next[variants[index]]
        workingOverrides = next
        dirty = !mapsEqual(workingOverrides, openingOverrides)
        revision++
        paletteChanged(editingThemeId, baseToken)
    }

    function resetTokens(tokens) {
        if (!editingThemeId) return
        const next = cloneMap(workingOverrides)
        for (let index = 0; index < tokens.length; index++)
            delete next[tokens[index]]
        workingOverrides = next
        dirty = !mapsEqual(workingOverrides, openingOverrides)
        revision++
        paletteChanged(editingThemeId, "*")
    }

    function resetTheme() {
        if (!editingThemeId) return
        workingOverrides = ({})
        dirty = Object.keys(openingOverrides).length > 0
        revision++
        paletteChanged(editingThemeId, "*")
    }

    function cancel() {
        if (!editingThemeId || saving) return
        const themeId = editingThemeId
        workingOverrides = ({})
        openingOverrides = ({})
        editingThemeId = ""
        dirty = false
        errorMessage = ""
        revision++
        paletteChanged(themeId, "*")
    }

    function save() {
        if (!editingThemeId || saving) return
        const nextThemes = cloneMap(storedThemes)
        if (Object.keys(workingOverrides).length > 0)
            nextThemes[editingThemeId] = cloneMap(workingOverrides)
        else
            delete nextThemes[editingThemeId]

        const payload = JSON.stringify({ version: 1, themes: nextThemes })
        saving = true
        errorMessage = ""
        saveProcess.command = ["python3", helperPath, "write", overridesPath, payload]
        saveProcess.running = true
    }

    function loadText(rawText) {
        try {
            const document = JSON.parse(rawText)
            if (document.version !== 1 || typeof document.themes !== "object")
                throw new Error("unsupported override document")
            const validated = {}
            const themeIds = Object.keys(document.themes || {})
            for (let themeIndex = 0; themeIndex < themeIds.length; themeIndex++) {
                const themeId = themeIds[themeIndex]
                if (!isKnownTheme(themeId)) throw new Error("unknown theme " + themeId)
                const source = document.themes[themeId]
                if (!source || typeof source !== "object")
                    throw new Error("invalid overrides for " + themeId)
                const clean = {}
                const tokens = Object.keys(source)
                for (let tokenIndex = 0; tokenIndex < tokens.length; tokenIndex++) {
                    const token = tokens[tokenIndex]
                    const value = normalizeValue(token, source[token])
                    if (!isKnownToken(token) || value === undefined || value === "")
                        throw new Error("invalid override " + token)
                    clean[token] = value
                }
                if (Object.keys(clean).length > 0) validated[themeId] = clean
            }
            storedThemes = validated
            revision++
            paletteChanged("*", "*")
            errorMessage = ""
        } catch (error) {
            console.warn("Theme overrides ignored:", error)
            storedThemes = ({})
            revision++
            paletteChanged("*", "*")
            errorMessage = "Invalid theme override file"
        }
    }

    property FileView overrideState: FileView {
        path: root.overridesPath
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: {
            const rawText = text()
            if (rawText.trim().length > 0) root.loadText(rawText)
        }
    }

    property Process saveProcess: Process {
        running: false
        onExited: function(exitCode) {
            root.saving = false
            if (exitCode !== 0) {
                root.errorMessage = "Could not save theme overrides"
                root.saveFailed(root.errorMessage)
                return
            }

            const themeId = root.editingThemeId
            const nextThemes = root.cloneMap(root.storedThemes)
            if (Object.keys(root.workingOverrides).length > 0)
                nextThemes[themeId] = root.cloneMap(root.workingOverrides)
            else
                delete nextThemes[themeId]
            root.storedThemes = nextThemes
            root.openingOverrides = root.cloneMap(root.workingOverrides)
            root.dirty = false
            root.revision++
            root.paletteChanged(themeId, "*")
            root.saveSucceeded()
        }
    }
}