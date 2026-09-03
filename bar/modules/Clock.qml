import QtQuick
import Quickshell
import "../../theme"
import "../../components"

// Clock readout flanked by two altitude bars:
//   ▍◤ NOW HH:MM │ DOW dd/mm ◢▍
// Left bar  = sun (amber).  Right bar = moon (silver).
// Each bar has a horizon line at vertical mid; a filled cap grows above the line
// when the body is above the horizon, below when it is below. Cap length ∝ |sin(π·progress)|.
// A ▲/▼ glyph at the outer tip indicates rising / falling.
Item {
    id: root
    implicitHeight: Theme.barHeight
    implicitWidth:  innerRow.implicitWidth

    SystemClock { id: clock; precision: SystemClock.Seconds }

    function pad(n) { return n < 10 ? "0" + n : "" + n }
    function dayOfWeek(d) {
        return ["SUN","MON","TUE","WED","THU","FRI","SAT"][d.getDay()]
    }
    property bool blink: clock.date.getSeconds() % 2 === 0

    // ── Body altitude bar component ───────────────────────
    // Thick horizontal line at altitude position + animated chevrons inside
    // the bar showing direction of travel. At least one chevron is always
    // visible so direction is clear even when the body is near the horizon.
    component AltBar : Item {
        id: bar
        property real altitude: 0          // -1..1, +1 = top, -1 = bottom
        property bool rising: true
        property color tint: Theme.amber
        property color tintDim: Theme.amberDim

        implicitWidth: 18
        implicitHeight: Theme.barHeight - 4

        // outer frame
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: bar.tintDim
            border.width: 2
            radius: 2
        }
        // horizon line
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 1
            color: bar.tintDim
            opacity: 0.6
        }

        // ── Animated chevron column behind the trailing edge ─────────
        // When rising, trailing edge is BELOW the marker (sun came from down).
        // When falling, trailing edge is ABOVE the marker.
        Item {
            id: chevClip
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 2
            clip: true
            // Position so the column starts at marker and extends to the
            // trailing edge of the bar.
            y: bar.rising ? marker.y + marker.height : 2
            height: bar.rising
                ? Math.max(0, parent.height - 2 - (marker.y + marker.height))
                : Math.max(0, marker.y - 2)

            property real offset: 0
            property int  spacing: 11

            NumberAnimation on offset {
                from: 0
                to: chevClip.spacing
                duration: 1400
                loops: Animation.Infinite
                running: true
            }

            Repeater {
                model: Math.ceil(chevClip.height / chevClip.spacing) + 2
                delegate: Canvas {
                    required property int index
                    width: chevClip.width
                    height: 7
                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.reset()
                        ctx.clearRect(0, 0, width, height)
                        ctx.strokeStyle = bar.tint
                        ctx.lineWidth = 2
                        ctx.lineCap = "round"
                        ctx.lineJoin = "round"
                        const cx = width / 2
                        const pad = 3
                        ctx.beginPath()
                        if (bar.rising) {
                            ctx.moveTo(pad, height - 1)
                            ctx.lineTo(cx, 1)
                            ctx.lineTo(width - pad, height - 1)
                        } else {
                            ctx.moveTo(pad, 1)
                            ctx.lineTo(cx, height - 1)
                            ctx.lineTo(width - pad, 1)
                        }
                        ctx.stroke()
                    }
                    Connections {
                        target: bar
                        function onRisingChanged() { requestPaint() }
                        function onTintChanged()   { requestPaint() }
                    }
                    opacity: 0.4
                    y: {
                        const base = chevClip.height - (index + 1) * chevClip.spacing
                        const o = bar.rising ? -chevClip.offset : chevClip.offset
                        let v = base + o
                        const span = chevClip.height + chevClip.spacing
                        v = ((v % span) + span) % span - chevClip.spacing
                        return v
                    }
                }
            }
        }

        // ── Altitude marker: bold chevron pointing in direction of motion
        Canvas {
            id: marker
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 2
            height: 9
            // map altitude (-1..1) to y inside bar
            y: ((1 - bar.altitude) / 2) * (parent.height - height)

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                ctx.clearRect(0, 0, width, height)
                ctx.strokeStyle = bar.tint
                ctx.lineWidth = 3
                ctx.lineCap = "round"
                ctx.lineJoin = "round"
                const cx = width / 2
                const pad = 2
                ctx.beginPath()
                if (bar.rising) {
                    ctx.moveTo(pad, height - 2)
                    ctx.lineTo(cx, 2)
                    ctx.lineTo(width - pad, height - 2)
                } else {
                    ctx.moveTo(pad, 2)
                    ctx.lineTo(cx, height - 2)
                    ctx.lineTo(width - pad, 2)
                }
                ctx.stroke()
            }
            Connections {
                target: bar
                function onRisingChanged() { marker.requestPaint() }
                function onTintChanged()   { marker.requestPaint() }
            }

            Behavior on y { NumberAnimation { duration: 600; easing.type: Easing.InOutQuad } }
        }
    }

    Row {
        id: innerRow
        anchors.centerIn: parent
        spacing: 10

        AltBar {
            anchors.verticalCenter: parent.verticalCenter
            altitude: Astro.sunAltitude
            rising:   Astro.sunRising
            tint:     Theme.sunHi
            tintDim:  Theme.sunDim
        }

        LabelCode { code: "NOW"; anchors.verticalCenter: parent.verticalCenter }
        Readout {
            anchors.verticalCenter: parent.verticalCenter
            text: root.pad(clock.date.getHours()) + (root.blink ? ":" : " ") + root.pad(clock.date.getMinutes())
            color: Theme.amberHi
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "│"
            color: Theme.tealDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.sizeReadout
        }
        Readout {
            anchors.verticalCenter: parent.verticalCenter
            text: root.dayOfWeek(clock.date) + " " + root.pad(clock.date.getDate()) + "/" + root.pad(clock.date.getMonth() + 1)
            color: Theme.teal
        }

        AltBar {
            anchors.verticalCenter: parent.verticalCenter
            altitude: Astro.moonAltitude
            rising:   Astro.moonRising
            tint:     Theme.moon
            tintDim:  Theme.moonDim
        }
    }
}
