import QtQuick
import QtQuick.Layouts

Rectangle {
  id: powerMenu
  radius: parent?.radius ?? 28
  color: "#0a1411"
  clip: true

  property var powerAction: null
  property bool hovered: false

  RowLayout {
    anchors.centerIn: parent
    spacing: 20

    // Logout
    ColumnLayout {
      spacing: 6
      Layout.alignment: Qt.AlignHCenter
      Rectangle {
        Layout.alignment: Qt.AlignHCenter
        width: 50; height: 50; radius: 14
        color: btnMouse.containsMouse ? "#1d2a25" : "#16241f"
        Behavior on color { ColorAnimation { duration: 120 } }
        Text {
          anchors.centerIn: parent
          text: ""
          color: btnMouse.containsMouse ? "#eae6dc" : "#e06c75"
          font { family: "JetBrainsMono Nerd Font"; pixelSize: 22 }
          Behavior on color { ColorAnimation { duration: 120 } }
        }
        MouseArea {
          id: btnMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: powerMenu.hovered = true
          onExited: powerMenu.hovered = false
          onClicked: if (powerMenu.powerAction) powerMenu.powerAction(["sh", "-c", "loginctl terminate-user $USER"])
        }
      }
      Text { text: "Logout"; color: "#eae6dc"; opacity: 0.6; font.family: "Inter"; font.pixelSize: 10; Layout.alignment: Qt.AlignHCenter }
    }

    // Lock
    ColumnLayout {
      spacing: 6
      Layout.alignment: Qt.AlignHCenter
      Rectangle {
        Layout.alignment: Qt.AlignHCenter
        width: 50; height: 50; radius: 14
        color: lockBtnMouse.containsMouse ? "#1d2a25" : "#16241f"
        Behavior on color { ColorAnimation { duration: 120 } }
        Text {
          anchors.centerIn: parent
          text: ""
          color: lockBtnMouse.containsMouse ? "#eae6dc" : "#56b6c2"
          font { family: "JetBrainsMono Nerd Font"; pixelSize: 22 }
          Behavior on color { ColorAnimation { duration: 120 } }
        }
        MouseArea {
          id: lockBtnMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: powerMenu.hovered = true
          onExited: powerMenu.hovered = false
          onClicked: if (powerMenu.powerAction) powerMenu.powerAction(["hyprlock"])
        }
      }
      Text { text: "Lock"; color: "#eae6dc"; opacity: 0.6; font.family: "Inter"; font.pixelSize: 10; Layout.alignment: Qt.AlignHCenter }
    }

    // Sleep
    ColumnLayout {
      spacing: 6
      Layout.alignment: Qt.AlignHCenter
      Rectangle {
        Layout.alignment: Qt.AlignHCenter
        width: 50; height: 50; radius: 14
        color: sleepBtnMouse.containsMouse ? "#1d2a25" : "#16241f"
        Behavior on color { ColorAnimation { duration: 120 } }
        Text {
          anchors.centerIn: parent
          text: ""
          color: sleepBtnMouse.containsMouse ? "#eae6dc" : "#61afef"
          font { family: "JetBrainsMono Nerd Font"; pixelSize: 22 }
          Behavior on color { ColorAnimation { duration: 120 } }
        }
        MouseArea {
          id: sleepBtnMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: powerMenu.hovered = true
          onExited: powerMenu.hovered = false
          onClicked: if (powerMenu.powerAction) powerMenu.powerAction(["systemctl", "suspend"])
        }
      }
      Text { text: "Sleep"; color: "#eae6dc"; opacity: 0.6; font.family: "Inter"; font.pixelSize: 10; Layout.alignment: Qt.AlignHCenter }
    }

    // Reboot
    ColumnLayout {
      spacing: 6
      Layout.alignment: Qt.AlignHCenter
      Rectangle {
        Layout.alignment: Qt.AlignHCenter
        width: 50; height: 50; radius: 14
        color: btnMouse2.containsMouse ? "#1d2a25" : "#16241f"
        Behavior on color { ColorAnimation { duration: 120 } }
        Text {
          anchors.centerIn: parent
          text: ""
          color: btnMouse2.containsMouse ? "#eae6dc" : "#e5c07b"
          font { family: "JetBrainsMono Nerd Font"; pixelSize: 22 }
          Behavior on color { ColorAnimation { duration: 120 } }
        }
        MouseArea {
          id: btnMouse2
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: powerMenu.hovered = true
          onExited: powerMenu.hovered = false
          onClicked: if (powerMenu.powerAction) powerMenu.powerAction(["systemctl", "reboot"])
        }
      }
      Text { text: "Reboot"; color: "#eae6dc"; opacity: 0.6; font.family: "Inter"; font.pixelSize: 10; Layout.alignment: Qt.AlignHCenter }
    }

    // Shutdown
    ColumnLayout {
      spacing: 6
      Layout.alignment: Qt.AlignHCenter
      Rectangle {
        Layout.alignment: Qt.AlignHCenter
        width: 50; height: 50; radius: 14
        color: btnMouse3.containsMouse ? "#1d2a25" : "#16241f"
        Behavior on color { ColorAnimation { duration: 120 } }
        Text {
          anchors.centerIn: parent
          text: ""
          color: btnMouse3.containsMouse ? "#eae6dc" : "#e06c75"
          font { family: "JetBrainsMono Nerd Font"; pixelSize: 22 }
          Behavior on color { ColorAnimation { duration: 120 } }
        }
        MouseArea {
          id: btnMouse3
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: powerMenu.hovered = true
          onExited: powerMenu.hovered = false
          onClicked: if (powerMenu.powerAction) powerMenu.powerAction(["systemctl", "poweroff"])
        }
      }
      Text { text: "Shutdown"; color: "#eae6dc"; opacity: 0.6; font.family: "Inter"; font.pixelSize: 10; Layout.alignment: Qt.AlignHCenter }
    }
  }
}
