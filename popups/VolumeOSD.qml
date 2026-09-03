import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../theme"
import "../components"

// Auto-popup volume OSD. Appears for ~1.6s whenever the default sink's
// volume or mute state changes (e.g. via XF86AudioRaiseVolume keybind).
PanelWindow {
    id: root

    // Pin to top of the primary (largest) screen by default.
    screen: {
        let pick = Quickshell.screens[0]
        for (let i = 1; i < Quickshell.screens.length; i++)
            if (Quickshell.screens[i].width > pick.width) pick = Quickshell.screens[i]
        return pick
    }
    anchors { top: true; left: true }
    property real anchorX: (root.screen ? root.screen.width - implicitWidth - 24 + implicitWidth / 2 : 0)
    margins { top: Theme.barHeight + 12; left: Math.max(4, anchorX - implicitWidth / 2) }
    implicitWidth: 110
    implicitHeight: 300
    color: "transparent"
    visible: false
    exclusionMode: ExclusionMode.Ignore

    // ── Pipewire binding ───────────────────────────────────
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real vol: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

    property real lastVol: -1
    property bool lastMuted: false

    Connections {
        target: root.sink && root.sink.audio ? root.sink.audio : null
        function onVolumeChanged() { root.showOsd() }
        function onMutedChanged()  { root.showOsd() }
    }

    // External trigger (e.g. right-click on VOL chip)
    Connections {
        target: Bus
        function onShowRequested(scr, cx) {
            if (scr) root.screen = scr
            if (cx) root.anchorX = cx
            root.lastVol = root.vol
            root.lastMuted = root.muted
            root.visible = true
            hideTimer.restart()
        }
    }

    function showOsd() {
        // Skip the very first emission at startup (no real change yet)
        if (lastVol < 0) { lastVol = vol; lastMuted = muted; return }
        if (Math.abs(lastVol - vol) < 0.001 && lastMuted === muted) return
        lastVol = vol
        lastMuted = muted
        visible = true
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 1600
        onTriggered: root.visible = false
    }

    // ── Panel ──────────────────────────────────────────────
    PopupSurface {
        id: panel
        anchors.fill: parent
        anchors.margins: 8
        clip: true

        // Header
        SectionHeader {
            id: header
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            title: root.muted ? "Mute" : "Volume"
            color: root.muted ? Theme.err : Theme.tealDim
        }

        // Footer numeric
        Text {
            id: footer
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round(root.vol * 100) + "%"
            color: root.muted ? Theme.err : Theme.amberHi
            font.family: Theme.fontFamily
            font.pixelSize: Theme.sizeReadout
            font.weight: Theme.fontWeight
        }

        // Segmented bar (20 segments, top = max)
        Column {
            id: bar
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: header.bottom
            anchors.bottom: footer.top
            anchors.topMargin: 10
            anchors.bottomMargin: 10
            width: 60
            spacing: 2

            Repeater {
                model: 20
                delegate: Rectangle {
                    required property int index
                    width: 60
                    height: (parent.height - parent.spacing * 19) / 20
                    readonly property int segIdx: 19 - index   // top = 19
                    readonly property bool lit: segIdx < Math.round(root.vol * 20)
                    readonly property bool isTop: lit && segIdx === Math.round(root.vol * 20) - 1
                    color: root.muted ? (lit ? Theme.err : Theme.bgElev)
                                      : (lit ? (isTop ? Theme.amberHi : Theme.amber) : Theme.bgElev)
                    opacity: lit ? 1.0 : 0.4

                    SequentialAnimation on opacity {
                        running: isTop && !root.muted
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 0.55; duration: 600 }
                        NumberAnimation { from: 0.55; to: 1.0; duration: 600 }
                    }
                }
            }
        }

        // Click / drag area over the segmented bar to set volume.
        // Slightly wider than the bar for easier targeting.
        MouseArea {
            anchors.top: header.bottom
            anchors.bottom: footer.top
            anchors.topMargin: 10
            anchors.bottomMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            width: bar.width + 24
            acceptedButtons: Qt.LeftButton
            preventStealing: true

            property int lastSeg: -1

            function setFromY(y) {
                if (!root.sink || !root.sink.audio) return
                const h = height
                if (h <= 0) return
                let frac = 1.0 - (y / h)
                if (frac < 0) frac = 0
                if (frac > 1) frac = 1
                // Snap to one of the 20 segments to throttle updates
                const seg = Math.round(frac * 20)
                if (seg === lastSeg) return
                lastSeg = seg
                root.sink.audio.volume = seg / 20
                if (root.sink.audio.muted) root.sink.audio.muted = false
                hideTimer.restart()
            }

            onPressed: (mouse) => { lastSeg = -1; setFromY(mouse.y) }
            onPositionChanged: (mouse) => { if (pressed) setFromY(mouse.y) }
        }
    }
}
