import Quickshell.Hyprland
import QtQuick
import "../theme"

Item {
  id: root
  height: 28

  property var items: []

  function update() {
    var vals = Hyprland.workspaces.values
    var list = []
    for (var i = 0; i < vals.length; i++) {
      var ws = vals[i]
      if (ws.focused || ws.toplevels.length > 0)
        list.push(ws)
    }
    list.sort(function(a, b) { return a.id - b.id })
    items = list
  }

  Connections {
    target: Hyprland.workspaces
    function onValuesChanged() { root.update() }
  }

  Connections {
    target: Hyprland
    function onFocusedWorkspaceChanged() { root.update() }
  }

  Timer {
    interval: 500
    running: root.items.length === 0
    repeat: false
    onTriggered: root.update()
  }

  Component.onCompleted: root.update()

  Rectangle {
    id: container
    anchors.fill: parent
    radius: 8
    color: Theme.surfaceContainer
    border.color: Theme.border
    border.width: 1
    visible: root.items.length > 0

    Flickable {
      anchors.fill: parent
      anchors.margins: 2
      contentWidth: row.width
      contentHeight: row.height
      clip: true
      interactive: contentWidth > width
      boundsBehavior: Flickable.StopAtBounds
      flickableDirection: Flickable.HorizontalFlick

      Row {
        id: row
        height: parent.height
        spacing: 2

        Repeater {
          model: root.items

          delegate: Rectangle {
            id: pill
            required property var modelData

            width: 28
            height: 22
            radius: 5

            color: modelData.focused ? Theme.primary : (mouseArea.containsMouse ? Theme.surfaceHover : "transparent")
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
              anchors.centerIn: parent
              text: modelData.id
              color: modelData.focused ? Theme.onPrimary : Theme.text
              font { family: "Inter"; pixelSize: 12; weight: modelData.focused ? Font.Bold : Font.Normal }
            }

            Rectangle {
              anchors.bottom: parent.bottom
              anchors.bottomMargin: 2
              anchors.horizontalCenter: parent.horizontalCenter
              width: 4; height: 4; radius: 2
              visible: modelData.toplevels.length > 0 && !modelData.focused
              color: Theme.primary
            }

            MouseArea {
              id: mouseArea
              anchors.fill: parent; anchors.margins: -2
              hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: Hyprland.dispatch("workspace " + modelData.id)
            }
          }
        }
      }
    }
  }
}
