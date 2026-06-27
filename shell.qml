import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "./Widgets/clock"
import "./controlCenter"
import "./Widgets/notifications"
import "./Widgets/launcher"

ShellRoot {
  id: root

  property bool isControlCenterOpen: false

  NotificationService {
    id: notifService
  }

  PanelWindow {
    anchors { top: true; left: true; right: true }
    implicitHeight: clockItem.height + 20
    color: "transparent"

    // Fixed exclusive zone — notification banner makes the window taller
    // but keeps the clock's reservation so it floats over apps, not pushes them.
    WlrLayershell.exclusiveZone: 56

    MouseArea {
      anchors.fill: parent
      enabled: clockItem.showPowerMenu
      onClicked: clockItem.showPowerMenu = false
    }

    Clock {
      id: clockItem
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: 10

      opacity: !isControlCenterOpen ? 1 : 0
      visible: opacity > 0

      Behavior on opacity {
        NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
      }

      latestNotification: notifService.latestNotification
      latestNotificationData: notifService.latestNotificationData
      storedNotifications: notifService.storedNotifications
      onNotifDismissed: (notifRef) => notifService.dismissNotif(notifRef)
      onNotifBannerDismissed: (notifRef) => notifService.dismissBanner(notifRef)

      onToggleControlCenter: isControlCenterOpen = true
    }
  }

  Timer {
    interval: 300; repeat: true; running: true
    onTriggered: {
      powerMenuChecker.running = true;
      appLauncherChecker.running = true;
    }
  }

  Process {
    id: powerMenuChecker
    command: ["sh", "-c", "test -f /tmp/qs-power-menu && rm /tmp/qs-power-menu && echo 1"]
    stdout: StdioCollector {
      onStreamFinished: {
        if (this.text.trim() === "1" && !clockItem.showAppLauncher)
          clockItem.showPowerMenu = true;
      }
    }
  }

  Process {
    id: appLauncherChecker
    command: ["sh", "-c", "test -f /tmp/qs-app-launcher && rm /tmp/qs-app-launcher && echo 1"]
    stdout: StdioCollector {
      onStreamFinished: {
        if (this.text.trim() === "1" && !clockItem.showPowerMenu)
          clockItem.showAppLauncher = true;
      }
    }
  }

  // App launcher overlay window for keyboard input
  PanelWindow {
    anchors { top: true; left: true; right: true }
    implicitHeight: clockItem.showAppLauncher ? 270 : 0
    color: "transparent"
    visible: clockItem.showAppLauncher
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.focusable: true

    MouseArea {
      anchors.fill: parent
      onClicked: clockItem.showAppLauncher = false
    }

    Item {
      width: 480; height: 240
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: 10

      AppLauncher {
        id: appLauncherOverlay
        anchors.fill: parent
        radius: 28
        appService: appLauncherSvc
        onCloseRequested: clockItem.showAppLauncher = false
        onHoveredChanged: clockItem.appLauncherHovered = hovered
      }
    }
  }

  AppLauncherService { id: appLauncherSvc }

  ControlCenter {
    isOpen: isControlCenterOpen
    storedNotifications: notifService.storedNotifications
    doNotDisturb: notifService.doNotDisturb
    onDndToggled: (val) => notifService.doNotDisturb = val
    onDismissNotif: (notifRef) => notifService.dismissNotif(notifRef)
    onClearNotifs: notifService.clearAll()
    onCloseRequested: isControlCenterOpen = false
  }
}
