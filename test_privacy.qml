import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    PanelWindow {
        width: 200
        height: 200
        color: "black"

        Text {
            anchors.centerIn: parent
            text: "Webcam: " + privacy.isWebcamActive + "\nMic: " + privacy.isMicActive
            color: "white"
        }

        Item {
            id: privacy
            property bool isWebcamActive: false
            property bool isMicActive: false

            Process {
                running: true
                command: [
                    "sh", "-c",
                    "while true; do " +
                    "  w=0; fuser /dev/video* 2>/dev/null | grep -q . && w=1; " +
                    "  m=0; pactl list source-outputs 2>/dev/null | grep -q 'Source Output' && m=1; " +
                    "  echo \"$w,$m\"; " +
                    "  sleep 1; " +
                    "done"
                ]
                stdout: SplitParser {
                    onRead: (data) => {
                        console.log("DATA RECEIVED:", data);
                        var parts = data.trim().split(",");
                        if (parts.length === 2) {
                            privacy.isWebcamActive = (parts[0] === "1");
                            privacy.isMicActive = (parts[1] === "1");
                        }
                    }
                }
            }
        }
    }
}
