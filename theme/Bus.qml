pragma Singleton
import QtQuick

QtObject {
    signal showRequested(var scr, real centerX)
    signal powerMenuRequested(var scr, real centerX)
    signal ws2MenuRequested(var scr, real centerX)
    signal musicMenuRequested(var scr, real centerX, var player)
    signal trayMenuRequested(var scr, real x, real y, var menu)
    signal controlCenterRequested(var scr, real centerX)
    signal themeEditorRequested(var scr, real centerX)
    signal colorPickerRequested(var scr, real preferredLeftX, real leftBoundaryX,
                                real centerY,
                                string title, color initialColor, var editCallback)
    signal colorPickerDismissRequested()
    signal colorPickerVisibilityChanged(bool visible)
}
