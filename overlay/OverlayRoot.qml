import "../overlay"
import "../widgets"
import "../services"
import "../theme"
import "../Overview/services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: overlayRoot
    
    property bool showMovieWidget: false
    property bool showWallpaperPicker: false
    property bool anyActive: island.anyOverlayActive || island.showControlCenter || island.showAppLauncher || island.showPowerSection || showMovieWidget || showWallpaperPicker
    property int islandHeight: island.height
    property alias island: island

    ActivityManager { id: activityManager }
    StatusService { id: statusSvc }
    NotificationService {
      id: notifService
      onNotificationReceived: function(data, notification) {
        activityManager.push("notification", data, activityManager.priorityPassive, 3500)
      }
    }
    Connections {
      target: activityManager
      function onActivityDismissed(activity) {
        if (activity.type === "notification" && activity.data) {
          notifService.dismissBanner(activity.data)
        }
      }
    }
    AppLauncherService { id: appLauncherSvc }
    ModeService { id: modeSvc }
    AskpassService { id: askpassSvc }
    PrivacyService { id: privacySvc }
    VpnService { id: vpnSvc }
    HardwareMonitor { id: hwMonitor }
    WallpaperService { id: wallpaperSvc }

    // Transparent background interceptor for closing menus when clicking outside
    MouseArea {
        anchors.fill: parent
        enabled: overlayRoot.anyActive
        
        Rectangle {
            anchors.fill: parent
            color: "#01000000"
            visible: parent.enabled
        }
        
        onClicked: {
            island.showPowerSection = false;
            activityManager.dismissByType("power");
            activityManager.dismissByType("battery");
            island.showControlCenter = false;
            island.showPomodoro = false;
            island.showSys = false;
            island.showTray = false;
            island.showVpn = false;
            island.isPinned = false;
            island.showProductivity = false;
            island.showAppLauncher = false;
            overlayRoot.showWallpaperPicker = false;
        }
    }

    DynamicIsland {
        id: island
        z: 10
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 10

        activityManager: activityManager
        notifService: notifService
        statusSvc: statusSvc

        modeSvc: modeSvc
        askpassSvc: askpassSvc
        privacySvc: privacySvc
        vpnSvc: vpnSvc
        hwMonitor: hwMonitor
    }

    // Embed Search (formerly AppLauncher) directly in the same scene graph
    Item {
        z: 20
        width: 480; height: 240
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 10
        visible: island.showAppLauncher
        opacity: island.showAppLauncher ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Search {
            id: searchOverlay
            anchors.fill: parent
            radius: 28
            appService: appLauncherSvc
            onCloseRequested: island.showAppLauncher = false
            onHoveredChanged: island.appLauncherHovered = hovered
        }
    }

    // Wallpaper picker overlay
    Item {
        z: 30
        anchors.fill: parent
        visible: overlayRoot.showWallpaperPicker
        opacity: overlayRoot.showWallpaperPicker ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuart } }

        Rectangle {
            anchors.fill: parent
            color: Theme.background
            opacity: 0.55
        }

        MouseArea {
            anchors.fill: parent
            onClicked: overlayRoot.showWallpaperPicker = false
        }

        Rectangle {
            id: wpPanel
            readonly property real maxWidth: Math.min(parent.width * 0.85, 760)
            readonly property real maxHeight: Math.min(parent.height * 0.8, 540)
            width: maxWidth
            height: maxHeight
            radius: 20
            color: Theme.surface
            border.width: 1
            border.color: Theme.border
            anchors.centerIn: parent

            Keys.onEscapePressed: overlayRoot.showWallpaperPicker = false

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text { text: "󰸉"; color: Theme.tertiary; font { family: "JetBrainsMono Nerd Font"; pixelSize: 18 } }
                    Text { text: "Wallpapers"; color: Theme.text; font { family: "Inter"; pixelSize: 16; weight: Font.Bold }; Layout.fillWidth: true }
                    Text {
                        text: "✕"; color: Theme.text; opacity: 0.5; font.pixelSize: 14
                        MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: overlayRoot.showWallpaperPicker = false }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true; radius: 12; color: Theme.surfaceDim; clip: true
                    WallpaperGrid {
                        anchors.fill: parent; anchors.margins: 10
                        wallpaperModel: wallpaperSvc.wallpapers
                        wallService: wallpaperSvc
                        onWallpaperChosen: overlayRoot.showWallpaperPicker = false
                    }
                }
            }
        }
    }

    // Movie finder overlay
    Item {
        z: 30
        anchors.fill: parent
        visible: overlayRoot.showMovieWidget
        opacity: overlayRoot.showMovieWidget ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuart } }

        MovieWidget {
            anchors.fill: parent
            Keys.onEscapePressed: overlayRoot.showMovieWidget = false
            onCloseRequested: overlayRoot.showMovieWidget = false
        }
    }

    Process {
        id: ipcChecker
        running: true
        command: ["stdbuf", "-oL", "sh", "-c",
            "while true; do " +
            "  out=''; " +
            "  test -f /tmp/qs-power-menu && rm /tmp/qs-power-menu && out=\"${out}p\"; " +
            "  test -f /tmp/qs-app-launcher && rm /tmp/qs-app-launcher && out=\"${out}a\"; " +
            "  test -f /tmp/qs-mode-cycle && rm /tmp/qs-mode-cycle && out=\"${out}m\"; " +
            "  test -f /tmp/qs-toggle-cc && rm /tmp/qs-toggle-cc && out=\"${out}c\"; " +
            "  test -f /tmp/qs-productivity && rm /tmp/qs-productivity && out=\"${out}d\"; " +
            "  test -f /tmp/qs-pomodoro && rm /tmp/qs-pomodoro && out=\"${out}f\"; " +
            "  test -f /tmp/qs-sys && rm /tmp/qs-sys && out=\"${out}s\"; " +
            "  test -f /tmp/qs-tray && rm /tmp/qs-tray && out=\"${out}t\"; " +
            "  test -f /tmp/qs-overview && rm /tmp/qs-overview && out=\"${out}o\"; " +
            "  test -f /tmp/qs-wallpaper && rm /tmp/qs-wallpaper && out=\"${out}w\"; " +
            "  test -f /tmp/qs-movie && rm /tmp/qs-movie && out=\"${out}v\"; " +
            "  if [ -n \"$out\" ]; then echo \"$out\"; fi; " +
            "  inotifywait -qq -t 2 -e create,modify /tmp 2>/dev/null || sleep 0.2; " +
            "done"
        ]
        stdout: SplitParser {
            onRead: (data) => {
                var flags = data.trim()
                if (flags.indexOf("p") >= 0 && !island.showAppLauncher) island.showPowerSection = !island.showPowerSection
                if (flags.indexOf("a") >= 0 && !island.showPowerSection && !activityManager.activeActivity) island.showAppLauncher = true
                if (flags.indexOf("m") >= 0) {
                    modeSvc.cycleMode();
                    island.showModeIndicator();
                }
                if (flags.indexOf("c") >= 0) island.showControlCenter = !island.showControlCenter;
                if (flags.indexOf("d") >= 0) island.showProductivity = !island.showProductivity;
                if (flags.indexOf("f") >= 0) island.showPomodoro = !island.showPomodoro;
                if (flags.indexOf("s") >= 0) island.showSys = !island.showSys;
                if (flags.indexOf("t") >= 0) island.showTray = !island.showTray;
                if (flags.indexOf("o") >= 0) GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
                if (flags.indexOf("w") >= 0) { wallpaperSvc.rescan(); overlayRoot.showWallpaperPicker = !overlayRoot.showWallpaperPicker }
                if (flags.indexOf("v") >= 0) overlayRoot.showMovieWidget = !overlayRoot.showMovieWidget;
            }
        }
    }
}
