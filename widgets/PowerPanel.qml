import "../theme"
import QtQuick
import Quickshell

Item {
  id: root

  property bool showPanel: false
  property var onCloseRequested

  width: 540
  height: 120

  visible: showPanel
  opacity: showPanel ? 1.0 : 0.0
  scale: showPanel ? 1.0 : 0.95

  Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
  Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }

  Rectangle {
    anchors.fill: parent
    radius: 28
    color: Theme.background
    border.width: 1
    border.color: Theme.outlineVariant

    Row {
      anchors.centerIn: parent
      spacing: 16

      Repeater {
        model: [
          { icon: "", color: Theme.error,     cmd: ["sh", "-c", "loginctl terminate-user $USER"],  label: "Logout"  },
          { icon: "", color: Theme.secondary, cmd: ["hyprlock"],                                     label: "Lock"    },
          { icon: "", color: Theme.tertiary,  cmd: ["systemctl", "suspend"],                         label: "Sleep"   },
          { icon: "", color: Theme.warning,   cmd: ["systemctl", "reboot"],                          label: "Reboot"  },
          { icon: "", color: Theme.error,     cmd: ["systemctl", "poweroff"],                        label: "Shutdown" },
        ]

        delegate: Column {
          spacing: 4
          width: 56

          Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 56; height: 56; radius: 16
            color: Theme.surfaceLight

            Text {
              anchors.centerIn: parent
              text: modelData.icon
              color: modelData.color
              font { family: "JetBrainsMono Nerd Font"; pixelSize: 22 }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              hoverEnabled: true
              onClicked: {
                Quickshell.execDetached(modelData.cmd)
                if (root.onCloseRequested) root.onCloseRequested()
              }
            }
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: modelData.label
            color: Theme.text
            opacity: 0.6
            font { family: "Inter"; pixelSize: 10 }
          }
        }
      }
    }
  }
}
