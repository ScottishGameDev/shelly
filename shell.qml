//@ pragma UseQApplication
import QtQuick
import Quickshell
import "bar"
import "popups"

// Root shell: per-screen bar + global volume OSD.
ShellRoot {
    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }
    Component.onCompleted: console.log("QApplication:", Qt.application.name, typeof QApplication)
    VolumeOSD {}
    PowerMenu {}
    WS2Menu {}
    ControlCenter {}
    ThemeEditor {}
    ColorPickerPopup {}
    MusicMenu {}
    TrayMenu {} 
}
