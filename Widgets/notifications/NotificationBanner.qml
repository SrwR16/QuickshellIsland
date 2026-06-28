import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "../../core"

Rectangle {
  id: root

  property var notification: null
  property var notificationData: null
  readonly property bool expanded: notificationData !== null
  property bool bannerHovered: false

  readonly property real bannerWidth: 480
  readonly property real bannerHeight: 130
  readonly property real bannerRadius: 28

  signal dismissed(var notifRef)

  color: Theme.background
  clip: true

  layer.enabled: true
  layer.samples: 4

  RowLayout {
    id: content
    anchors.fill: parent
    anchors.margins: 20
    spacing: 14

    NotifIcon {
      iconSize: 42
      appIcon: root.notificationData?.appIcon ?? ""
      appName: root.notificationData?.appName ?? ""
    }

    ColumnLayout {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
      spacing: 2

      Text {
        text: root.notificationData?.appName ?? ""
        color: Theme.subtext
        font { family: "Inter"; pixelSize: 11; weight: 500 }
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      Text {
        text: root.notificationData?.summary ?? ""
        color: root.notificationData
          && root.notificationData.urgency === NotificationUrgency.Critical
          ? Theme.error : Theme.text
        font { family: "Inter"; pixelSize: 14; weight: 700 }
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      Text {
        text: root.notificationData?.body ?? ""
        visible: text !== ""
        color: Theme.subtext
        font { family: "Inter"; pixelSize: 10; weight: 400 }
        elide: Text.ElideRight
        Layout.fillWidth: true
        maximumLineCount: 1
      }

      Text {
        text: root.notificationData?.body ?? ""
        visible: text !== ""
        color: Theme.muted
        font { family: "Inter"; pixelSize: 11; weight: 400 }
        elide: Text.ElideRight
        Layout.fillWidth: true
        maximumLineCount: 2
        wrapMode: Text.WordWrap
      }
    }

    Text {
      text: "󰅂"
      color: Theme.subtext
      font { family: "JetBrainsMono Nerd Font"; pixelSize: 18 }
      Layout.alignment: Qt.AlignTop | Qt.AlignRight
      Layout.topMargin: 2

      MouseArea {
        anchors.fill: parent
        anchors.margins: -8
        cursorShape: Qt.PointingHandCursor
        onClicked: root.dismissed(root.notificationData)
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onContainsMouseChanged: root.bannerHovered = containsMouse
    onClicked: root.dismissed(root.notificationData)
  }

  states: [
    State {
      name: "expanded"
      when: expanded
      PropertyChanges { target: root; width: bannerWidth }
      PropertyChanges { target: root; height: bannerHeight }
      PropertyChanges { target: root; radius: bannerRadius }
      PropertyChanges { target: content; opacity: 1.0 }
    },
    State {
      name: "collapsed"
      when: !expanded
      PropertyChanges { target: root; width: 0 }
      PropertyChanges { target: root; height: 0 }
      PropertyChanges { target: root; radius: 18 }
      PropertyChanges { target: content; opacity: 0.0 }
    }
  ]

  transitions: [
    Transition {
      from: "collapsed"; to: "expanded"
      ParallelAnimation {
        NumberAnimation {
          target: root
          properties: "width,height,radius"
          duration: 400
          easing.type: Easing.InOutQuint
        }
        SequentialAnimation {
          PauseAnimation { duration: 150 }
          NumberAnimation {
            target: content
            property: "opacity"
            duration: 200
            easing.type: Easing.InOutQuint
          }
        }
      }
    },
    Transition {
      from: "expanded"; to: "collapsed"
      ParallelAnimation {
        SequentialAnimation {
          NumberAnimation {
            target: content
            property: "opacity"
            duration: 100
          }
        }
        NumberAnimation {
          target: root
          properties: "width,height,radius"
          duration: 300
          easing.type: Easing.InOutQuint
        }
      }
    }
  ]
}
