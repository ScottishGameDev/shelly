pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    readonly property string freezePath: Paths.wallpaperFreezePath
    property bool frozen: false
    readonly property bool autoCycle: !frozen

    function previous() {
        previousProcess.running = true
    }

    function next() {
        nextProcess.running = true
    }

    function setAutoCycle(enabled) {
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

    property Process previousProcess: Process {
        command: ["bash", Paths.script("wallpaper_shift.sh"), "prev", Config.wallpaperDirectory]
    }

    property Process nextProcess: Process {
        command: ["bash", Paths.script("wallpaper_shift.sh"), "next", Config.wallpaperDirectory]
    }

    property Process freezeWriter: Process {
        running: false
    }
}