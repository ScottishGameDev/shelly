import QtQuick
import "../theme"

// Draws a dashed rectangle border around its child content.
// Usage: wrap any item — DashFrame { child: SomeWidget {} }
Item {
    id: root

    property Item child: null
    property color frameColor: Theme.chrome
    property int   dash:  4    // px on
    property int   gap:   4    // px off
    property int   pad:   6    // inner padding
    property bool  dashed: Theme.dashedFrames

    implicitWidth:  child ? child.implicitWidth  + pad * 2 : 0
    implicitHeight: child ? child.implicitHeight + pad * 2 : 0

    onChildChanged: {
        if (child) {
            child.parent = contentArea
            child.anchors.centerIn = contentArea
        }
    }

    Item {
        id: contentArea
        anchors.fill: parent
        anchors.margins: pad
    }

    Canvas {
        id: frameCanvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = root.frameColor
            ctx.lineWidth = 1.5
            ctx.setLineDash(root.dashed ? [root.dash, root.gap] : [])
            ctx.lineDashOffset = 0
            ctx.beginPath()
            ctx.rect(0.75, 0.75, width - 1.5, height - 1.5)
            ctx.stroke()
        }
        // repaint if color changes (e.g. from live picker)
        Connections {
            target: root
            function onFrameColorChanged() { frameCanvas.requestPaint() }
            function onDashedChanged() { frameCanvas.requestPaint() }
        }
    }
}
