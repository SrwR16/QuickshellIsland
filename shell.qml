import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "./Widgets/clock"
import "./controlCenter"
import "./Widgets/notifications"
import "./Widgets/launcher"
import "./Widgets/mode"
import "./core"
import "./Widgets/wallpaper"
import "./Widgets/askpass"

ShellRoot {
  id: root

  NotificationService {
    id: notifService
  }

  PanelWindow {
    anchors { top: true; left: true; right: true }
    // When a menu is open, expand the Wayland surface to cover the screen to intercept background clicks.
    // When closed, perfectly hug the island's animated height to prevent Wayland lag or visual clipping.
    implicitHeight: (clockItem.showControlCenter || clockItem.showPowerMenu || clockItem.showWallpaperMenu || clockItem.showAppLauncher) ? 4000 : clockItem.height + 20
    color: "transparent"

    // Fixed exclusive zone — notification banner makes the window taller
    // but keeps the clock's reservation so it floats over apps, not pushes them.
    WlrLayershell.exclusiveZone: 56
    // Exclusive keyboard grab when the askpass dialog is open — enables the
    // password field to receive keystrokes without requiring a click first.
    WlrLayershell.keyboardFocus: clockItem.showAskpass || clockItem.showControlCenter ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea {
      anchors.fill: parent
      enabled: clockItem.showPowerMenu || clockItem.showWallpaperMenu || clockItem.showControlCenter || clockItem.showAppLauncher

      // Wayland compositor requires drawn pixels to capture input. 
      // 0.4% alpha is invisible to the human eye but forces Hyprland to capture all outside clicks.
      Rectangle {
        anchors.fill: parent
        color: "#01000000"
        visible: parent.enabled
      }

      onClicked: {
        clockItem.showPowerMenu = false;
        clockItem.showWallpaperMenu = false;
        clockItem.showControlCenter = false;
        clockItem.isPinned = false;
      }
    }

    Clock {
      id: clockItem
      z: 10
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: 10

      opacity: 1
      visible: opacity > 0
      
      Behavior on opacity {
        NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
      }

      latestNotification: notifService.latestNotification
      latestNotificationData: notifService.latestNotificationData
      storedNotifications: notifService.storedNotifications
      onNotifDismissed: (notifRef) => notifService.dismissBanner(notifRef)
      onNotifBannerDismissed: (notifRef) => notifService.dismissBanner(notifRef)

      wallpaperSvc: wallpaperSvc
      modeSvc: modeSvc
      askpassSvc: askpassSvc
      showControlCenter: clockItem.showControlCenter
      onShowControlCenterChanged: {
        if (!showControlCenter) clockItem.showControlCenter = false;
      }
    }
  }

  Process {
    id: ipcChecker
    running: true
    command: ["sh", "-c",
      "while true; do " +
      "  out=''; " +
      "  test -f /tmp/qs-power-menu && rm /tmp/qs-power-menu && out=\"${out}p\"; " +
      "  test -f /tmp/qs-app-launcher && rm /tmp/qs-app-launcher && out=\"${out}a\"; " +
      "  test -f /tmp/qs-wallpaper && rm /tmp/qs-wallpaper && out=\"${out}w\"; " +
      "  test -f /tmp/qs-mode-cycle && rm /tmp/qs-mode-cycle && out=\"${out}m\"; " +
      "  test -f /tmp/qs-toggle-cc && rm /tmp/qs-toggle-cc && out=\"${out}c\"; " +
      "  test -f /tmp/qs-pomodoro && rm /tmp/qs-pomodoro && out=\"${out}f\"; " +
      "  test -f /tmp/qs-movies && rm /tmp/qs-movies && out=\"${out}v\"; " +
      "  test -f /tmp/qs-sys && rm /tmp/qs-sys && out=\"${out}s\"; " +
      "  test -f /tmp/qs-tray && rm /tmp/qs-tray && out=\"${out}t\"; " +
      "  if [ -n \"$out\" ]; then echo \"$out\"; fi; " +
      "  sleep 0.05; " +
      "done"
    ]
    stdout: SplitParser {
      onRead: (data) => {
        var flags = data.trim()
        if (flags.indexOf("p") >= 0 && !clockItem.showAppLauncher)
          clockItem.showPowerMenu = true
        if (flags.indexOf("a") >= 0 && !clockItem.showPowerMenu)
          clockItem.showAppLauncher = true
        if (flags.indexOf("w") >= 0)
          clockItem.showWallpaperMenu = !clockItem.showWallpaperMenu
        if (flags.indexOf("m") >= 0) {
          modeSvc.cycleMode();
          clockItem.showModeIndicator();
        }
        if (flags.indexOf("c") >= 0)
          clockItem.showControlCenter = !clockItem.showControlCenter;
        if (flags.indexOf("f") >= 0)
          clockItem.showPomodoro = !clockItem.showPomodoro;
        if (flags.indexOf("v") >= 0)
          clockItem.showMovies = !clockItem.showMovies;
        if (flags.indexOf("s") >= 0)
          clockItem.showSys = !clockItem.showSys;
        if (flags.indexOf("t") >= 0)
          clockItem.showTray = !clockItem.showTray;
      }
    }
  }
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

  // Watch colors.json generated by matugen → push new values into Theme singleton
  FileView {
    id: themeFileWatcher
    path: Quickshell.shellPath("core/colors.json")
    watchChanges: true
    onLoaded: applyColors()
    onTextChanged: applyColors()

    function applyColors() {
      var t = text().trim()
      if (t.length < 10) return
      try {
        var c = JSON.parse(t)
        if (c.background) Theme.background = c.background
        if (c.surface) Theme.surface = c.surface
        if (c.surfaceBright) Theme.surfaceBright = c.surfaceBright
        if (c.surfaceDim) Theme.surfaceDim = c.surfaceDim
        if (c.surfaceContainer) Theme.surfaceContainer = c.surfaceContainer
        if (c.surfaceVariant) Theme.surfaceVariant = c.surfaceVariant
        if (c.primary) Theme.primary = c.primary
        if (c.primaryFg) Theme.primaryFg = c.primaryFg
        if (c.secondary) Theme.secondary = c.secondary
        if (c.tertiary) Theme.tertiary = c.tertiary
        if (c.backgroundFg) Theme.backgroundFg = c.backgroundFg
        if (c.surfaceFg) Theme.surfaceFg = c.surfaceFg
        if (c.surfaceVariantFg) Theme.surfaceVariantFg = c.surfaceVariantFg
        if (c.outline) Theme.outline = c.outline
        if (c.outlineVariant) Theme.outlineVariant = c.outlineVariant
        if (c.error) Theme.error = c.error
      } catch (e) {
        console.error("theme colors parse error:", e)
      }
    }
  }

  WallpaperService { id: wallpaperSvc }

  AppLauncherService { id: appLauncherSvc }

  ModeService { id: modeSvc }

  AskpassService { id: askpassSvc }

  Shortcut {
    sequences: ["Alt+F5"]
    onActivated: { modeSvc.cycleMode(); clockItem.showModeIndicator(); }
    context: Qt.ApplicationShortcut
  }
}
