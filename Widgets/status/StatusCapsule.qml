import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth

import "../../core"

Rectangle {
    id: statusCapsule
    color: capsuleMouseArea.containsMouse ? Theme.surfaceHover : Theme.surface
    radius: 12
    height: 24
    width: layout.implicitWidth + 24

    Behavior on color { ColorAnimation { duration: 150 } }

    property string wifiName: status.wifi
    property int wifiSignal: status.wifiSignal
    property int batteryPercent: status.battery
    property bool isCharging: status.charging
    property string powerState: status.powerState
    property string networkState: status.networkState
    property string connectionType: status.connType
    property bool isHovered: capsuleMouseArea.containsMouse
    signal clicked()

    property var btAdapter: Bluetooth.defaultAdapter
    property bool btConnected: {
        if (!btAdapter || !btAdapter.enabled) return false;
        var devs = btAdapter.devices.values;
        for (var i = 0; i < devs.length; i++) {
            if (devs[i].state === BluetoothDeviceState.Connected) return true;
        }
        return false;
    }

    StatusService {
        id: status
    }

    MouseArea {
        id: capsuleMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: statusCapsule.clicked()
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 10

        Text {
            text: statusCapsule.networkState === "Disconnected" ? "󰤭"
                : statusCapsule.connectionType === "wired" ? "󰌚"
                : statusCapsule.wifiSignal > 75 ? "󰤨"
                : statusCapsule.wifiSignal > 50 ? "󰤥"
                : statusCapsule.wifiSignal > 25 ? "󰤢"
                : "󰤟"
            color: statusCapsule.networkState === "Disconnected" ? Theme.subtext : Theme.text
            font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
        }

        Text {
            visible: statusCapsule.btConnected
            text: "󰂱"
            color: Theme.text
            font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
        }

        Item {
            width: 32; height: 14
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 25; height: 12
                radius: 4
                color: "transparent"
                border.color: Theme.text
                border.width: 1
                opacity: 0.4
            }

            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 2
                anchors.leftMargin: 2
                height: 8
                // Clamp max width to 21 to prevent overflow bugs if system reports > 100% battery
                width: Math.max(0, Math.min(21, 21 * (statusCapsule.batteryPercent / 100)))
                radius: 2
                color: statusCapsule.isCharging ? Theme.primary : (statusCapsule.batteryPercent <= 20 ? Theme.error : Theme.text)
            }

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 26
                anchors.verticalCenter: parent.verticalCenter
                width: 2; height: 4
                radius: 1
                color: Theme.text
                opacity: 0.4
            }

            // Pure geometric '+' sign for charging: 100% immune to missing fonts or broken emojis
            Item {
                anchors.centerIn: parent
                width: 8; height: 8
                visible: statusCapsule.isCharging
                z: 1
                
                Rectangle {
                    anchors.centerIn: parent
                    width: 2; height: 8
                    color: Theme.background
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: 8; height: 2
                    color: Theme.background
                }
            }
        }

        Text {
            text: statusCapsule.batteryPercent + "%"
            color: statusCapsule.batteryPercent <= 20 && !statusCapsule.isCharging ? Theme.error : Theme.text
            font { family: "Inter"; pixelSize: 11; weight: 700 }
        }
    }
}
