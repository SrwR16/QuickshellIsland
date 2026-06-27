import QtQuick
import QtQuick.Layouts

import "../../core"

Rectangle {
    id: statusCapsule
    color: capsuleMouseArea.containsMouse ? "#2a3a34" : "#1a2421"
    radius: 12
    height: 24
    width: layout.implicitWidth + 24

    Behavior on color { ColorAnimation { duration: 150 } }

    property string wifiName: status.wifi
    property int wifiSignal: status.wifiSignal
    property int batteryPercent: status.battery
    property bool isCharging: status.charging
    property bool isHovered: capsuleMouseArea.containsMouse
    signal clicked()

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
            text: statusCapsule.wifiName === "Disconnected" ? "󰤭"
                : statusCapsule.wifiSignal > 75 ? "󰤨"
                : statusCapsule.wifiSignal > 50 ? "󰤥"
                : statusCapsule.wifiSignal > 25 ? "󰤢"
                : "󰤟"
            color: statusCapsule.wifiName === "Disconnected" ? "#556663" : "#3ba889"
            font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
        }

        Item {
            width: 38
            height: 14

            Rectangle {
                anchors.fill: parent
                radius: 3
                color: "#33403c"

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * Math.min(statusCapsule.batteryPercent, 100) / 100
                    radius: 3
                    color: statusCapsule.batteryPercent > 20 ? "#3ba889" : "#d35d6e"
                }

                Text {
                    anchors.centerIn: parent
                    text: statusCapsule.batteryPercent + "%"
                    color: "#eae6dc"
                    font { family: "Inter"; pixelSize: 9; weight: 700 }
                }
            }

            Rectangle {
                anchors.left: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 3
                height: 6
                radius: 1
                color: statusCapsule.isCharging ? "#3ba889" : "#33403c"
            }
        }
    }
}
