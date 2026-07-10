import "../theme"
import QtQuick
import QtQuick.Layouts

Item {
  property var powerAction: function(cmd) {}

  Row {
    anchors.centerIn: parent
    spacing: 24

    Repeater {
      model: [
        { icon: "", label: "Logout",   color: Theme.error,     cmd: ["sh", "-c", "loginctl terminate-user $USER"] },
        { icon: "", label: "Lock",     color: Theme.secondary, cmd: ["hyprlock"] },
        { icon: "", label: "Sleep",    color: Theme.tertiary,  cmd: ["systemctl", "suspend"] },
        { icon: "", label: "Reboot",   color: Theme.warning,   cmd: ["systemctl", "reboot"] },
        { icon: "", label: "Shutdown", color: Theme.error,     cmd: ["systemctl", "poweroff"] },
      ]

      delegate: Column {
        spacing: 8

        Rectangle {
          width: 56; height: 56; radius: 16
          color: marea.containsMouse ? Theme.surfaceHover : Theme.surfaceLight
          Behavior on color { ColorAnimation { duration: 120 } }

          Text {
            anchors.centerIn: parent
            text: modelData.icon
            color: marea.containsMouse ? Theme.text : modelData.color
            font { family: "JetBrainsMono Nerd Font"; pixelSize: 24 }
            Behavior on color { ColorAnimation { duration: 120 } }
          }

          MouseArea {
            id: marea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (powerAction) powerAction(modelData.cmd)
          }
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: modelData.label
          color: Theme.text
          opacity: 0.6
          font { family: "Inter"; pixelSize: 11 }
        }
      }
    }
  }
}
