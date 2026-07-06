import "../overlay"
import "../widgets"
import "../services"
import "../theme"
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts


Rectangle {
  id: clockWidget

  property QtObject privacySvc
  property QtObject vpnSvc

  function exclusiveOpen(menuName) {
    if (menuName !== "cc") showControlCenter = false;
    if (menuName !== "power") showPowerMenu = false;
    if (menuName !== "app") showAppLauncher = false;
    if (menuName !== "wallpaper") showWallpaperMenu = false;
    if (menuName !== "movies") showMovies = false;
    if (menuName !== "sys") showSys = false;
    if (menuName !== "tray") showTray = false;
    if (menuName !== "battery") showBatteryAlert = false;
    if (menuName !== "battery") showBatteryAlert = false;
    if (menuName !== "askpass") showAskpass = false;
    if (menuName !== "prod") showProductivity = false;
    if (menuName !== "vpn") showVpn = false;
  }

  property bool showControlCenter: false
  property bool showVpn: false
  onShowControlCenterChanged: {
    if (showControlCenter) exclusiveOpen("cc");
    else isPinned = false; // Force unpin when closing so it fully shrinks down to 36px
  }

  property bool isPinned: false
  property bool hasMedia: media.mediaState !== "Idle"
  // Added powerMouseArea.containsMouse so the island doesn't collapse when hovering the power button
  property bool isExpanded: mouseArea.containsMouse || statusCapsule.isHovered || (typeof mediaSectionItem !== "undefined" && mediaSectionItem.isHovered) || (typeof powerMouseArea !== "undefined" && powerMouseArea.containsMouse) || (typeof timeMouseArea !== "undefined" && timeMouseArea.containsMouse) || (typeof dateMouseArea !== "undefined" && dateMouseArea.containsMouse) || isPinned || showControlCenter || showProductivity
  signal toggleControlCenter()

  // --- Morph mode ---
  property string mode: "default"
  property bool _ready: false

  Timer {
    interval: 1000; running: true; repeat: false
    onTriggered: {
      _ready = true;
      if (latestNotificationData && notifUnpinTimer)
        notifUnpinTimer.restart();
    }
  }

  // --- Audio ---
  readonly property PwNode audioSink: Pipewire.defaultAudioSink
  readonly property bool audioMuted: !!audioSink?.audio?.muted
  readonly property real volume: Math.min(1, Math.max(0, audioSink?.audio?.volume ?? 0))

  PwObjectTracker {
    objects: clockWidget.audioSink ? [clockWidget.audioSink] : []
  }

  onVolumeChanged: {
    if (_ready && !clockWidget.isExpanded) {
      mode = "volume";
      revertTimer.restart();
    }
  }

  onAudioMutedChanged: {
    if (_ready && !clockWidget.isExpanded) {
      mode = "volume";
      revertTimer.restart();
    }
  }

  function volumeIcon(vol, muted) {
    if (muted || vol <= 0) return "󰝟";
    if (vol < 0.34) return "󰕿";
    if (vol < 0.67) return "󰖀";
    return "󰕾";
  }

  // --- Combined polling: brightness, caps lock, num lock, kbd backlight ---
  property QtObject hwMonitor
  
  property real brightness: hwMonitor ? hwMonitor.brightness : 0
  property bool capsLock: hwMonitor ? hwMonitor.capsLock : false
  property bool numLock: hwMonitor ? hwMonitor.numLock : false
  property real kbdBrightness: hwMonitor ? hwMonitor.kbdBrightness : 0

  onKbdBrightnessChanged: {
    if (_ready && !clockWidget.isExpanded) {
      mode = "kbdbacklight";
      revertTimer.restart();
    }
  }

  onBrightnessChanged: {
    if (_ready && !clockWidget.isExpanded) {
      mode = "brightness";
      revertTimer.restart();
    }
  }

  function brightnessIcon(val) {
    if (val < 0.34) return "󰃞";
    if (val < 0.67) return "󰃟";
    return "󰃠";
  }

  onNumLockChanged: {
    if (_ready && !clockWidget.isExpanded) {
      mode = "numlock";
      revertTimer.restart();
    }
  }

  onCapsLockChanged: {
    if (_ready && !clockWidget.isExpanded) {
      mode = "capslock";
      revertTimer.restart();
    }
  }

  // --- Power menu state ---
  property bool showPowerMenu: false
  signal showPowerMenuRequested()
  property bool powerMenuHovered: powerMenuComponent ? powerMenuComponent.hovered : false
  property Timer powerMenuTimer: Timer {
    interval: 10000
    onTriggered: clockWidget.showPowerMenu = false
  }

  property Process powerActionProc: Process { running: false }

  function powerAction(cmd) {
    powerActionProc.command = cmd;
    powerActionProc.running = true;
    clockWidget.showPowerMenu = false;
  }

  // --- Mode indicator ---
  property var modeSvc: null
  function showModeIndicator() {
    if (_ready && !isExpanded) {
      mode = "mode";
      revertTimer.restart();
    }
  }

  // --- App launcher state ---
  property bool showAppLauncher: false
  property bool appLauncherHovered: false
  property Timer appLauncherTimer: Timer {
    interval: 15000
    onTriggered: clockWidget.showAppLauncher = false
  }

  // --- Wallpaper menu state ---
  property bool showWallpaperMenu: false
  property bool wallpaperMenuHovered: false
  property var wallpaperSvc: null
  property Timer wallpaperMenuTimer: Timer {
    interval: 20000
    onTriggered: clockWidget.showWallpaperMenu = false
  }

  // --- System Status for Alerts ---
  StatusService { id: sysStatus }

  // --- Battery Alert state ---
  property bool showBatteryAlert: false
  property bool showProductivity: false
  property string productivityPage: "time"
  // Add showVpn to anyOverlayActive
  property bool anyOverlayActive: showBatteryAlert || showPomodoro || showMovies || showSys || showTray || showPowerMenu || showAppLauncher || showWallpaperMenu || showAskpass || showProductivity || showVpn || showingNotification
  property string batteryAlertMode: "charging" // "charging", "unplugged", "low"
  property Timer batteryAlertTimer: Timer {
    interval: 2000 // Reduced from 3000ms so it doesn't stay visible for too long
    onTriggered: clockWidget.showBatteryAlert = false
  }

  Connections {
    target: sysStatus
    function onChargingChanged() {
      if (clockWidget._ready) {
        clockWidget.batteryAlertMode = sysStatus.charging ? "charging" : "unplugged"
        clockWidget.showBatteryAlert = true
      }
    }
    function onBatteryChanged() {
      if (clockWidget._ready && !sysStatus.charging && sysStatus.battery <= 20) {
        clockWidget.batteryAlertMode = "low"
        clockWidget.showBatteryAlert = true
      }
    }
  }

  onShowBatteryAlertChanged: {
    if (showBatteryAlert) {
      exclusiveOpen("battery");
      batteryAlertTimer.restart();
    }
  }

  // --- Pomodoro, Movies, System, Tray state ---
  property bool showPomodoro: false
  property bool showMovies: false
  property bool showSys: false
  property bool showTray: false
  
  onShowPomodoroChanged: {
    if (showPomodoro) {
      exclusiveOpen("pomodoro");
    }
  }

  onShowMoviesChanged: {
    if (showMovies) {
      exclusiveOpen("movies");
    }
  }

  onShowSysChanged: {
    if (showSys) {
      exclusiveOpen("sys");
    }
  }

  onShowTrayChanged: {
    if (showTray) {
      exclusiveOpen("tray");
    }
  }

  // --- Notification state ---
  // Set from shell.qml via the latestNotification property binding.
  // When non-null, the island auto-expands to show the Dynamic Island banner.
  property var latestNotification: null
  property var latestNotificationData: null
  property var storedNotifications: []
  signal notifDismissed(var notifRef)
  signal notifBannerDismissed(var notifRef)

  // True while the notification banner is the active view
  readonly property bool showingNotification: latestNotification !== null

  // --- Power menu lifecycle ---
  onShowPowerMenuRequested: {
    showPowerMenu = true;
    if (powerMenuTimer) powerMenuTimer.restart();
  }

  onShowPowerMenuChanged: {
    if (showPowerMenu) {
      exclusiveOpen("power");
      if (powerMenuTimer) powerMenuTimer.restart();
    }
  }

  onPowerMenuHoveredChanged: {
    if (powerMenuHovered && powerMenuTimer.running) {
      powerMenuTimer.stop();
    } else if (!powerMenuHovered && showPowerMenu) {
      powerMenuTimer.restart();
    }
  }

  // --- App launcher lifecycle ---
  onShowAppLauncherChanged: {
    if (showAppLauncher) {
      exclusiveOpen("app");
      if (appLauncherTimer) appLauncherTimer.restart();
    }
  }

  onAppLauncherHoveredChanged: {
    if (appLauncherHovered && appLauncherTimer.running) {
      appLauncherTimer.stop();
    } else if (!appLauncherHovered && showAppLauncher) {
      appLauncherTimer.restart();
    }
  }

  // --- Wallpaper menu lifecycle ---
  onShowWallpaperMenuChanged: {
    if (showWallpaperMenu) {
      exclusiveOpen("wallpaper");
      if (wallpaperMenuTimer) wallpaperMenuTimer.restart();
      if (wallpaperSvc) wallpaperSvc.rescan();
    }
  }

  onWallpaperMenuHoveredChanged: {
    if (wallpaperMenuHovered && wallpaperMenuTimer.running) {
      wallpaperMenuTimer.stop();
    } else if (!wallpaperMenuHovered && showWallpaperMenu) {
      wallpaperMenuTimer.restart();
    }
  }

  // --- Notification lifecycle ---
  onLatestNotificationDataChanged: {
    if (_ready && latestNotificationData) {
      if (showPowerMenu) showPowerMenu = false;
      if (showAppLauncher) showAppLauncher = false;
      if (showWallpaperMenu) showWallpaperMenu = false;
      if (notifUnpinTimer) notifUnpinTimer.restart();
    }
  }

  readonly property bool notifHovered: (mouseArea && mouseArea.containsMouse) || (statusCapsule && statusCapsule.isHovered) || (notifBanner && notifBanner.bannerHovered)

  onNotifHoveredChanged: {
    if (notifHovered && notifUnpinTimer.running) {
      notifUnpinTimer.stop();
    } else if (!notifHovered && _ready && latestNotificationData) {
      notifUnpinTimer.restart();
    }
  }

  Timer {
    id: notifUnpinTimer
    interval: 3500
    onTriggered: {
      clockWidget.notifBannerDismissed(clockWidget.latestNotificationData);
    }
  }

  Timer {
    id: revertTimer
    interval: 2000
    onTriggered: mode = "default"
  }

  // --- Layout ---
  MediaService { id: media }

  // --- Askpass dialog state ---
  property var askpassSvc: null
  property bool showAskpass: askpassSvc && askpassSvc.pendingRequest !== null

  // Size changes are the core of the Dynamic Island morph.
  property string morphState: showProductivity ? "productivity" 
                            : showControlCenter ? "controlCenter" 
                            : showAppLauncher ? "appLauncher" 
                            : showWallpaperMenu ? "wallpaperMenu" 
                            : showAskpass ? "askpass" 
                            : showMovies ? "movies" 
                            : showVpn ? "vpn" 
                            : (latestNotificationData || showPowerMenu) ? "notificationOrPower" 
                            : showTray ? "tray" 
                            : showSys ? "sys" 
                            : showPomodoro ? "pomodoro" 
                            : showBatteryAlert ? "batteryAlert" 
                            : "default"

  state: morphState

  states: [
    State {
      name: "default"
      PropertyChanges { target: clockWidget; height: isExpanded ? 64 : 36; width: isExpanded ? 540 : (mode !== "default") ? indicatorRow.implicitWidth + 32 : collapsedContent.contentWidth + 86; radius: isExpanded ? 22 : 18 }
    },
    State {
      name: "productivity"
      PropertyChanges { target: clockWidget; height: typeof prodLoader !== "undefined" && prodLoader.item ? prodLoader.item.implicitHeight + 70 : 800; width: 540; radius: 28 }
    },
    State {
      name: "controlCenter"
      PropertyChanges { target: clockWidget; height: typeof ccLoader !== "undefined" && ccLoader.item ? ccLoader.item.implicitHeight + 70 : 870; width: 680; radius: 24 }
    },
    State {
      name: "appLauncher"
      PropertyChanges { target: clockWidget; height: 240; width: 480; radius: 28 }
    },
    State {
      name: "wallpaperMenu"
      PropertyChanges { target: clockWidget; height: 300; width: 640; radius: 28 }
    },
    State {
      name: "askpass"
      PropertyChanges { target: clockWidget; height: 200; width: 480; radius: 28 }
    },
    State {
      name: "movies"
      PropertyChanges { target: clockWidget; height: 540; width: 540; radius: 28 }
    },
    State {
      name: "vpn"
      PropertyChanges { target: clockWidget; height: 200; width: 480; radius: 28 }
    },
    State {
      name: "notificationOrPower"
      PropertyChanges { target: clockWidget; height: 130; width: 480; radius: 28 }
    },
    State {
      name: "tray"
      PropertyChanges { target: clockWidget; height: 120; width: 440; radius: 28 }
    },
    State {
      name: "sys"
      PropertyChanges { target: clockWidget; height: 100; width: 480; radius: 28 }
    },
    State {
      name: "pomodoro"
      PropertyChanges { target: clockWidget; height: 76; width: 380; radius: 28 }
    },
    State {
      name: "batteryAlert"
      PropertyChanges { target: clockWidget; height: 48; width: 220; radius: 24 }
    }
  ]

  color: Theme.background

  // Fluid morph animation for expansion/collapse (Apple-like)
  Behavior on height { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
  Behavior on width  { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
  Behavior on radius { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true

    onClicked: (mouse) => {
      if (clockWidget.showingNotification) return;
      if (clockWidget.showPowerMenu) {
        clockWidget.showPowerMenu = false;
        return;
      }
      if (clockWidget.showWallpaperMenu) {
        clockWidget.showWallpaperMenu = false;
        return;
      }
      if (clockWidget.showPomodoro) {
        clockWidget.showPomodoro = false;
        return;
      }
      if (clockWidget.showMovies) {
        clockWidget.showMovies = false;
        return;
      }
      if (clockWidget.showSys) {
        clockWidget.showSys = false;
        return;
      }
      if (clockWidget.showTray) {
        clockWidget.showTray = false;
        return;
      }
      if (clockWidget.showControlCenter) {
        return; // Do nothing if they click the background of the control center itself
      }
      if (clockWidget.showAppLauncher) return;
      if (clockWidget.isExpanded) {
        let mappedPos = mouseArea.mapToItem(expandedContent, mouse.x, mouse.y);
        let clickedItem = expandedContent.childAt(mappedPos.x, mappedPos.y);
        if (clickedItem !== null) return;
      }
      clockWidget.isPinned = !clockWidget.isPinned;
    }
  }

  // --- Collapsed: clock + cava (default) ---
  Item {
    id: collapsedContent
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 36

    opacity: clockWidget.isExpanded || clockWidget.mode !== "default" || clockWidget.anyOverlayActive ? 0.0 : 1.0
    visible: opacity > 0.0
    Behavior on opacity { NumberAnimation { duration: 200 } }

    property real leftWidth: media.playing ? visualizerContainer.width + 12 : 0
    property real rightWidth: (PomodoroService.sessionState !== "Idle" ? pomodoroRow.implicitWidth + 12 : 0) + (privacyContainer.targetWidth > 0 ? privacyContainer.targetWidth + 12 : 0)
    property real maxSide: Math.max(leftWidth, rightWidth)
    property real contentWidth: collapsedClockText.implicitWidth + maxSide * 2

    Text {
      id: collapsedClockText
      anchors.centerIn: parent
      text: Qt.formatDateTime(clock.date, "h:mm AP")
      color: Theme.text
      font { family: "Inter"; pixelSize: 14; weight: 500 }
    }

    Item {
      id: visualizerContainer
      anchors.right: collapsedClockText.left
      anchors.rightMargin: media.playing ? 12 : 0
      anchors.verticalCenter: parent.verticalCenter
      property real targetWidth: media.playing ? 14 : 0
      width: targetWidth
      height: 12
      clip: true

      Behavior on anchors.rightMargin { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }

      Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        height: 12

        Rectangle { width: 2; height: Math.min(12, media.bars[0]); radius: 1; color: Theme.primary; anchors.bottom: parent.bottom }
        Rectangle { width: 2; height: Math.min(12, media.bars[1]); radius: 1; color: Theme.primary; anchors.bottom: parent.bottom }
        Rectangle { width: 2; height: Math.min(12, media.bars[2]); radius: 1; color: Theme.primary; anchors.bottom: parent.bottom }
        Rectangle { width: 2; height: Math.min(12, media.bars[3]); radius: 1; color: Theme.primary; anchors.bottom: parent.bottom }
      }
    }

    // Live Activity: Pomodoro
    RowLayout {
      id: pomodoroRow
      anchors.left: collapsedClockText.right
      anchors.leftMargin: PomodoroService.sessionState !== "Idle" ? 12 : 0
      anchors.verticalCenter: parent.verticalCenter
      visible: PomodoroService.sessionState !== "Idle"
      spacing: 6
      
      Behavior on anchors.leftMargin { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }

      Rectangle {
        Layout.preferredWidth: 2
        Layout.preferredHeight: 14
        Layout.alignment: Qt.AlignVCenter
        radius: 1
        color: Theme.border
      }

      Text {
        text: ""
        color: PomodoroService.sessionState === "Work" ? Theme.primary : Theme.tertiary
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
      }
      Text {
        text: PomodoroService.formatTime()
        color: PomodoroService.sessionState === "Work" ? Theme.primary : Theme.tertiary
        font.family: "JetBrains Mono"
        font.pixelSize: 13
        font.weight: 700
      }
    }

    Item {
      id: privacyContainer
      anchors.left: PomodoroService.sessionState !== "Idle" ? pomodoroRow.right : collapsedClockText.right
      anchors.leftMargin: active ? 12 : 0
      anchors.verticalCenter: parent.verticalCenter
      property bool active: (clockWidget.vpnSvc && clockWidget.vpnSvc.isActive) || (clockWidget.privacySvc && (clockWidget.privacySvc.isMicActive || clockWidget.privacySvc.isWebcamActive))
      property real targetWidth: active ? privacyRow.implicitWidth : 0
      width: targetWidth
      height: 18
      clip: true

      Behavior on anchors.leftMargin { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }

      Row {
        id: privacyRow
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Text {
          text: "󰒄"
          color: Theme.primary
          font { family: "JetBrainsMono Nerd Font"; pixelSize: 14 }
          visible: clockWidget.vpnSvc && clockWidget.vpnSvc.isActive
        }

        Rectangle {
          width: 6; height: 6; radius: 3; color: "#f5a623"
          visible: clockWidget.privacySvc && clockWidget.privacySvc.isMicActive
          anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
          width: 6; height: 6; radius: 3; color: "#34c759"
          visible: clockWidget.privacySvc && clockWidget.privacySvc.isWebcamActive
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        visible: clockWidget.vpnSvc && clockWidget.vpnSvc.isActive
        onClicked: {
          clockWidget.exclusiveOpen("vpn");
          clockWidget.showVpn = !clockWidget.showVpn;
        }
      }
    }
  }

  // --- Collapsed: volume / brightness indicator ---
  RowLayout {
    id: indicatorRow
    anchors.centerIn: parent
    spacing: 8

    opacity: !clockWidget.isExpanded && clockWidget.mode !== "default" ? 1.0 : 0.0
    visible: opacity > 0.0
    Behavior on opacity { NumberAnimation { duration: 200 } }

    // Volume mode
    RowLayout {
      spacing: 8
      visible: clockWidget.mode === "volume"

      Text {
        text: clockWidget.volumeIcon(clockWidget.volume, clockWidget.audioMuted)
        color: clockWidget.audioMuted ? Theme.subtext : Theme.primary
        font { family: "JetBrainsMono Nerd Font"; pixelSize: 18 }
        Behavior on color { ColorAnimation { duration: 120 } }
      }

      Item {
        width: 80; height: 6
        Rectangle {
          anchors.fill: parent; radius: 3; color: Theme.border
          Rectangle {
            anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
            width: parent.width * (clockWidget.audioMuted ? 0 : clockWidget.volume)
            radius: 3
            color: clockWidget.audioMuted ? Theme.border : Theme.primary
            Behavior on width { NumberAnimation { duration: 150; easing: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 120 } }
          }
        }
      }

      Text {
        text: Math.round((clockWidget.audioMuted ? 0 : clockWidget.volume) * 100) + "%"
        color: clockWidget.audioMuted ? Theme.subtext : Theme.text
        font { family: "Inter"; pixelSize: 13; weight: 700 }
        Behavior on color { ColorAnimation { duration: 120 } }
      }
    }

    // Brightness mode
    RowLayout {
      spacing: 8
      visible: clockWidget.mode === "brightness"

      Text {
        text: clockWidget.brightnessIcon(clockWidget.brightness)
        color: Qt.rgba(
          0.89, 0.7 + 0.25 * clockWidget.brightness, 0.25,
          0.4 + 0.6 * clockWidget.brightness
        )
        font { family: "JetBrainsMono Nerd Font"; pixelSize: 18 }
        Behavior on color { ColorAnimation { duration: 200 } }
      }

      Item {
        width: 80; height: 6
        Rectangle {
          anchors.fill: parent; radius: 3; color: Theme.border
          Rectangle {
            anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
            width: parent.width * clockWidget.brightness
            radius: 3; color: Theme.warning
            Behavior on width { NumberAnimation { duration: 200; easing: Easing.OutCubic } }
          }
        }
      }

      Text {
        text: Math.round(clockWidget.brightness * 100) + "%"
        color: Theme.text
        font { family: "Inter"; pixelSize: 13; weight: 700 }
      }
    }

    // Kbd Brightness mode
    RowLayout {
      spacing: 8
      visible: clockWidget.mode === "kbdbacklight"

      Text {
        text: "󰌌"
        color: Theme.primary
        font { family: "JetBrainsMono Nerd Font"; pixelSize: 18 }
      }

      Item {
        width: 80; height: 6
        Rectangle {
          anchors.fill: parent; radius: 3; color: Theme.border
          Rectangle {
            anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
            width: parent.width * clockWidget.kbdBrightness
            radius: 3; color: Theme.primary
            Behavior on width { NumberAnimation { duration: 200; easing: Easing.OutCubic } }
          }
        }
      }

      Text {
        text: Math.round(clockWidget.kbdBrightness * 100) + "%"
        color: Theme.text
        font { family: "Inter"; pixelSize: 13; weight: 700 }
      }
    }

    // Caps Lock mode
    RowLayout {
      spacing: 8
      visible: clockWidget.mode === "capslock"

      Text {
        text: "󰜹"
        color: clockWidget.capsLock ? Theme.primary : Theme.subtext
        font { family: "JetBrainsMono Nerd Font"; pixelSize: 18 }
        Behavior on color { ColorAnimation { duration: 120 } }
      }

      Text {
        text: clockWidget.capsLock ? "ON" : "OFF"
        color: clockWidget.capsLock ? Theme.text : Theme.subtext
        font { family: "Inter"; pixelSize: 13; weight: 700 }
        Behavior on color { ColorAnimation { duration: 120 } }
      }
    }

    // Num Lock mode
    RowLayout {
      spacing: 8
      visible: clockWidget.mode === "numlock"

      Text {
        text: "󰎦"
        color: clockWidget.numLock ? Theme.primary : Theme.subtext
        font { family: "JetBrainsMono Nerd Font"; pixelSize: 18 }
        Behavior on color { ColorAnimation { duration: 120 } }
      }

      Text {
        text: clockWidget.numLock ? "ON" : "OFF"
        color: clockWidget.numLock ? Theme.text : Theme.subtext
        font { family: "Inter"; pixelSize: 13; weight: 700 }
        Behavior on color { ColorAnimation { duration: 120 } }
      }
    }

    // Mode indicator
    RowLayout {
      spacing: 8
      visible: clockWidget.mode === "mode"

      Text {
        text: {
          if (!clockWidget.modeSvc) return "";
          var m = clockWidget.modeSvc.currentMode;
          if (m === "silent") return "";
          if (m === "performance") return "";
          return "";
        }
        color: {
          if (!clockWidget.modeSvc) return Theme.subtext;
          var m = clockWidget.modeSvc.currentMode;
          if (m === "silent") return Theme.tertiary;
          if (m === "performance") return Theme.error;
          return Theme.primary;
        }
        font { family: "JetBrainsMono Nerd Font"; pixelSize: 18 }
      }

      Text {
        text: {
          if (!clockWidget.modeSvc) return "Balanced";
          var m = clockWidget.modeSvc.currentMode;
          return m.charAt(0).toUpperCase() + m.slice(1);
        }
        color: Theme.text
        font { family: "Inter"; pixelSize: 13; weight: 700 }
      }
    }

  }

  // --- Expanded content (regular) ---
  // Visible when expanded with no notification: shows media player, clock, status capsule.
  Item {
    id: expandedContent
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 64
    anchors.leftMargin: 16
    anchors.rightMargin: 16

    opacity: (clockWidget.isExpanded || clockWidget.showControlCenter) && !clockWidget.showingNotification && !clockWidget.showPomodoro && !clockWidget.showMovies && !clockWidget.showSys && !clockWidget.showBatteryAlert && !clockWidget.showTray ? 1.0 : 0.0
    visible: opacity > 0.0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    MediaSection {
      id: mediaSectionItem
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      trackTitle: media.title
      trackArtist: media.artist
      trackArt: media.art
      mediaState: media.mediaState
      barHeights: media.bars
    }

    Item {
      id: centerSection
      anchors.centerIn: parent

      ColumnLayout {
        id: clockView
        anchors.centerIn: parent
        spacing: 4

        // Time
        Rectangle {
          Layout.alignment: Qt.AlignHCenter
          width: clockText.implicitWidth + 16
          height: clockText.implicitHeight + 8
          radius: 8
          color: timeMouseArea.containsMouse ? Theme.surfaceHover : "transparent"
          
          Text {
            id: clockText
            anchors.centerIn: parent
            text: Qt.formatDateTime(clock.date, "h:mm AP")
            color: Theme.text
            font { family: "Inter"; pixelSize: 20; weight: 700 }
          }
          
          MouseArea {
            id: timeMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (clockWidget.showProductivity && clockWidget.productivityPage === "time") {
                clockWidget.showProductivity = false;
              } else {
                clockWidget.exclusiveOpen("prod");
                clockWidget.productivityPage = "time";
                clockWidget.showProductivity = true;
              }
            }
          }
        }

        // Date
        Rectangle {
          Layout.alignment: Qt.AlignHCenter
          width: dateText.implicitWidth + 12
          height: dateText.implicitHeight + 4
          radius: 6
          color: dateMouseArea.containsMouse ? Theme.surfaceHover : "transparent"

          Text {
            id: dateText
            anchors.centerIn: parent
            text: Qt.formatDateTime(clock.date, "ddd, MMM d")
            color: Theme.text
            opacity: dateMouseArea.containsMouse ? 1.0 : 0.5
            font { family: "Inter"; pixelSize: 11; weight: 500 }
            Behavior on opacity { NumberAnimation { duration: 150 } }
          }

          MouseArea {
            id: dateMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (clockWidget.showProductivity && clockWidget.productivityPage === "calendar") {
                clockWidget.showProductivity = false;
              } else {
                clockWidget.exclusiveOpen("prod");
                clockWidget.productivityPage = "calendar";
                clockWidget.showProductivity = true;
              }
            }
          }
        }
      }
    }

    StatusCapsule {
      id: statusCapsule
      anchors.right: powerButton.left
      anchors.rightMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      onClicked: clockWidget.showControlCenter = !clockWidget.showControlCenter
    }

    Rectangle {
      id: powerButton
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      width: 32; height: 32
      radius: 16
      color: powerMouseArea.containsMouse ? Theme.surfaceHover : "transparent"
      Behavior on color { ColorAnimation { duration: 150 } }
      
      Text {
        anchors.centerIn: parent
        text: "󰐥"
        color: Theme.error
        font { family: "JetBrainsMono Nerd Font"; pixelSize: 18 }
      }
      
      MouseArea {
        id: powerMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: clockWidget.showPowerMenu = !clockWidget.showPowerMenu
      }
    }
  }

  // --- Pomodoro expanded overlay ---
  Item {
    id: pomodoroExpandedContent
    anchors.fill: parent
    anchors.margins: 16

    opacity: clockWidget.showPomodoro ? 1.0 : 0.0
    visible: opacity > 0.0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    PomodoroSection {
      anchors.fill: parent
    }
  }

  // --- Movies expanded overlay ---
  Item {
    id: moviesExpandedContent
    anchors.fill: parent
    anchors.margins: 16

    opacity: clockWidget.showMovies ? 1.0 : 0.0
    visible: opacity > 0.0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    Loader {
      id: movieLoader
      anchors.fill: parent
      active: clockWidget.showMovies || opacity > 0.0
      sourceComponent: Component {
        MovieSection {
        }
      }
    }
  }

  // --- Sys expanded overlay ---
  Item {
    id: sysExpandedContent
    anchors.fill: parent
    anchors.margins: 16

    opacity: clockWidget.showSys ? 1.0 : 0.0
    visible: opacity > 0.0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    SystemUsageSection {
      anchors.fill: parent
    }
  }

  // --- Battery Alert expanded overlay ---
  Item {
    id: batteryAlertExpandedContent
    anchors.fill: parent
    anchors.margins: 12

    opacity: clockWidget.showBatteryAlert ? 1.0 : 0.0
    visible: opacity > 0.0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    RowLayout {
      anchors.centerIn: parent
      spacing: 12
      
      Item {
        width: 48; height: 22
        Layout.alignment: Qt.AlignVCenter

        Rectangle {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          width: 42; height: 20
          radius: 6
          color: "transparent"
          border.color: Theme.text
          border.width: 1
          opacity: 0.4
        }

        Rectangle {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          anchors.margins: 3
          anchors.leftMargin: 3
          height: 14
          width: Math.max(0, 36 * (sysStatus.battery / 100))
          radius: 3
          color: clockWidget.batteryAlertMode === "charging" ? Theme.primary : (clockWidget.batteryAlertMode === "low" ? Theme.error : Theme.text)
        }

        Rectangle {
          anchors.left: parent.left
          anchors.leftMargin: 43
          anchors.verticalCenter: parent.verticalCenter
          width: 4; height: 8
          radius: 2
          color: Theme.text
          opacity: 0.4
        }

        Text {
          anchors.centerIn: parent
          text: "󱐋"
          font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
          visible: clockWidget.batteryAlertMode === "charging"
          color: Theme.background
          z: 1
        }
      }
      Text {
        text: clockWidget.batteryAlertMode === "charging" ? "Charging" : (clockWidget.batteryAlertMode === "low" ? "Battery Low" : "Unplugged")
        color: Theme.text
        font.family: "Inter"
        font.pixelSize: 14
        font.weight: 600
      }
      Text {
        text: sysStatus.battery + "%"
        color: clockWidget.batteryAlertMode === "charging" ? Theme.primary : (clockWidget.batteryAlertMode === "low" ? Theme.error : Theme.text)
        font.family: "Inter"
        font.pixelSize: 14
        font.weight: 600
      }
    }
  }

  // --- Tray expanded overlay ---
  Item {
    id: trayExpandedContent
    anchors.fill: parent
    opacity: clockWidget.showTray ? 1.0 : 0.0
    visible: opacity > 0.0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    SystemTraySection {
      anchors.fill: parent
    }
  }

  // --- Control Center expanded overlay ---
  Item {
    id: ccExpandedContent
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: 20
    anchors.topMargin: 64
    height: Math.max(0, parent.height - 84) // Prevent negative heights during morph which completely breaks the QML rendering engine
    clip: true // Apple-style smooth unmasking: we clip the perfectly rendered internal layout as the island smoothly morphs!

    opacity: clockWidget.showControlCenter ? 1.0 : 0.0
    visible: opacity > 0.0
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } } // Fades out slightly faster than the morph so it doesn't leave ghost images

    MouseArea {
      anchors.fill: parent
      onClicked: {} // Consume clicks so they don't fall through to the background and pin the island
    }

    Loader {
      id: ccLoader
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      active: clockWidget.showControlCenter || opacity > 0.0
      sourceComponent: Component {
        ControlCenter {
          height: implicitHeight // Instantly snaps to final layout size to prevent jittery recalculations during morph!
          isOpen: clockWidget.showControlCenter
          modeSvc: clockWidget.modeSvc
          storedNotifications: clockWidget.notifService ? clockWidget.notifService.storedNotifications : []
          doNotDisturb: clockWidget.notifService ? clockWidget.notifService.doNotDisturb : false
          onDndToggled: (val) => { if (clockWidget.notifService) clockWidget.notifService.doNotDisturb = val; }
          onDismissNotif: (notifRef) => { if (clockWidget.notifService) clockWidget.notifService.dismissNotif(notifRef); }
          onClearNotifs: { if (clockWidget.notifService) clockWidget.notifService.clearAll(); }
          onCloseRequested: clockWidget.showControlCenter = false
        }
      }
    }
  }

  // --- Productivity Center overlay ---
  Item {
    id: prodExpandedContent
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: 20
    anchors.topMargin: 64
    height: Math.max(0, parent.height - 84)
    clip: true

    opacity: clockWidget.showProductivity ? 1.0 : 0.0
    visible: opacity > 0.0
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }

    MouseArea {
      anchors.fill: parent
      onClicked: {} // Consume clicks
    }

    Loader {
      id: prodLoader
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      active: clockWidget.showProductivity || opacity > 0.0
      sourceComponent: Component {
        ProductivityCenter {
          height: implicitHeight
          isOpen: clockWidget.showProductivity
          page: clockWidget.productivityPage
          onRequestClose: clockWidget.showProductivity = false
        }
      }
    }
  }

  // --- Power menu overlay ---
  PowerMenu {
    id: powerMenuComponent
    anchors.fill: parent
    visible: clockWidget.showPowerMenu
    powerAction: clockWidget.powerAction
  }

  // --- Wallpaper menu overlay ---
  Item {
    id: wallpaperMenuComponent
    anchors.fill: parent
    clip: true
    visible: clockWidget.showWallpaperMenu

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 16
      spacing: 8

      // Header
      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
          text: ""
          color: Theme.tertiary
          font { family: "JetBrainsMono Nerd Font"; pixelSize: 16 }
        }

        Text {
          text: "Wallpapers"
          color: Theme.text
          font { family: "Inter"; pixelSize: 14; weight: Font.Bold }
          Layout.fillWidth: true
        }

        Text {
          text: "✕"
          color: Theme.text
          opacity: 0.5
          font.pixelSize: 13
          MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: clockWidget.showWallpaperMenu = false
          }
        }
      }

      // Grid
      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 12
        color: Theme.container
        clip: true

        WallpaperGrid {
          anchors.fill: parent
          anchors.margins: 8
          wallpaperModel: clockWidget.wallpaperSvc ? clockWidget.wallpaperSvc.wallpapers : []
          wallService: clockWidget.wallpaperSvc
          onWallpaperChosen: function(path) {
            clockWidget.showWallpaperMenu = false
          }
        }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
            onEntered: clockWidget.wallpaperMenuHovered = true
            onExited: clockWidget.wallpaperMenuHovered = false
          }
      }
    }
  }

  Notifications {
    id: notifBanner
    anchors.centerIn: parent

    notification: clockWidget.latestNotification
    notificationData: clockWidget.latestNotificationData

    onDismissed: (notifRef) => {
      if (clockWidget.notifUnpinTimer)
        clockWidget.notifUnpinTimer.stop();
      clockWidget.notifDismissed(notifRef);
    }
  }

  PasswordAskpassDialog {
    id: askpassDialog
    anchors.centerIn: parent

    promptText: clockWidget.showAskpass && clockWidget.askpassSvc ? clockWidget.askpassSvc.pendingRequest.prompt : ""
    fifoPath: clockWidget.showAskpass && clockWidget.askpassSvc ? clockWidget.askpassSvc.pendingRequest.fifoPath : ""

    onSubmitted: (password) => { if (clockWidget.askpassSvc) clockWidget.askpassSvc.submit(password); }
    onCancelled: { if (clockWidget.askpassSvc) clockWidget.askpassSvc.cancel(); }
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  VpnSection {
    vpnSvc: clockWidget.vpnSvc
    visible: clockWidget.showVpn
    opacity: visible ? 1 : 0
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: 56
    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
  }
}

