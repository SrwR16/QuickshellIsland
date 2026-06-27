import QtQuick
import QtQuick.Layouts

Item {
  id: root

  property var wallpaperModel: []
  property var wallService: null
  property int cellSize: 120
  property int cellSpacing: 12

  signal wallpaperChosen(string path)

  Flickable {
    id: flick
    anchors.fill: parent
    contentWidth: parent.width
    contentHeight: flow.implicitHeight + 20
    clip: true

    Flow {
      id: flow
      width: parent.width - 16
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: root.cellSpacing
      layoutDirection: Qt.LeftToRight

      Repeater {
        model: root.wallpaperModel

        delegate: Rectangle {
          id: card
          width: root.cellSize
          height: Math.round(root.cellSize * 9 / 16)
          radius: 14
          color: "#16241f"
          clip: true

          property bool hovered: false

          transform: [
            Scale {
              id: cardScale
              origin.x: card.width / 2
              origin.y: card.height / 2
              xScale: card.hovered ? 1.06 : 1
              yScale: card.hovered ? 1.06 : 1
              Behavior on xScale { NumberAnimation { duration: 120; easing.type: Easing.OutQuart } }
              Behavior on yScale { NumberAnimation { duration: 120; easing.type: Easing.OutQuart } }
            }
          ]

          Rectangle {
            anchors.fill: parent
            radius: 14
            border.width: card.hovered ? 2 : 0
            border.color: "#61afef"
            color: "transparent"
            Behavior on border.width { NumberAnimation { duration: 100 } }
          }

          Image {
            id: thumb
            anchors.fill: parent
            anchors.margins: card.hovered ? 2 : 4
            source: "file://" + modelData
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: root.cellSize * 2
            sourceSize.height: root.cellSize * 2
            smooth: true
            visible: thumb.status === Image.Ready
            Behavior on anchors.margins { NumberAnimation { duration: 120; easing.type: Easing.OutQuart } }
          }

          Rectangle {
            anchors { fill: parent; margins: card.hovered ? 2 : 4 }
            radius: 10
            color: "#0a141180"
            visible: thumb.status !== Image.Ready

            Text {
              anchors.centerIn: parent
              text: "󰸉"
              color: "#eae6dc"
              opacity: 0.4
              font { family: "JetBrainsMono Nerd Font"; pixelSize: 28 }
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: card.hovered = true
            onExited: card.hovered = false
            onClicked: {
              root.wallpaperChosen(modelData)
              if (root.wallService)
                root.wallService.applyWallpaper(modelData)
            }
          }
        }
      }
    }
  }

}
