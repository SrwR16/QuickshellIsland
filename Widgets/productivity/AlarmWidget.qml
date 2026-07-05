import QtQuick
import QtQuick.Layouts
import "../../core"
import Quickshell.Io

Item {
    id: alarmWidget

    property int hour: 7
    property int minute: 30
    property bool isPM: false
    property bool isActive: false

    Timer {
        interval: 1000
        running: alarmWidget.isActive
        repeat: true
        onTriggered: {
            let d = new Date();
            let h = d.getHours();
            let m = d.getMinutes();
            let currentPM = h >= 12;
            let currentH12 = h % 12;
            if (currentH12 === 0) currentH12 = 12;
            
            if (currentH12 === alarmWidget.hour && m === alarmWidget.minute && currentPM === alarmWidget.isPM) {
                alarmWidget.isActive = false;
                notifyProc.command = ["notify-send", "-a", "Alarm", "-u", "critical", "-i", "alarm", "Alarm Ringing!", "Time to wake up!"];
                notifyProc.running = true;
            }
        }
    }

    Process { id: notifyProc }

    ColumnLayout {
        anchors.fill: parent
        spacing: 24

        // Time Input
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16

            // Hour
            ColumnLayout {
                spacing: 8
                Rectangle {
                    width: 40; height: 24; radius: 8; color: Theme.surfaceVariant;
                    Text { anchors.centerIn: parent; text: "󰁝"; color: Theme.text; font.family: "JetBrainsMono Nerd Font" }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if(!alarmWidget.isActive) alarmWidget.hour = alarmWidget.hour === 12 ? 1 : alarmWidget.hour + 1 }
                }
                Text {
                    text: alarmWidget.hour.toString().padStart(2, '0')
                    font { family: "JetBrains Mono"; pixelSize: 68; weight: Font.Black }
                    color: alarmWidget.isActive ? Theme.text : Theme.primary
                    Layout.alignment: Qt.AlignHCenter
                }
                Rectangle {
                    width: 40; height: 24; radius: 8; color: Theme.surfaceVariant;
                    Text { anchors.centerIn: parent; text: "󰁅"; color: Theme.text; font.family: "JetBrainsMono Nerd Font" }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if(!alarmWidget.isActive) alarmWidget.hour = alarmWidget.hour === 1 ? 12 : alarmWidget.hour - 1 }
                }
            }

            Text {
                text: ":"
                font { family: "JetBrains Mono"; pixelSize: 68; weight: Font.Black }
                color: Theme.subtext
            }

            // Minute
            ColumnLayout {
                spacing: 8
                Rectangle {
                    width: 40; height: 24; radius: 8; color: Theme.surfaceVariant;
                    Text { anchors.centerIn: parent; text: "󰁝"; color: Theme.text; font.family: "JetBrainsMono Nerd Font" }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if(!alarmWidget.isActive) alarmWidget.minute = alarmWidget.minute >= 59 ? 0 : alarmWidget.minute + 1 }
                }
                Text {
                    text: alarmWidget.minute.toString().padStart(2, '0')
                    font { family: "JetBrains Mono"; pixelSize: 68; weight: Font.Black }
                    color: alarmWidget.isActive ? Theme.text : Theme.primary
                    Layout.alignment: Qt.AlignHCenter
                }
                Rectangle {
                    width: 40; height: 24; radius: 8; color: Theme.surfaceVariant;
                    Text { anchors.centerIn: parent; text: "󰁅"; color: Theme.text; font.family: "JetBrainsMono Nerd Font" }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if(!alarmWidget.isActive) alarmWidget.minute = alarmWidget.minute <= 0 ? 59 : alarmWidget.minute - 1 }
                }
            }

            // AM / PM
            ColumnLayout {
                spacing: 8
                Rectangle {
                    width: 48; height: 48; radius: 12
                    color: !alarmWidget.isPM ? Theme.primary : Theme.surfaceVariant
                    Text { anchors.centerIn: parent; text: "AM"; color: !alarmWidget.isPM ? Theme.onPrimary : Theme.text; font { family: "JetBrains Mono"; pixelSize: 16; weight: 700 } }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if(!alarmWidget.isActive) alarmWidget.isPM = false }
                }
                Rectangle {
                    width: 48; height: 48; radius: 12
                    color: alarmWidget.isPM ? Theme.primary : Theme.surfaceVariant
                    Text { anchors.centerIn: parent; text: "PM"; color: alarmWidget.isPM ? Theme.onPrimary : Theme.text; font { family: "JetBrains Mono"; pixelSize: 16; weight: 700 } }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if(!alarmWidget.isActive) alarmWidget.isPM = true }
                }
            }
        }

        Item { Layout.fillHeight: true }

        // Controls
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 24

            Rectangle {
                width: 64; height: 64; radius: 16; color: alarmWidget.isActive ? Theme.surfaceVariant : Theme.primary
                Text { 
                    anchors.centerIn: parent
                    text: alarmWidget.isActive ? "󰜺" : "󰄲"
                    color: alarmWidget.isActive ? Theme.text : Theme.onPrimary; font { family: "JetBrainsMono Nerd Font"; pixelSize: 28 }
                }
                MouseArea { 
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor;
                    onClicked: alarmWidget.isActive = !alarmWidget.isActive
                }
            }
        }
    }
}
