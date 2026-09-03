import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "../../theme"
import "../../components"
import "../../services"

// Spotify-only music readout. Layout: <artist>  ▶/⏸  <title>
// The play/pause glyph sits dead-center of the bar; artist and title flank it.
Item {
    id: root
    implicitWidth: 600
    implicitHeight: Theme.barHeight

    // ── Spotify picker ─────────────────────────────────────
    property var player: null
    function pickSpotify() {
        const list = Mpris.players.values
        for (let i = 0; i < list.length; i++) {
            const p = list[i]
            const id = (p.identity || "").toLowerCase()
            const dn = (p.dbusName || "").toLowerCase()
            if (id.indexOf("spotify") !== -1 || dn.indexOf("spotify") !== -1) {
                player = p
                return
            }
        }
        player = null
    }
    Component.onCompleted: pickSpotify()
    Connections {
        target: Mpris.players
        function onValuesChanged() { root.pickSpotify() }
    }

    property bool playing: player && player.playbackState === MprisPlaybackState.Playing
    property string title:  player ? (player.trackTitle  || "") : ""
    property string artist: player ? (player.trackArtist || "") : ""
    property bool hasTrack: title.length > 0 || artist.length > 0

    // ── Centered play/pause glyph ─────────────────────────
    Text {
        id: glyph
        anchors.centerIn: parent
        visible: root.hasTrack
        text: root.playing ? "\u25B6" : "\u23F8"
        color: root.playing ? Theme.pink : Theme.amber
        font.family: Theme.fontFamily
        font.pixelSize: Theme.sizeReadout
        layer.enabled: root.hasTrack
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: glyph.color
            shadowOpacity: 0.9
            shadowBlur: 1.0
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            blurMax: 16
        }    }

    // Idle banner (no glyph) when nothing is playing
    Text {
        id: idleText
        anchors.centerIn: parent
        visible: !root.hasTrack
        text: "── NO SIGNAL ──"
        color: Theme.tealDim
        font.family: Theme.fontFamily
        font.pixelSize: Theme.sizeReadout
        font.letterSpacing: 1.5
    }

    Readout {
        id: artistText
        anchors.right: glyph.left
        anchors.rightMargin: 14
        anchors.verticalCenter: glyph.verticalCenter
        text: root.artist
        color: Theme.amberHi
        elide: Text.ElideLeft
        horizontalAlignment: Text.AlignRight
        width: Math.min(implicitWidth, 320)
        visible: root.hasTrack
    }

    Readout {
        id: titleText
        anchors.left: glyph.right
        anchors.leftMargin: 14
        anchors.verticalCenter: glyph.verticalCenter
        text: root.title
        color: Theme.amberHi
        elide: Text.ElideRight
        width: Math.min(implicitWidth, 320)
        visible: root.hasTrack
    }

    Text {
        anchors.left: glyph.right
        anchors.leftMargin: 14
        anchors.verticalCenter: glyph.verticalCenter
        visible: false
        text: ""
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(m) {
            // No player -> launch Spotify on left, ignore right
            if (!root.player) {
                if (m.button === Qt.LeftButton) launchSpotify.running = true
                return
            }
            if (m.button === Qt.RightButton) {
                let p = mapToItem(null, glyph.x + glyph.width / 2, 0)
                Bus.musicMenuRequested(QsWindow.window.screen, p.x, root.player)
                return
            }
            if (root.playing) root.player.pause()
            else root.player.play()
        }
    }

    Process {
        id: launchSpotify
        command: ["bash", Paths.script("switch_to_spotify.sh")].concat(Config.spotifyCommand)
    }
}
