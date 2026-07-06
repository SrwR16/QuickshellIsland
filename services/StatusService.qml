import "../overlay"
import "../widgets"
import "../services"
import "../theme"
import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
  property int battery: 0
  property bool charging: false
  property string wifi: "Disconnected"
  property int wifiSignal: 0
  property string powerStatus: "Unknown"
  property string connType: "disconnected"

  readonly property string powerState: {
    if (powerStatus === "Charging") return "Charging";
    if (powerStatus === "Full") return "Full";
    return "Discharging";
  }

  readonly property string networkState: connType === "disconnected" ? "Disconnected" : "Connected"

  property Process batProc: Process {
    command: [
      "sh", "-c",
      "while true; do " +
      "  cap=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1); " +
      "  st=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1); " +
      "  echo \"BAT:${cap}:${st:-Unknown}\"; " +
      "  sleep 1; " +
      "done"
    ]
    running: true
    stdout: SplitParser {
      onRead: (data) => {
        var line = data.trim();
        if (line.startsWith("BAT:")) {
          var parts = line.substring(4).split(":");
          if (parts.length >= 2) {
            var parsedVal = parseInt(parts[0]);
            if (!isNaN(parsedVal) && parsedVal >= 0 && parsedVal <= 100) {
              battery = parsedVal;
            }
            powerStatus = parts[1];
            charging = (powerStatus === "Charging" || powerStatus === "Full");
          }
        }
      }
    }
  }

  property Process wifiProc: Process {
    command: [
      "sh", "-c",
      "while true; do " +
      "  types=$(nmcli -t -f TYPE,NAME con show --active 2>/dev/null); " +
      "  ssid=$(echo \"$types\" | grep '^802-11-wireless:' | cut -d: -f2 -s); " +
      "  [ -z \"$ssid\" ] && ssid=$(iwgetid -r 2>/dev/null); " +
      "  eth=$(echo \"$types\" | grep '^802-3-ethernet:' | cut -d: -f2 -s); " +
      "  ctype=disconnected; " +
      "  [ -n \"$ssid\" ] && ctype=wifi; " +
      "  [ -z \"$ssid\" ] && [ -n \"$eth\" ] && { ssid=\"$eth\"; ctype=wired; }; " +
      "  [ -z \"$ssid\" ] && ssid=Disconnected; " +
      "  sig=$(awk 'NR>2{if($3!=\"\"){gsub(/\\./,\"\",$3); q=$3+0; print int(q*100/70)}}' /proc/net/wireless 2>/dev/null || echo 0); " +
      "  echo \"WIFI:$ssid:$sig:$ctype\"; " +
      "  sleep 5; " +
      "done"
    ]
    running: true
    stdout: SplitParser {
      onRead: (data) => {
        var line = data.trim();
        if (line.startsWith("WIFI:")) {
          var parts = line.split(":");
          if (parts.length >= 4) {
            wifi = parts.slice(1, parts.length - 2).join(":");
            wifiSignal = parseInt(parts[parts.length - 2]);
            connType = parts[parts.length - 1];
          }
        }
      }
    }
  }
}
