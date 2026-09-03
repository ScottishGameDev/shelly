pragma Singleton
import QtQuick
import Quickshell

QtObject {
    readonly property string root: Quickshell.shellRoot
    readonly property string scripts: root + "/scripts"
    readonly property string configPath: root + "/config.json"
    readonly property string themeSelectionPath: root + "/theme_selection"
    readonly property string themeOverridesPath: root + "/theme_overrides.json"

    readonly property string home: String(Quickshell.env("HOME") || "")
    readonly property string cacheBase: String(
        Quickshell.env("XDG_CACHE_HOME") || (home + "/.cache"))
    readonly property string runtimeBase: String(
        Quickshell.env("XDG_RUNTIME_DIR") || "/tmp")
    readonly property string cache: cacheBase + "/quickshell"
    readonly property string runtime: runtimeBase + "/quickshell"
    readonly property string wallpaperFreezePath: cache + "/wallpaper_freeze"
    readonly property string minimisedStatePath: cache + "/minimised_windows.json"
    readonly property string gameModeStatePath: runtime + "/game_mode_state"

    function script(name) {
        return scripts + "/" + name
    }

    function expandUserPath(path) {
        const value = String(path || "")
        return value.indexOf("~/") === 0 ? home + value.slice(1) : value
    }
}
