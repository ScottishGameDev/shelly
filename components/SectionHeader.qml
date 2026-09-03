import QtQuick
import "../theme"

Text {
    property string title: ""

    text: Theme.variantId === "industrial"
        ? title.toUpperCase()
        : "── " + title.toUpperCase() + " ──"
    color: Theme.tealDim
    font.family: Theme.fontFamily
    font.pixelSize: Theme.sizeLabel
    font.weight: Theme.fontWeight
    font.letterSpacing: Theme.labelLetterSpacing
}