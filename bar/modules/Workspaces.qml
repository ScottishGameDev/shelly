import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../../theme"
import "../../components"
import "../../services"

// Workspaces row, scoped to a single monitor.
RowLayout {
    id: root
    property string screenName: ""   // Hyprland monitor connector name
    spacing: 8

    Chip {
        text: "+"
        onClicked: newWsProc.running = true
        Process {
            id: newWsProc
            command: ["bash", Paths.script("create_workspace.sh")]
        }
    }

    Repeater {
        model: ScriptModel {
            values: {
                const out = []
                const all = Hyprland.workspaces.values
                for (let i = 0; i < all.length; i++) {
                    const ws = all[i]
                    if (!root.screenName) { out.push(ws); continue }
                    if (ws.monitor && ws.monitor.name === root.screenName) out.push(ws)
                }
                return out
            }
        }
        delegate: Chip {
            required property var modelData
            text: (modelData.active ? "▶ " : "") + "WS-" + modelData.id
            active: modelData.active
            bracketed: false
            onClicked: Hyprland.dispatch("workspace " + modelData.id)
        }
    }
}
