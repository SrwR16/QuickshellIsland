import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
  property int battery: 0
  property bool charging: false
  property string wifi: "Disconnected"
  property int wifiSignal: 0

  property Timer pollTimer: Timer {
    interval: 5000; running: true; repeat: true; triggeredOnStart: true
    onTriggered: { pollProc.running = true }
  }

  property Process pollProc: Process {
    command: [
      "sh", "-c",
      "cap=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1); " +
      "st=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1); " +
      "ssid=$(nmcli -t -f TYPE,NAME con show --active 2>/dev/null | grep '^802-11-wireless:' | cut -d: -f2 -s); " +
      "[ -z \"$ssid\" ] && ssid=$(iwgetid -r 2>/dev/null); " +
      "[ -z \"$ssid\" ] && ssid=Disconnected; " +
      "sig=$(awk 'NR>2{if($3!=\"\"){gsub(/\\./,\"\",$3); q=$3+0; print int(q*100/70)}}' /proc/net/wireless 2>/dev/null || echo 0); " +
      "echo \"${cap:-0}\"; echo \"${st:-Unknown}\"; echo \"$ssid\"; echo \"$sig\""
    ]
    stdout: SplitParser {
      onRead: (data) => {
        var lines = data.trim().split("\n");
        if (lines.length >= 4) {
          battery = parseInt(lines[0]) || 0;
          charging = lines[1].trim() === "Charging";
          wifi = lines[2].trim() || "Disconnected";
          wifiSignal = Math.min(100, Math.max(0, parseInt(lines[3]) || 0));
        }
      }
    }
  }
}
