pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../services"

// Solar/lunar progress singleton.
// Polls wttr.in every 10 min for sunrise/sunset/
// moonrise/moonset/phase. Recomputes altitudes every 30 s.
QtObject {
    id: root

    // Raw strings as returned by wttr (e.g. "05:27 AM")
    property string sunriseStr: ""
    property string sunsetStr:  ""
    property string moonPhase:  ""
    property int    moonIllum:  0

    // Day/night progress (0..1).
    property real dayProgress: 0
    property real nightProgress: 0
    property bool isDay: false

    // Moon: progress through current up- or down-phase, and whether currently above horizon.
    property real moonProgress: 0
    property bool moonUp: false

    // Signed altitude (-1..1): sin(pi*progress), negative below horizon.
    property real sunAltitude: 0
    property real moonAltitude: 0

    // Direction flags: true while body's altitude is increasing.
    property bool sunRising: true
    property bool moonRising: true

    // Internal: minutes-since-midnight.
    property int sunriseMins:  5 * 60 + 30
    property int sunsetMins:  20 * 60
    property int moonriseMins: -1
    property int moonsetMins:  -1

    function parseClock(s) {
        if (!s) return -1
        const m = s.match(/^\s*(\d{1,2}):(\d{2})\s*([AP]M)\s*$/i)
        if (!m) return -1
        let h = parseInt(m[1])
        const mi = parseInt(m[2])
        const ampm = m[3].toUpperCase()
        if (ampm === "AM") { if (h === 12) h = 0 }
        else                { if (h !== 12) h += 12 }
        return h * 60 + mi
    }

    function recompute() {
        const now = new Date()
        const t = now.getHours() * 60 + now.getMinutes() + now.getSeconds() / 60

        // ── Sun ──
        const rise = sunriseMins
        const set  = sunsetMins
        if (t >= rise && t <= set) {
            isDay = true
            dayProgress = (t - rise) / Math.max(1, set - rise)
            nightProgress = 0
            sunAltitude = Math.sin(Math.PI * dayProgress)
            sunRising = dayProgress < 0.5
        } else {
            isDay = false
            dayProgress = (t < rise) ? 0 : 1
            const nightLen = (24 * 60) - set + rise
            const elapsedN = (t < rise) ? (24 * 60 - set + t) : (t - set)
            nightProgress = Math.max(0, Math.min(1, elapsedN / Math.max(1, nightLen)))
            sunAltitude = -Math.sin(Math.PI * nightProgress)
            sunRising = nightProgress > 0.5
        }

        // ── Moon ──
        if (moonriseMins >= 0 && moonsetMins >= 0) {
            const r = moonriseMins
            const s = moonsetMins
            let up = false
            let prog = 0
            if (r < s) {
                if (t >= r && t <= s) {
                    up = true
                    prog = (t - r) / Math.max(1, s - r)
                } else {
                    up = false
                    const downLen = (24 * 60) - s + r
                    const elapsed = (t < r) ? ((24 * 60 - s) + t) : (t - s)
                    prog = elapsed / Math.max(1, downLen)
                }
            } else {
                if (t >= s && t <= r) {
                    up = false
                    prog = (t - s) / Math.max(1, r - s)
                } else {
                    up = true
                    const upLen = (24 * 60) - r + s
                    const elapsed = (t < s) ? ((24 * 60 - r) + t) : (t - r)
                    prog = elapsed / Math.max(1, upLen)
                }
            }
            moonUp = up
            moonProgress = Math.max(0, Math.min(1, prog))
            moonAltitude = (up ? 1 : -1) * Math.sin(Math.PI * moonProgress)
            moonRising = up ? (moonProgress < 0.5) : (moonProgress > 0.5)
        }
    }

    property var poll: Process {
        command: ["bash", Paths.script("get_weather.sh"), Config.weatherLocation]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(this.text)
                    if (j.sunrise)  { root.sunriseStr = j.sunrise; const m = root.parseClock(j.sunrise);  if (m >= 0) root.sunriseMins  = m }
                    if (j.sunset)   { root.sunsetStr  = j.sunset;  const m = root.parseClock(j.sunset);   if (m >= 0) root.sunsetMins   = m }
                    if (j.moonrise) { const m = root.parseClock(j.moonrise); if (m >= 0) root.moonriseMins = m }
                    if (j.moonset)  { const m = root.parseClock(j.moonset);  if (m >= 0) root.moonsetMins  = m }
                    if (j.moonPhase) root.moonPhase = j.moonPhase
                    if (j.moonIllum) root.moonIllum = parseInt(j.moonIllum) || 0
                    root.recompute()
                } catch (e) { /* ignore */ }
            }
        }
    }

    property var pollTimer: Timer {
        interval: 600000   // 10 min
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.poll.running = true
    }

    property var tickTimer: Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.recompute()
    }
}
