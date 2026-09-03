import QtQuick
import "../theme"

// ALL CAPS letterspaced terminal-style label code (e.g. "TMP", "SYS", "WS").
Text {
    property string code: ""
    text: code.toUpperCase()
    color: Theme.teal
    opacity: Theme.labelOpacity
    font.family: Theme.fontFamily
    font.pixelSize: Theme.sizeLabel
    font.letterSpacing: Theme.labelLetterSpacing
    font.weight: Theme.fontWeight
    verticalAlignment: Text.AlignVCenter
}
