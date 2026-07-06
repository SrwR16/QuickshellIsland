import QtQuick
import Quickshell.Io



QtObject {
    id: root

    property real brightness: 0
    property bool capsLock: false
    property bool numLock: false
    property real kbdBrightness: 0

    property Process pollProc: Process {
        command: [
            "sh", "-c",
            "while true; do " +
            "  b=$(brightnessctl -m 2>/dev/null | head -1 | cut -d, -f4 | tr -d '%' || echo 0); " +
            "  c=$(hyprctl devices -j 2>/dev/null | grep -q '\"capsLock\": true' && echo 1 || echo 0); " +
            "  n=$(hyprctl devices -j 2>/dev/null | grep -q '\"numLock\": true' && echo 1 || echo 0); " +
            "  k=$(brightnessctl -d '*kbd_backlight*' -m 2>/dev/null | head -1 | cut -d, -f4 | tr -d '%' || echo 0); " +
            "  echo \"b=$b\"; echo \"c=$c\"; echo \"n=$n\"; echo \"k=$k\"; " +
            "  sleep 0.05; " +
            "done"
        ]
        running: true
        stdout: SplitParser {
            onRead: (data) => {
                var line = data.trim();
                if (line.length < 2 || line.charAt(1) !== '=') return;
                var val = line.substring(2);
                if (line.charAt(0) === 'b') {
                    var pct = parseInt(val);
                    if (!isNaN(pct)) root.brightness = Math.max(0, Math.min(1, pct / 100));
                } else if (line.charAt(0) === 'c') {
                    root.capsLock = val.trim() === "1";
                } else if (line.charAt(0) === 'n') {
                    root.numLock = val.trim() === "1";
                } else if (line.charAt(0) === 'k') {
                    var kpct = parseInt(val);
                    if (!isNaN(kpct)) root.kbdBrightness = Math.max(0, Math.min(1, kpct / 100));
                }
            }
        }
    }
}
