import QtQuick
import "../theme"

Rectangle {
    id: root

    color: Theme.variantId === "industrial" ? Theme.bgElev : Theme.bg
    border.color: Theme.variantId === "industrial" ? Theme.chrome : Theme.amber
    border.width: 1
    radius: Theme.controlRadius

    Rectangle {
        visible: Theme.variantId === "industrial"
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 4
        color: Theme.amberDim
    }
}