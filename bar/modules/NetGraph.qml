import QtQuick
import Quickshell
import Quickshell.Io
import "../../theme"
import "../../components"

// NET ▾ tx/rx mini-graph. Polls /proc/net/dev once per second.
Item {
    id: root
    implicitHeight: Theme.barHeight
    implicitWidth:  inner.implicitWidth

    // ─── State ────────────────────────────────────────────
    property real txRate: 0   // bytes/sec
    property real rxRate: 0
    property real prevTx: -1
    property real prevRx: -1
    property var  txHist: []  // last N samples
    property var  rxHist: []
    property int  histLen: 48
    property real maxRate: 1   // running max for graph scale

    function fmt(bps) {
        if (bps < 1024)        return Math.round(bps) + " B"
        if (bps < 1024 * 1024) return (bps / 1024).toFixed(1) + " K"
        return (bps / (1024 * 1024)).toFixed(2) + " M"
    }

    // ─── Poller ───────────────────────────────────────────
    Process {
        id: netPoll
        // Sum bytes across all real interfaces (skip lo, virbr, docker, veth)
        command: ["sh", "-c",
            "awk -F'[: ]+' 'NR>2 && $2 !~ /^(lo|virbr|docker|veth|br-)/ " +
            "{rx+=$3; tx+=$11} END{print rx,tx}' /proc/net/dev"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(/\s+/)
                if (parts.length < 2) return
                const rx = parseFloat(parts[0])
                const tx = parseFloat(parts[1])
                if (root.prevRx >= 0) {
                    root.rxRate = Math.max(0, rx - root.prevRx)
                    root.txRate = Math.max(0, tx - root.prevTx)
                    // Push samples
                    root.rxHist = (root.rxHist.concat([root.rxRate])).slice(-root.histLen)
                    root.txHist = (root.txHist.concat([root.txRate])).slice(-root.histLen)
                    // Update running max with mild decay so spikes don't dominate forever
                    let m = 1
                    for (let i = 0; i < root.rxHist.length; i++) {
                        if (root.rxHist[i] > m) m = root.rxHist[i]
                        if (root.txHist[i] > m) m = root.txHist[i]
                    }
                    root.maxRate = m
                    canvas.requestPaint()
                }
                root.prevRx = rx
                root.prevTx = tx
            }
        }
    }
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: netPoll.running = true
    }

    // ─── Layout ───────────────────────────────────────────
    Row {
        id: inner
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        LabelCode { code: "NET"; anchors.verticalCenter: parent.verticalCenter }

        // Mini graph
        Canvas {
            id: canvas
            width: 64
            height: Theme.barHeight - 16
            anchors.verticalCenter: parent.verticalCenter

            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                if (root.rxHist.length < 2) return

                const N = root.histLen
                const dx = width / (N - 1)
                const scale = root.maxRate > 0 ? (height - 2) / root.maxRate : 0

                function drawLine(arr, color, fill) {
                    ctx.beginPath()
                    for (let i = 0; i < arr.length; i++) {
                        const x = (N - arr.length + i) * dx
                        const y = height - 1 - arr[i] * scale
                        if (i === 0) ctx.moveTo(x, y)
                        else ctx.lineTo(x, y)
                    }
                    ctx.strokeStyle = color
                    ctx.lineWidth = 1.2
                    ctx.stroke()
                    if (fill) {
                        ctx.lineTo(width, height)
                        ctx.lineTo((N - arr.length) * dx, height)
                        ctx.closePath()
                        ctx.fillStyle = fill
                        ctx.fill()
                    }
                }

                // RX (download) and TX (upload)
                drawLine(root.rxHist, Theme.graphRx,
                         Qt.rgba(Theme.graphRx.r, Theme.graphRx.g, Theme.graphRx.b, 0.18))
                drawLine(root.txHist, Theme.graphTx,
                         Qt.rgba(Theme.graphTx.r, Theme.graphTx.g, Theme.graphTx.b, 0.18))
            }

            Connections {
                target: Theme
                function onThemeChanged() { canvas.requestPaint() }
                function onPaletteChanged() { canvas.requestPaint() }
            }
        }

        // Numeric readouts
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            Text {
                text: "↓ " + root.fmt(root.rxRate)
                color: Theme.teal
                font.family: Theme.fontFamily
                font.pixelSize: Theme.sizeMarker
                font.weight: Font.Medium
            }
            Text {
                text: "↑ " + root.fmt(root.txRate)
                color: Theme.amberHi
                font.family: Theme.fontFamily
                font.pixelSize: Theme.sizeMarker
                font.weight: Font.Medium
            }
        }
    }
}
