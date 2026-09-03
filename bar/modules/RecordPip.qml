import QtQuick
import Quickshell
import Quickshell.Io
import "../../theme"
import "../../components"

// Region-recording indicator. Polls for an active `wf-recorder` process and
// shows a pulsing red dot + REC + elapsed mm:ss while one is running.
// Click to stop (sends SIGINT so the file is finalised cleanly).
Item {
    id: root
    visible: recording
    implicitHeight: Theme.barHeight
    implicitWidth:  visible ? inner.implicitWidth : 0

    property bool recording: false
    property int  elapsed: 0   // seconds

    function fmt(s) {
        const m = Math.floor(s / 60)
        const r = s % 60
        return (m < 10 ? "0" + m : m) + ":" + (r < 10 ? "0" + r : r)
    }

    // ── Poller ────────────────────────────────────────────
    Process {
        id: poll
        // Prefer a stampfile written by the toggler script (records actual start time)
        command: ["sh", "-c",
            "uid=$(id -u); stamp=/tmp/wf-recorder-$uid.start; \
             if [ -f \"$stamp\" ]; then echo $(( $(date +%s) - $(cat \"$stamp\") )); \
             else pid=$(pgrep -x wf-recorder | head -1); [ -n \"$pid\" ] && ps -o etimes= -p \"$pid\" | tr -d ' ' || true; fi"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim()
                if (t.length > 0) {
                    root.recording = true
                    root.elapsed = parseInt(t) || 0
                } else {
                    root.recording = false
                    root.elapsed = 0
                }
            }
        }
    }
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: poll.running = true
    }

    // Stop process (SIGINT to finalise mp4 cleanly)
    Process { id: stopProc }

    // ── Visual ────────────────────────────────────────────
    Row {
        id: inner
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        // Pulsing red dot
        Rectangle {
            id: dot
            width: 10
            height: 10
            radius: 5
            color: Theme.err
            anchors.verticalCenter: parent.verticalCenter
            SequentialAnimation on opacity {
                running: root.recording
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 0.25; duration: 600; easing.type: Easing.InOutSine }
                NumberAnimation { from: 0.25; to: 1.0; duration: 600; easing.type: Easing.InOutSine }
            }
        }

        LabelCode {
            code: "REC"
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.fmt(root.elapsed)
            color: Theme.err
            font.family: Theme.fontFamily
            font.pixelSize: Theme.sizeReadout
            font.weight: Theme.fontWeight
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: {
            stopProc.command = ["sh","-c","pkill -INT -x wf-recorder; rm -f /tmp/wf-recorder-$(id -u).start"]
            stopProc.running = true
        }
    }
}
