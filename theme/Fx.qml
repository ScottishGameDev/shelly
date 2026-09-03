pragma Singleton
import QtQuick
import "../services"

// Global FX master switch. Disabled while game mode is on.
// Per-effect props are convenience aliases of `enabled`.
QtObject {
    id: root
    // master toggle (manual override)
    property bool userEnabled: true
    readonly property bool gameMode: ModeService.gameMode
    readonly property bool enabled: userEnabled && !gameMode

    readonly property bool scanlines: enabled && Theme.effects.scanlines
    readonly property bool vignette:  enabled && Theme.effects.vignette
    readonly property bool flicker:   enabled && Theme.effects.flicker
    readonly property bool rollBar:   enabled && Theme.effects.rollBar
    readonly property bool bloom:     enabled && Theme.effects.bloom
}
