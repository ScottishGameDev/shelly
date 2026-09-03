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
        wallpaper: { directory: "~/Pictures/walls" },
        controller: { enabled: false, address: "" },
        workspace2: { enabled: false, id: 2, apps: [] },
        minimisedStateFile: ""
    })

    property var values: defaults
    property string errorMessage: ""

    readonly property var volumeCommand: command("volume", defaults.apps.volume)
    readonly property var spotifyCommand: command("spotify", defaults.apps.spotify)
    readonly property string weatherLocation: stringValue(
        values.weather, "location", defaults.weather.location)
    readonly property string wallpaperDirectory: Paths.expandUserPath(stringValue(
        values.wallpaper, "directory", defaults.wallpaper.directory))
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
            const document = JSON.parse(rawText)
            if (!document || document.version !== 1)
                throw new Error("config must have version 1")
            if (document.apps && typeof document.apps !== "object")
                throw new Error("apps must be an object")
            if (document.workspace2 && document.workspace2.apps !== undefined
                    && !validCommandList(document.workspace2.apps))
                throw new Error("workspace2.apps must contain command arrays")
            if (document.workspace2 && document.workspace2.enabled !== undefined
                    && typeof document.workspace2.enabled !== "boolean")
                throw new Error("workspace2.enabled must be a boolean")
            values = document
            errorMessage = ""
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
}
