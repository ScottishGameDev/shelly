pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    readonly property string freezePath: Paths.wallpaperFreezePath
    property bool frozen: false
    readonly property bool imageMode: Config.wallpaperMode === "images"
    readonly property bool autoCycle: imageMode && !frozen
    property string pendingAction: ""

    function previous() {
        if (!imageMode) return
        run("prev")
    }

    function next() {
        if (!imageMode) return
        run("next")
    }

    function apply() {
        run("restore")
    }

    function run(action) {
        pendingAction = action
        if (!wallpaperProcess.running) startPending()
    }

    function startPending() {
        if (!pendingAction) return
        const action = pendingAction
        pendingAction = ""
        wallpaperProcess.command = [
            "bash", Paths.script("wallpaper_shift.sh"), action,
            Config.wallpaperDirectory, Config.wallpaperMode, Config.wallpaperColor
        ]
        wallpaperProcess.running = true
    }

    function setAutoCycle(enabled) {
        if (!imageMode) return
        const nextFrozen = !enabled
        frozen = nextFrozen
        freezeWriter.command = ["sh", "-c",
            "mkdir -p \"$(dirname \"$1\")\"; tmp=\"$1.tmp\"; printf '%s' \"$2\" > \"$tmp\" && mv \"$tmp\" \"$1\"",
            "sh", freezePath, nextFrozen ? "1" : "0"]
        freezeWriter.running = true
    }

    property FileView freezeState: FileView {
        path: root.freezePath
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: root.frozen = text().trim() === "1"
    }

    property Process wallpaperProcess: Process {
        running: false
        onExited: root.startPending()
    }

    property Connections configConnections: Connections {
        target: Config
        function onWallpaperChanged() { root.apply() }
    }

    property Process freezeWriter: Process {
        running: false
    }
}