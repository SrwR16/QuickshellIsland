import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

import "../media"
import "../status"
import "../notifications"
import "../power"

Rectangle {
  id: clockWidget

  property bool isPlaying: media.playing
  property var barHeights: media.bars
  property string trackTitle: media.title
  property string trackArtist: media.artist
  property string trackArt: media.art

  property bool isPinned: false
  property bool isExpanded: mouseArea.containsMouse || statusCapsule.isHovered || isPinned
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

  // --- Brightness ---
  property real brightness: 0

  property Process brightnessProc: Process {
    command: ["brightnessctl", "-m"]
    stdout: StdioCollector {
      onStreamFinished: {
        const parts = this.text.trim().split(",");
        if (parts.length >= 5) {
          const pct = parseInt(parts[3]);
          if (!isNaN(pct)) {
            clockWidget.brightness = Math.max(0, Math.min(1, pct / 100));
          }
        }
      }
    }
  }

  Timer {
    id: brightnessPoll
    interval: 100; running: true; repeat: true
    onTriggered: {
      if (!clockWidget.brightnessProc.running)
        clockWidget.brightnessProc.running = true;
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

  // --- Caps Lock ---
  property bool capsLock: false

  property Process capsLockProc: Process {
    command: ["sh", "-c", "cat /sys/class/leds/*capslock*/brightness 2>/dev/null | head -1"]
    stdout: StdioCollector {
      onStreamFinished: {
        const val = this.text.trim();
        clockWidget.capsLock = val === "1";
      }
    }
  }

  Timer {
    interval: 200; running: true; repeat: true
    onTriggered: {
      if (!clockWidget.capsLockProc.running)
        clockWidget.capsLockProc.running = true;
    }
  }

  // --- Num Lock ---
  property bool numLock: false

  property Process numLockProc: Process {
    command: ["sh", "-c", "cat /sys/class/leds/*numlock*/brightness 2>/dev/null | head -1"]
    stdout: StdioCollector {
      onStreamFinished: {
        const val = this.text.trim();
        clockWidget.numLock = val === "1";
      }
    }
  }

  Timer {
    interval: 200; running: true; repeat: true
    onTriggered: {
      if (!clockWidget.numLockProc.running)
        clockWidget.numLockProc.running = true;
    }
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

  function powerAction(cmd) {
    var p = Qt.createQmlObject('import QtQuick; import Quickshell.Io; Process { command: ' + JSON.stringify(cmd) + ' }', clockWidget);
    p.running = true;
    clockWidget.showPowerMenu = false;
  }

  // --- App launcher state ---
  property bool showAppLauncher: false
  property bool appLauncherHovered: false
  property Timer appLauncherTimer: Timer {
    interval: 15000
    onTriggered: clockWidget.showAppLauncher = false
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
    if (showPowerMenu && powerMenuTimer) powerMenuTimer.restart();
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
      if (showPowerMenu) showPowerMenu = false;
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

  // --- Notification lifecycle ---
  onLatestNotificationDataChanged: {
    if (_ready && latestNotificationData) {
      if (showPowerMenu) showPowerMenu = false;
      if (showAppLauncher) showAppLauncher = false;
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
    interval: 6000
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

  // Size changes are the core of the Dynamic Island morph.
  // Regular expanded = 64×540; notification/power = 130×480; app launcher = 240×480; collapsed = 36×auto.
  height: showAppLauncher ? 240 : (latestNotificationData || showPowerMenu ? 130 : (isExpanded ? 64 : 36))
  width: latestNotificationData || showPowerMenu || showAppLauncher ? 480 : (isExpanded ? 540 : (mode !== "default" ? indicatorRow.implicitWidth + 86 : collapsedRow.implicitWidth + 86))
  radius: latestNotificationData || showPowerMenu || showAppLauncher ? 28 : (isExpanded ? 22 : 18)
  color: "#0a1411"

  // Elastic morph animation for regular expand/collapse
  Behavior on height { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }
  Behavior on width  { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }
  Behavior on radius { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }

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
  RowLayout {
    id: collapsedRow
    anchors.centerIn: parent
    spacing: clockWidget.isPlaying ? 6 : 0

    opacity: clockWidget.isExpanded || clockWidget.mode !== "default" ? 0.0 : 1.0
    visible: opacity > 0.0
    Behavior on opacity { NumberAnimation { duration: 200 } }

    Item {
      id: visualizerContainer
      Layout.alignment: Qt.AlignVCenter
      property real targetWidth: clockWidget.isPlaying ? 14 : 0
      Layout.preferredWidth: targetWidth
      Layout.preferredHeight: 12
      clip: true

      Behavior on targetWidth { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }

      Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        height: 12

        Rectangle { width: 2; height: Math.min(12, clockWidget.barHeights[0]); radius: 1; color: "#3ba889"; anchors.bottom: parent.bottom }
        Rectangle { width: 2; height: Math.min(12, clockWidget.barHeights[1]); radius: 1; color: "#3ba889"; anchors.bottom: parent.bottom }
        Rectangle { width: 2; height: Math.min(12, clockWidget.barHeights[2]); radius: 1; color: "#3ba889"; anchors.bottom: parent.bottom }
        Rectangle { width: 2; height: Math.min(12, clockWidget.barHeights[3]); radius: 1; color: "#3ba889"; anchors.bottom: parent.bottom }
      }
    }

    Text {
      text: Qt.formatDateTime(clock.date, "HH:mm")
      color: "#eae6dc"
      font { family: "Inter"; pixelSize: 14; weight: 500 }
    }
  }

  // --- Collapsed: volume / brightness indicator ---
  RowLayout {
    id: indicatorRow
    anchors.centerIn: parent
    spacing: 6

    opacity: !clockWidget.isExpanded && clockWidget.mode !== "default" ? 1.0 : 0.0
    visible: opacity > 0.0
    Behavior on opacity { NumberAnimation { duration: 200 } }

    // Volume mode
    RowLayout {
      spacing: 8
      visible: clockWidget.mode === "volume"

      Text {
        text: clockWidget.volumeIcon(clockWidget.volume, clockWidget.audioMuted)
        color: clockWidget.audioMuted ? "#556663" : "#3ba889"
        font { family: "JetBrainsMono Nerd Font"; pixelSize: 18 }
        Behavior on color { ColorAnimation { duration: 120 } }
      }

      Item {
        width: 80; height: 6
        Rectangle {
          anchors.fill: parent; radius: 3; color: "#33403c"
          Rectangle {
            anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
            width: parent.width * (clockWidget.audioMuted ? 0 : clockWidget.volume)
            radius: 3
            color: clockWidget.audioMuted ? "#33403c" : "#3ba889"
            Behavior on width { NumberAnimation { duration: 150; easing: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 120 } }
          }
        }
      }

      Text {
        text: Math.round((clockWidget.audioMuted ? 0 : clockWidget.volume) * 100) + "%"
        color: clockWidget.audioMuted ? "#556663" : "#eae6dc"
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
          anchors.fill: parent; radius: 3; color: "#33403c"
          Rectangle {
            anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
            width: parent.width * clockWidget.brightness
            radius: 3; color: "#e3b341"
            Behavior on width { NumberAnimation { duration: 200; easing: Easing.OutCubic } }
          }
        }
      }

      Text {
        text: Math.round(clockWidget.brightness * 100) + "%"
        color: "#eae6dc"
        font { family: "Inter"; pixelSize: 13; weight: 700 }
      }
    }

    // Caps Lock mode
    RowLayout {
      spacing: 8
      visible: clockWidget.mode === "capslock"

      Text {
        text: "󰜹"
        color: clockWidget.capsLock ? "#3ba889" : "#556663"
        font { family: "JetBrainsMono Nerd Font"; pixelSize: 18 }
        Behavior on color { ColorAnimation { duration: 120 } }
      }

      Text {
        text: clockWidget.capsLock ? "ON" : "OFF"
        color: clockWidget.capsLock ? "#eae6dc" : "#556663"
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
        color: clockWidget.numLock ? "#3ba889" : "#556663"
        font { family: "JetBrainsMono Nerd Font"; pixelSize: 18 }
        Behavior on color { ColorAnimation { duration: 120 } }
      }

      Text {
        text: clockWidget.numLock ? "ON" : "OFF"
        color: clockWidget.numLock ? "#eae6dc" : "#556663"
        font { family: "Inter"; pixelSize: 13; weight: 700 }
        Behavior on color { ColorAnimation { duration: 120 } }
      }
    }

  }

  // --- Expanded content (regular) ---
  // Visible when expanded with no notification: shows media player, clock, status capsule.
  Item {
    id: expandedContent
    anchors.fill: parent
    anchors.leftMargin: 16
    anchors.rightMargin: 16

    opacity: clockWidget.isExpanded && !clockWidget.showingNotification ? 1.0 : 0.0
    visible: opacity > 0.0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    MediaSection {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      trackTitle: clockWidget.trackTitle
      trackArtist: clockWidget.trackArtist ? clockWidget.trackArtist : "Unknown Artist"
      trackArt: clockWidget.trackArt
      isPlaying: clockWidget.isPlaying
      barHeights: clockWidget.barHeights
    }

    Item {
      id: centerSection
      anchors.centerIn: parent
      width: clockView.implicitWidth
      height: clockView.implicitHeight

      ColumnLayout {
        id: clockView
        anchors.centerIn: parent
        spacing: 1

        Text {
          text: Qt.formatDateTime(clock.date, "HH:mm")
          color: "#eae6dc"
          Layout.alignment: Qt.AlignHCenter
          font { family: "Inter"; pixelSize: 18; weight: 500 }
        }

        Text {
          text: Qt.formatDateTime(clock.date, "ddd, MMM d")
          color: "#eae6dc"
          opacity: 0.5
          Layout.alignment: Qt.AlignHCenter
          font { family: "Inter"; pixelSize: 11; weight: 400 }
        }
      }
    }

    StatusCapsule {
      id: statusCapsule
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      onClicked: clockWidget.toggleControlCenter()
    }
  }

  // --- Power menu overlay ---
  PowerMenu {
    id: powerMenuComponent
    anchors.fill: parent
    visible: clockWidget.showPowerMenu
    powerAction: clockWidget.powerAction
  }

  NotificationBanner {
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

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }
}
