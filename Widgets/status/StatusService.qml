import Quickshell
import Quickshell.Io
import QtQuick


QtObject {


property int battery:0

property bool charging:false

property string wifi:"Disconnected"

property int wifiSignal:0




property Timer pollTimer: Timer {

interval:5000

running:true

repeat:true

triggeredOnStart:true


onTriggered:
{

batteryProc.running=true
statusProc.running=true
wifiProc.running=true
wifiSignalProc.running=true

}


}


property Process batteryProc: Process {

command:
[
"sh",
"-c",
"cat /sys/class/power_supply/BAT*/capacity | head -1"
]


stdout:SplitParser {

onRead:data =>
battery=parseInt(data)||0

}

}


property Process statusProc: Process {

command:
[
"sh",
"-c",
"cat /sys/class/power_supply/BAT*/status | head -1"
]


stdout:SplitParser {

onRead:data =>
charging=data.trim()=="Charging"

}

}


property Process wifiProc: Process {

command:
[
"sh",
"-c",
"r=$(nmcli -t -f TYPE,NAME con show --active 2>/dev/null | grep '^802-11-wireless:' | cut -d: -f2 -s); [ -n \"$r\" ] && echo \"$r\" || { r=$(iwgetid -r 2>/dev/null); [ -n \"$r\" ] && echo \"$r\" || echo Disconnected; }"
]


stdout:SplitParser {

onRead:data =>
wifi=data.trim() || "Disconnected"

}

}


property Process wifiSignalProc: Process {

command:
[
"sh",
"-c",
"awk 'NR>2{if($3!=\"\"){gsub(/\\./,\"\",$3); q=$3+0; print int(q*100/70)}}' /proc/net/wireless 2>/dev/null || echo 0"
]


stdout:SplitParser {

onRead:data =>
wifiSignal=Math.min(100, Math.max(0, parseInt(data)||0))

}

}


}
