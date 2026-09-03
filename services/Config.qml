pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    readonly property var defaults: ({
        version: 1,
        apps: {
            volume: ["pwvucontrol"],
            spotify: ["spotify-launcher"]
        },
        weather: { location: "London" },
        wallpaper: {
            mode: "images",
            directory: "~/Pictures/walls",
            color: "#26312F",
            colors: ["#26312F", "#EEF1ED", "#B8D5CC", "#DCC7A1", "#B98282"]
        },
        controller: { enabled: false, address: "" },
        workspace2: { enabled: false, id: 2, apps: [] },
        minimisedStateFile: ""
    })

    property var values: defaults
    property string errorMessage: ""
    signal wallpaperChanged()

    readonly property var volumeCommand: command("volume", defaults.apps.volume)
    readonly property var spotifyCommand: command("spotify", defaults.apps.spotify)
    readonly property string weatherLocation: stringValue(
        values.weather, "location", defaults.weather.location)
    readonly property string wallpaperDirectory: Paths.expandUserPath(stringValue(
        values.wallpaper, "directory", defaults.wallpaper.directory))
    readonly property string wallpaperMode: values.wallpaper
        && (values.wallpaper.mode === "images" || values.wallpaper.mode === "solid")
        ? values.wallpaper.mode : defaults.wallpaper.mode
    readonly property string wallpaperColor: values.wallpaper
        && typeof values.wallpaper.color === "string"
        && /^#[0-9A-Fa-f]{6}$/.test(values.wallpaper.color)
        ? values.wallpaper.color.toUpperCase() : defaults.wallpaper.color
    readonly property var wallpaperColors: validColors(
        values.wallpaper ? values.wallpaper.colors : null)
        ? values.wallpaper.colors.map(function(color) { return color.toUpperCase() })
        : defaults.wallpaper.colors
    readonly property bool controllerEnabled: values.controller
        && typeof values.controller.enabled === "boolean"
        ? values.controller.enabled : defaults.controller.enabled
    readonly property string controllerAddress: stringValue(
        values.controller, "address", defaults.controller.address)
    readonly property bool workspace2Enabled: values.workspace2
        && typeof values.workspace2.enabled === "boolean"
        ? values.workspace2.enabled : defaults.workspace2.enabled
    readonly property int workspace2Id: values.workspace2
        && Number.isInteger(values.workspace2.id) && values.workspace2.id > 0
        ? values.workspace2.id : defaults.workspace2.id
    readonly property var workspace2Apps: validCommandList(
        values.workspace2 ? values.workspace2.apps : null)
        ? values.workspace2.apps : defaults.workspace2.apps
    readonly property string minimisedStateFile: {
        const configured = typeof values.minimisedStateFile === "string"
            ? Paths.expandUserPath(values.minimisedStateFile) : ""
        return configured.length > 0 ? configured : Paths.minimisedStatePath
    }

    function validCommand(value) {
        if (!Array.isArray(value) || value.length === 0) return false
        for (let index = 0; index < value.length; index++) {
            if (typeof value[index] !== "string" || value[index].length === 0)
                return false
        }
        return true
    }

    function validCommandList(value) {
        if (!Array.isArray(value)) return false
        for (let index = 0; index < value.length; index++) {
            if (!validCommand(value[index])) return false
        }
        return true
    }

    function validColors(value) {
        if (!Array.isArray(value) || value.length === 0) return false
        for (let index = 0; index < value.length; index++) {
            if (typeof value[index] !== "string"
                    || !/^#[0-9A-Fa-f]{6}$/.test(value[index])) return false
        }
        return true
    }

    function colorHex(value) {
        const channel = function(component) {
            return Math.round(Math.max(0, Math.min(1, component)) * 255)
                .toString(16).padStart(2, "0").toUpperCase()
        }
        return "#" + channel(value.r) + channel(value.g) + channel(value.b)
    }

    function selectWallpaperImages() {
        updateWallpaper("images", wallpaperColor)
    }

    function selectWallpaperColor(color) {
        const normalized = typeof color === "string"
            ? color.toUpperCase() : colorHex(color)
        if (!/^#[0-9A-F]{6}$/.test(normalized)) return
        updateWallpaper("solid", normalized)
    }

    function updateWallpaper(mode, color) {
        const next = JSON.parse(JSON.stringify(values))
        if (!next.wallpaper) next.wallpaper = {}
        next.wallpaper.mode = mode
        next.wallpaper.color = color
        values = next
        wallpaperChanged()
        pendingPayload = JSON.stringify(next)
        if (!configWriter.running) writeTimer.restart()
    }

    function startWrite() {
        if (!pendingPayload || configWriter.running) return
        const payload = pendingPayload
        pendingPayload = ""
        configWriter.command = ["python3", Paths.script("write_config.py"),
                                Paths.configPath, payload]
        configWriter.running = true
    }

    function command(name, fallback) {
        const candidate = values.apps ? values.apps[name] : null
        return validCommand(candidate) ? candidate : fallback
    }

    function stringValue(object, key, fallback) {
        return object && typeof object[key] === "string" && object[key].length > 0
            ? object[key] : fallback
    }

    function load(rawText) {
        try {
            const previousMode = wallpaperMode
            const previousDirectory = wallpaperDirectory
            const previousColor = wallpaperColor
            const document = JSON.parse(rawText)
            if (!document || document.version !== 1)
                throw new Error("config must have version 1")
            if (document.apps && typeof document.apps !== "object")
                throw new Error("apps must be an object")
            if (document.wallpaper && document.wallpaper.mode !== undefined
                    && document.wallpaper.mode !== "images"
                    && document.wallpaper.mode !== "solid")
                throw new Error("wallpaper.mode must be images or solid")
            if (document.wallpaper && document.wallpaper.color !== undefined
                    && (typeof document.wallpaper.color !== "string"
                        || !/^#[0-9A-Fa-f]{6}$/.test(document.wallpaper.color)))
                throw new Error("wallpaper.color must use #RRGGBB")
            if (document.wallpaper && document.wallpaper.colors !== undefined
                    && !validColors(document.wallpaper.colors))
                throw new Error("wallpaper.colors must contain #RRGGBB colors")
            if (document.workspace2 && document.workspace2.apps !== undefined
                    && !validCommandList(document.workspace2.apps))
                throw new Error("workspace2.apps must contain command arrays")
            if (document.workspace2 && document.workspace2.enabled !== undefined
                    && typeof document.workspace2.enabled !== "boolean")
                throw new Error("workspace2.enabled must be a boolean")
            if (document.workspace2 && document.workspace2.monitor !== undefined
                    && typeof document.workspace2.monitor !== "string")
                throw new Error("workspace2.monitor must be a string")
            if (document.workspace2 && document.workspace2.postLaunch !== undefined
                    && (!Array.isArray(document.workspace2.postLaunch)
                        || (document.workspace2.postLaunch.length > 0
                            && !validCommand(document.workspace2.postLaunch))))
                throw new Error("workspace2.postLaunch must be a command array")
            if (document.workspace2) {
                const delays = ["launchDelayMs", "postLaunchDelayMs"]
                for (let index = 0; index < delays.length; index++) {
                    const value = document.workspace2[delays[index]]
                    if (value !== undefined && (!Number.isInteger(value)
                            || value < 0 || value > 30000))
                        throw new Error("workspace2." + delays[index]
                                        + " must be between 0 and 30000")
                }
            }
            values = document
            errorMessage = ""
            Qt.callLater(function() {
                if (root.wallpaperMode !== previousMode
                        || root.wallpaperDirectory !== previousDirectory
                        || root.wallpaperColor !== previousColor)
                    root.wallpaperChanged()
            })
        } catch (error) {
            console.warn("Config ignored:", error)
            values = defaults
            errorMessage = String(error)
        }
    }

    property FileView configFile: FileView {
        path: Paths.configPath
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: {
            const rawText = text()
            if (rawText.trim().length > 0) root.load(rawText)
        }
    }

    property string pendingPayload: ""
    property Timer writeTimer: Timer {
        interval: 80
        onTriggered: root.startWrite()
    }
    property Process configWriter: Process {
        running: false
        onExited: root.startWrite()
    }
}
