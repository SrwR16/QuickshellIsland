import "../overlay"
import "../widgets"
import "../services"
import "../theme"
import QtQuick
import QtQuick.Layouts

Rectangle {
  id: powerMenu
  radius: parent?.radius ?? 28
  color: Theme.background
  clip: true

  property var powerAction: null
  property bool hovered: false

  RowLayout {
    anchors.centerIn: parent
    spacing: 24

    ColumnLayout {
      spacing: 8
      Layout.alignment: Qt.AlignHCenter
      Rectangle {
        Layout.alignment: Qt.AlignHCenter
        width: 56; height: 56; radius: 16
        color: logMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceLight
        Behavior on color { ColorAnimation { duration: 120 } }
        Text {
          anchors.centerIn: parent
          text: ""
          color: logMouse.containsMouse ? Theme.text : Theme.error
          font { family: "JetBrainsMono Nerd Font"; pixelSize: 24 }
          Behavior on color { ColorAnimation { duration: 120 } }
        }
        MouseArea {
          id: logMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: powerMenu.hovered = true
          onExited: powerMenu.hovered = false
          onClicked: if (powerMenu.powerAction) powerMenu.powerAction(["sh", "-c", "loginctl terminate-user $USER"])
        }
      }
      Text { text: "Logout"; color: Theme.text; opacity: 0.6; font.family: "Inter"; font.pixelSize: 11; Layout.alignment: Qt.AlignHCenter }
    }

    ColumnLayout {
      spacing: 8
      Layout.alignment: Qt.AlignHCenter
      Rectangle {
        Layout.alignment: Qt.AlignHCenter
        width: 56; height: 56; radius: 16
        color: lockMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceLight
        Behavior on color { ColorAnimation { duration: 120 } }
        Text {
          anchors.centerIn: parent
          text: ""
          color: lockMouse.containsMouse ? Theme.text : Theme.secondary
          font { family: "JetBrainsMono Nerd Font"; pixelSize: 24 }
          Behavior on color { ColorAnimation { duration: 120 } }
        }
        MouseArea {
          id: lockMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: powerMenu.hovered = true
          onExited: powerMenu.hovered = false
          onClicked: if (powerMenu.powerAction) powerMenu.powerAction(["hyprlock"])
        }
      }
      Text { text: "Lock"; color: Theme.text; opacity: 0.6; font.family: "Inter"; font.pixelSize: 11; Layout.alignment: Qt.AlignHCenter }
    }

    ColumnLayout {
      spacing: 8
      Layout.alignment: Qt.AlignHCenter
      Rectangle {
        Layout.alignment: Qt.AlignHCenter
        width: 56; height: 56; radius: 16
        color: sleepMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceLight
        Behavior on color { ColorAnimation { duration: 120 } }
        Text {
          anchors.centerIn: parent
          text: ""
          color: sleepMouse.containsMouse ? Theme.text : Theme.tertiary
          font { family: "JetBrainsMono Nerd Font"; pixelSize: 24 }
          Behavior on color { ColorAnimation { duration: 120 } }
        }
        MouseArea {
          id: sleepMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: powerMenu.hovered = true
          onExited: powerMenu.hovered = false
          onClicked: if (powerMenu.powerAction) powerMenu.powerAction(["systemctl", "suspend"])
        }
      }
      Text { text: "Sleep"; color: Theme.text; opacity: 0.6; font.family: "Inter"; font.pixelSize: 11; Layout.alignment: Qt.AlignHCenter }
    }

    ColumnLayout {
      spacing: 8
      Layout.alignment: Qt.AlignHCenter
      Rectangle {
        Layout.alignment: Qt.AlignHCenter
        width: 56; height: 56; radius: 16
        color: rebMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceLight
        Behavior on color { ColorAnimation { duration: 120 } }
        Text {
          anchors.centerIn: parent
          text: ""
          color: rebMouse.containsMouse ? Theme.text : Theme.warning
          font { family: "JetBrainsMono Nerd Font"; pixelSize: 24 }
          Behavior on color { ColorAnimation { duration: 120 } }
        }
        MouseArea {
          id: rebMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: powerMenu.hovered = true
          onExited: powerMenu.hovered = false
          onClicked: if (powerMenu.powerAction) powerMenu.powerAction(["systemctl", "reboot"])
        }
      }
      Text { text: "Reboot"; color: Theme.text; opacity: 0.6; font.family: "Inter"; font.pixelSize: 11; Layout.alignment: Qt.AlignHCenter }
    }

    ColumnLayout {
      spacing: 8
      Layout.alignment: Qt.AlignHCenter
      Rectangle {
        Layout.alignment: Qt.AlignHCenter
        width: 56; height: 56; radius: 16
        color: shutMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceLight
        Behavior on color { ColorAnimation { duration: 120 } }
        Text {
          anchors.centerIn: parent
          text: ""
          color: shutMouse.containsMouse ? Theme.text : Theme.error
          font { family: "JetBrainsMono Nerd Font"; pixelSize: 24 }
          Behavior on color { ColorAnimation { duration: 120 } }
        }
        MouseArea {
          id: shutMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: powerMenu.hovered = true
          onExited: powerMenu.hovered = false
          onClicked: if (powerMenu.powerAction) powerMenu.powerAction(["systemctl", "poweroff"])
        }
      }
      Text { text: "Shutdown"; color: Theme.text; opacity: 0.6; font.family: "Inter"; font.pixelSize: 11; Layout.alignment: Qt.AlignHCenter }
    }
  }
}
