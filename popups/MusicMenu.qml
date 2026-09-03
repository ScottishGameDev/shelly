import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "../theme"
import "../components"
import "../services"

// Music transport popup — drops under the bar's music readout on right-click.
// Mirrors the eww `window_music`: prev | album-art (click=focus Spotify) | next.
PanelWindow {
    id: root

    anchors { top: true; left: true }
    margins { top: Theme.barHeight + 4; left: Math.max(4, anchorX - implicitWidth / 2) }
    implicitWidth: 380
    implicitHeight: 160
    color: "transparent"
    visible: false
    exclusionMode: ExclusionMode.Ignore

    property real anchorX: 0
    property var player: null

    function open() { visible = true; graceTimer.restart() }
    function close() { visible = false }

    Component.onCompleted: {
        Bus.musicMenuRequested.connect(function(scr, cx, p) {
            root.screen = scr
            root.anchorX = cx
            root.player = p
            artPoll.running = true
            root.open()
        })
    }

    property bool inGrace: false
    Timer { id: graceTimer; interval: 1500; onTriggered: root.inGrace = false }
    onVisibleChanged: if (visible) inGrace = true

    HoverHandler {
        id: hover
        onHoveredChanged: if (!hovered) closeTimer.restart()
    }
    Timer {
        id: closeTimer
        interval: 400
        onTriggered: if (!hover.hovered && !root.inGrace) root.close()
    }

    // Album artwork cache.
    property string artPath: ""
    Process {
        id: artPoll
        command: ["bash", Paths.script("spotify_artwork.sh")]
        stdout: StdioCollector { onStreamFinished: root.artPath = text.trim() }
    }
    Timer {
        running: root.visible
        interval: 5000
        repeat: true
        onTriggered: artPoll.running = true
    }

    PopupSurface {
        id: panel
        anchors.fill: parent
        anchors.margins: 12

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            SectionHeader {
                Layout.alignment: Qt.AlignHCenter
                title: "Now Playing"
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                // Prev
                Rectangle {
                    Layout.preferredWidth: 64
                    Layout.fillHeight: true
                    color: prevHover.hovered ? Theme.controlHoverBg : "transparent"
                    border.color: Theme.controlBorder
                    border.width: 1
                    radius: Theme.controlRadius
                    HoverHandler { id: prevHover }
                    TapHandler {
                        onTapped: {
                            ctlProc.command = ["playerctl", "previous", "-p", "spotify"]
                            ctlProc.running = true
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "[ \u25C2\u25C2 ]"
                        color: prevHover.hovered ? Theme.controlHoverFg : Theme.controlFg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.sizeReadout
                    }
                }

                // Artwork (click = focus Spotify)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Theme.bg
                    border.color: artHover.hovered ? Theme.controlFocus : Theme.controlBorder
                    border.width: 1
                    radius: Theme.controlRadius
                    HoverHandler { id: artHover }
                    TapHandler { onTapped: focusProc.running = true }
                    Image {
                        anchors.fill: parent
                        anchors.margins: 4
                        source: root.artPath ? "file://" + root.artPath : ""
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        visible: root.artPath !== ""
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: !root.artPath
                        text: "\u266B"
                        color: Theme.tealDim
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.sizeIconLarge
                    }
                }

                // Next
                Rectangle {
                    Layout.preferredWidth: 64
                    Layout.fillHeight: true
                    color: nextHover.hovered ? Theme.controlHoverBg : "transparent"
                    border.color: Theme.controlBorder
                    border.width: 1
                    radius: Theme.controlRadius
                    HoverHandler { id: nextHover }
                    TapHandler {
                        onTapped: {
                            ctlProc.command = ["playerctl", "next", "-p", "spotify"]
                            ctlProc.running = true
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "[ \u25B8\u25B8 ]"
                        color: nextHover.hovered ? Theme.controlHoverFg : Theme.controlFg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.sizeReadout
                    }
                }
            }
        }
    }

    Process {
        id: focusProc
        command: ["bash", Paths.script("switch_to_spotify.sh")].concat(Config.spotifyCommand)
    }
    Process { id: ctlProc }
}
