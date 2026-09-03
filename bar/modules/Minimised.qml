import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../theme"
import "../../components"
import "../../services"

// MIN :: <minimised window chips from minimised_windows.json>
RowLayout {
    id: root
    spacing: 8

    property var items: []

    FileView {
        id: minFile
        path: Config.minimisedStateFile
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try { root.items = JSON.parse(this.text() || "[]") }
            catch (e) { root.items = [] }
        }
    }

    Component.onCompleted: minFile.reload()

    LabelCode {
        code: "MIN"
        visible: root.items.length > 0
    }

    Repeater {
        model: root.items
        delegate: Chip {
            required property var modelData
            text: "◂ " + (modelData.icon || "?") + " " + (modelData.title || "")
            bracketed: false
            onClicked: restoreProc.running = true
            Process {
                id: restoreProc
                command: ["sh", "-c",
                    "workspace=$(hyprctl activeworkspace -j | jq -r '.id'); id=\"$1\"; file=\"$2\"; " +
                    "hyprctl dispatch movetoworkspacesilent \"$workspace,address:$id\" && " +
                    "hyprctl dispatch focuswindow \"address:$id\" && " +
                    "tmp=\"$file.tmp\"; jq --arg id \"$id\" 'map(select(.id != $id))' \"$file\" > \"$tmp\" && " +
                    "mv \"$tmp\" \"$file\"",
                    "sh", modelData.id, Config.minimisedStateFile
                ]
            }
        }
    }
}
