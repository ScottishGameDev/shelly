import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../components"
import "modules"

// Top bar — anchors top edge across full screen width.
PanelWindow {
    id: bar
    required property ShellScreen modelData
    screen: modelData

    // Module set: full bar shows everything (primary/big monitor); minimal hides tray/minimised/power
    // Identify the "big" monitor by largest resolution rather than name string.
    property bool fullModuleSet: modelData ? (modelData.width >= 3000) : true

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight
    color: Theme.bg

    // ── CRT flicker ─────────────────────────────────────────────────────
    // Subtly drops bar opacity for ~80ms at random intervals.
    property real flicker: 1.0
    Timer {
        interval: 1500 + Math.random() * 4000
        running: Fx.flicker
        repeat: true
        onTriggered: {
            bar.flicker = 0.88 + Math.random() * 0.06
            flickerRecover.start()
            interval = 1500 + Math.random() * 4000
        }
    }
    Timer {
        id: flickerRecover
        interval: 70 + Math.random() * 60
        onTriggered: bar.flicker = 1.0
    }

    // ── CRT roll bar ────────────────────────────────────────────────────
    // A faint horizontal band drifts vertically through the bar every ~12s.
    Rectangle {
        id: rollBar
        anchors.left: parent.left
        anchors.right: parent.right
        height: 12
        z: 99
        opacity: 0.0
        visible: Fx.rollBar
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: "#00000000" }
            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.08) }
            GradientStop { position: 1.0; color: "#00000000" }
        }
        SequentialAnimation on y {
            loops: Animation.Infinite
            PauseAnimation { duration: 8000 }
            ScriptAction { script: rollBar.opacity = 0.9 }
            NumberAnimation {
                from: -16
                to: bar.implicitHeight + 16
                duration: 1800
                easing.type: Easing.InOutSine
            }
            ScriptAction { script: rollBar.opacity = 0.0 }
        }
    }

    // ── Animated scanlines + distortion ────────────────────────────────
    Canvas {
        id: scanlines
        anchors.fill: parent
        z: 100
        enabled: false   // pass clicks through
        visible: Fx.scanlines
        opacity: bar.flicker

        property real offset: 0   // scroll position (0–3 px cycle)
        property real phase:  0   // sine wave phase

        Timer {
            interval: 16          // 60 fps
            running: Fx.scanlines
            repeat: true
            onTriggered: {
                scanlines.offset = (scanlines.offset + 0.18) % 3
                scanlines.phase  += 0.028
                scanlines.requestPaint()
            }
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.fillStyle = "#000000"
            var spacing = 3
            var n = Math.ceil(height / spacing) + 1
            for (var i = 0; i < n; i++) {
                var y  = (i * spacing + offset) % (height + spacing) - spacing
                // gentle horizontal wobble — amp 1.5 px, frequency varies with y
                var dx = Math.sin(y * 0.28 + phase) * 1.5
                       + Math.sin(y * 0.07 + phase * 0.4) * 0.8
                ctx.globalAlpha = 0.65
                ctx.fillRect(dx, y, width, 1)
            }
        }
    }
    // ── Subtle filmic top-edge gradient ────────────────────
    Rectangle {
        anchors.fill: parent
        visible: Theme.variantId === "cyberpunk"
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(Theme.bg, 1.15) }
            GradientStop { position: 0.4; color: Theme.bg }
            GradientStop { position: 1.0; color: Theme.bg }
        }
        opacity: 0.6
        z: -1
    }

    // Industrial surface: pale structural band with a datum rail.
    Rectangle {
        anchors.fill: parent
        visible: Theme.variantId === "industrial"
        color: Theme.bgElev
        z: -1
    }
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: Theme.variantId === "industrial"
        height: 1
        color: Theme.chrome
        enabled: false
        z: 97
    }
    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        visible: Theme.variantId === "industrial"
        width: Math.min(parent.width * 0.28, 720)
        height: 4
        color: Theme.amberDim
        enabled: false
        z: 97
    }

    // ── Vignette (darken left/right edges, like uneven CRT illumination) ──
    Rectangle {
        anchors.fill: parent
        z: 98
        enabled: false
        visible: Fx.vignette
        gradient: Gradient {
            GradientStop { position: 0.0;  color: Qt.rgba(0, 0, 0, 0.45) }
            GradientStop { position: 0.15; color: "#00000000" }
            GradientStop { position: 0.85; color: "#00000000" }
            GradientStop { position: 1.0;  color: Qt.rgba(0, 0, 0, 0.45) }
        }
    }

    // ── Layout: left | center | right ──────────────────────
    Item {
        anchors.fill: parent
        anchors.leftMargin: Theme.gutter
        anchors.rightMargin: Theme.gutter
        opacity: Fx.flicker ? bar.flicker : 1.0

        Workspaces {
            id: wsRow
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            screenName: bar.modelData ? bar.modelData.name : ""
        }

        // CENTER
        Loader {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            sourceComponent: Component { Music {} }
        }

        // RIGHT
        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.gutter

            Loader { active: bar.fullModuleSet; sourceComponent: Component { Minimised {} } }
            Loader { active: bar.fullModuleSet; sourceComponent: Component { Tray {} } }

            Loader { active: bar.fullModuleSet; sourceComponent: Component { RecordPip {} } }
            Loader { active: bar.fullModuleSet; sourceComponent: Component { NetGraph {} } }

            // Weather with dashed border
            Item {
                implicitWidth:  weatherInner.implicitWidth  + 12
                implicitHeight: Theme.barHeight
                Weather {
                    id: weatherInner
                    anchors.centerIn: parent
                }
                DashFrame {
                    anchors.fill: parent
                    visible: Theme.weatherFrameVisible
                    dashed: Theme.weatherFrameDashed
                    pad: 0
                }
            }
            // Clock with dashed border
            Item {
                implicitWidth:  clockInner.implicitWidth  + 16
                implicitHeight: clockInner.implicitHeight
                Clock {
                    id: clockInner
                    anchors.centerIn: parent
                }
                DashFrame {
                    anchors.fill: parent
                    visible: Theme.clockFrameVisible
                    dashed: Theme.clockFrameDashed
                    pad: 0
                }
            }

            Loader { active: bar.fullModuleSet; sourceComponent: Component { Power {} } }
        }
    }
}
