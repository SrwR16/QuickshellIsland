import Quickshell.Hyprland
import QtQuick
import "../theme"

Item {
  id: root
  height: 22
  implicitWidth: maxPills * (pillWidth + pillSpacing) - pillSpacing

  readonly property int maxPills: 5
  readonly property int pillWidth: 24
  readonly property int pillHeight: 22
  readonly property int pillSpacing: 4

  property var items: []
  property int focusedIndex: -1

  function windowCount(ws) {
    if (!ws || !ws.toplevels) return 0
    try { return ws.toplevels.values.length } catch (e) { return 0 }
  }

  function update() {
    try {
      if (!Hyprland || !Hyprland.workspaces) return
      var vals = Hyprland.workspaces.values
      if (!vals) return

      var list = []
      for (var i = 0; i < vals.length; i++) {
        var ws = vals[i]
        if (ws && (ws.focused || windowCount(ws) > 0))
          list.push(ws)
      }
      list.sort(function(a, b) { return a.id - b.id })
      items = list

      focusedIndex = -1
      for (var j = 0; j < list.length; j++) {
        if (list[j].focused) { focusedIndex = j; break }
      }
    } catch (e) {}
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
    interval: 300
    running: true
    repeat: true
    onTriggered: {
      root.update()
      if (root.items.length > 0)
        running = false
    }
  }

  Component.onCompleted: Qt.callLater(root.update)

  Flickable {
    anchors.fill: parent
    contentWidth: row.width
    contentHeight: row.height
    clip: true
    interactive: contentWidth > width
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.HorizontalFlick

    Item {
      width: row.width
      height: row.height

      Rectangle {
        id: activeHighlight
        width: pillWidth
        height: pillHeight
        radius: 5
        color: Theme.primary
        visible: focusedIndex >= 0

        x: focusedIndex >= 0 ? focusedIndex * (pillWidth + pillSpacing) : -100
        y: 0
        Behavior on x { NumberAnimation { duration: 200; easing: Easing.OutQuart } }
      }

      Row {
        id: row
        height: parent.height
        spacing: pillSpacing

        Repeater {
          model: root.items

          delegate: Item {
            id: pill
            required property var modelData

            width: pillWidth
            height: pillHeight

            Rectangle {
              anchors.fill: parent
              radius: 5
              color: {
                if (index === root.focusedIndex) return "transparent"
                if (mouseArea.containsMouse) return Qt.rgba(bgBase.r, bgBase.g, bgBase.b, 0.1)
                return root.windowCount(modelData) > 0 ? Qt.rgba(bgBase.r, bgBase.g, bgBase.b, 0.15) : "transparent"
              }
              property color bgBase: root.windowCount(modelData) > 0 ? Theme.text : Theme.muted
            }

            Text {
              anchors.centerIn: parent
              text: modelData.id
              color: {
                if (index === root.focusedIndex) return Theme.onPrimary
                if (mouseArea.containsMouse) return Theme.text
                return root.windowCount(modelData) > 0 ? Theme.text : Theme.muted
              }
              font {
                family: "Inter"
                pixelSize: 11
                weight: index === root.focusedIndex ? Font.Bold : Font.Medium
              }
            }

            Rectangle {
              anchors.bottom: parent.bottom
              anchors.bottomMargin: 2
              anchors.horizontalCenter: parent.horizontalCenter
              width: 3; height: 3; radius: 1.5
              visible: root.windowCount(modelData) > 0 && index !== root.focusedIndex
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
