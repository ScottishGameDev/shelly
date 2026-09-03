import QtQuick
import "../theme"

// Four faint corner brackets framing arbitrary content (use as background of a Layout).
// Set `corners: ["tl","tr","bl","br"]` to choose which to draw.
Item {
    id: root
    property color color: Theme.chrome
    property int thickness: 2
    property int armLength: Theme.cornerArmLength
    property var corners: ["tl", "tr", "bl", "br"]

    Repeater {
        model: root.corners
        delegate: Item {
            anchors.fill: parent
            // horizontal arm
            Rectangle {
                width: root.armLength
                height: root.thickness
                color: root.color
                x: (modelData === "tl" || modelData === "bl") ? 0 : (parent.width - width)
                y: (modelData === "tl" || modelData === "tr") ? 0 : (parent.height - height)
            }
            // vertical arm
            Rectangle {
                width: root.thickness
                height: root.armLength
                color: root.color
                x: (modelData === "tl" || modelData === "bl") ? 0 : (parent.width - width)
                y: (modelData === "tl" || modelData === "tr") ? 0 : (parent.height - height)
            }
        }
    }
}
