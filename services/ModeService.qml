pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property string currentMode: "0"
    readonly property bool gameMode: currentMode === "1"

    function setMode(mode) {
        if (mode === "desk" || mode === "off") {
            currentMode = "0"
            modeOff.running = true
        } else if (mode === "notifications" || mode === "ntfc") {
            currentMode = "2"
            modeNotifications.running = true
        } else if (mode === "game" || mode === "on") {
            currentMode = "1"
            modeGame.running = true
        }
    }

    property FileView modeState: FileView {
        path: Paths.gameModeStatePath
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: root.currentMode = text().trim()
    }

    property Process modeOff: Process {
        command: ["bash", Paths.script("toggle_mode.sh"), "off", Config.wallpaperDirectory]
    }

    property Process modeNotifications: Process {
        command: ["bash", Paths.script("toggle_mode.sh"), "ntfc", Config.wallpaperDirectory]
    }

    property Process modeGame: Process {
        command: ["bash", Paths.script("toggle_mode.sh"), "on", Config.wallpaperDirectory]
    }
}