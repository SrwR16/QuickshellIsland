import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool isWebcamActive: false
    property bool isMicActive: false

    Process {
        id: hardwareMonitor
        running: true
        command: [
            "stdbuf", "-oL",
            "sh", "-c",
            "while true; do " +
            "  w=0; fuser /dev/video* 2>/dev/null | grep -q . && w=1; " +
            "  m=0; pactl list source-outputs 2>/dev/null | grep -q 'Source Output' && m=1; " +
            "  echo \"$w,$m\"; " +
            "  echo \"$w,$m\" > /tmp/quickshell_privacy.log; " +
            "  sleep 2; " +
            "done"
        ]
        stdout: SplitParser {
            onRead: (data) => {
                var parts = data.trim().split(",");
                if (parts.length === 2) {
                    root.isWebcamActive = (parts[0] === "1");
                    root.isMicActive = (parts[1] === "1");
                }
            }
        }
    }
}
