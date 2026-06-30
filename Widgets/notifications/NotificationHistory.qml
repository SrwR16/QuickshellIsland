import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "../../core"

Rectangle {
  id: historyRoot

  property var storedNotifications: []

  signal dismissNotif(var notifRef)
  signal clearAll()

  radius: 16
  color: Theme.surface
  clip: true

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 14
    spacing: 10

    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Text {
        text: "Notifications"
        color: Theme.text
        opacity: 0.7
        font { family: "Inter"; pixelSize: 11; weight: 700 }
        Layout.fillWidth: true
      }

      Text {
        text: "Clear all"
        color: Theme.primary
        font { family: "Inter"; pixelSize: 11; weight: 600 }
        visible: (historyRoot.storedNotifications?.length ?? 0) > 1

        MouseArea {
          anchors.fill: parent
          anchors.margins: -6
          cursorShape: Qt.PointingHandCursor
          onClicked: historyRoot.clearAll()
        }
      }
    }

    ScrollView {
      id: notifScroll
      Layout.fillWidth: true
      Layout.fillHeight: true
  visible: (storedNotifications?.length ?? 0) > 0
  clip: true

      Column {
        spacing: 8
        width: notifScroll.availableWidth

        Repeater {
          model: historyRoot.storedNotifications

          delegate: Rectangle {
            id: notifCard
            required property var modelData
            width: parent.width
            height: notifItemCol.implicitHeight + 24
            radius: 14
            color: Theme.surfaceLight

            RowLayout {
              anchors.fill: parent
              anchors.margins: 14
              spacing: 10

              NotifIcon {
                Layout.alignment: Qt.AlignTop
                iconSize: 26
                appIcon: modelData.appIcon || ""
                appName: modelData.appName || ""
              }

              ColumnLayout {
                id: notifItemCol
                spacing: 2
                Layout.fillWidth: true

                Text {
                  text: modelData.appName || ""
                  visible: text !== ""
                  color: Theme.muted
                  font { family: "Inter"; pixelSize: 10; weight: 500 }
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                }

                Text {
                  text: modelData.summary || ""
                  color: modelData.urgency === NotificationUrgency.Critical
                    ? Theme.error : Theme.text
                  font { family: "Inter"; pixelSize: 13; weight: 700 }
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                }

                Text {
                  text: modelData.body || ""
                  visible: text !== ""
                  color: Theme.subtext
                  font { family: "Inter"; pixelSize: 10 }
                  Layout.fillWidth: true
                  Layout.topMargin: 2
                  maximumLineCount: 2
                  wrapMode: Text.WordWrap
                }
              }

              Text {
                Layout.alignment: Qt.AlignTop
                text: "✕"
                color: Theme.subtext
                font { family: "Inter"; pixelSize: 12 }
                MouseArea {
                  anchors.fill: parent
                  anchors.margins: -6
                  cursorShape: Qt.PointingHandCursor
                  onClicked: historyRoot.dismissNotif(modelData)
                }
              }
            }
          }
        }
      }
    }
  }
}
