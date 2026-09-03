import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../theme"
import "../../components"
import "../../services"

// Weather widget: TMP 24°C  (or [ NO LINK ] on failure)
RowLayout {
    id: root
    spacing: 8

    property string tempText: "—"
    property bool   online: false

    Process {
        id: weatherProc
        command: ["bash", Paths.script("get_weather.sh"), Config.weatherLocation]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const weather = JSON.parse(this.text)
                    if (!weather.tempC) throw new Error("missing temperature")
                    root.online = true
                    root.tempText = weather.tempC + "°C"
                } catch (error) {
                    root.online = false
                    root.tempText = "NO LINK"
                }
            }
        }
    }

    Timer {
        interval: 600000   // 10 min
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: weatherProc.running = true
    }

    LabelCode { code: "TMP" }

    Readout {
        id: readout
        text: root.tempText
        color: root.online ? Theme.teal : Theme.err

        SequentialAnimation on opacity {
            running: !root.online
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 0.4; duration: 600 }
            NumberAnimation { from: 0.4; to: 1.0; duration: 600 }
        }
    }
}
