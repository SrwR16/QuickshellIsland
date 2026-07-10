import "../overlay"
import "../widgets"
import "../services"
import "../theme"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: overlayRoot
    
    property bool anyActive: island.anyOverlayActive || island.showControlCenter || island.showAppLauncher
    property int islandHeight: island.height
    property alias island: island

    ActivityManager { id: activityManager }
    StatusService { id: statusSvc }
    NotificationService {
      id: notifService
      onNotificationReceived: function(data, notification) {
        activityManager.push("notification", data, activityManager.priorityTimeSensitive, 3500)
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
    WallpaperService { id: wallpaperSvc }
    AppLauncherService { id: appLauncherSvc }
    ModeService { id: modeSvc }
    AskpassService { id: askpassSvc }
    PrivacyService { id: privacySvc }
    VpnService { id: vpnSvc }
    HardwareMonitor { id: hwMonitor }

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
            activityManager.dismissByType("power");
            activityManager.dismissByType("battery");
            island.showWallpaperMenu = false;
            island.showControlCenter = false;
            island.showMovies = false;
            island.showPomodoro = false;
            island.showSys = false;
            island.showTray = false;
            island.showVpn = false;
            island.isPinned = false;
            island.showProductivity = false;
            island.showAppLauncher = false;
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

        wallpaperSvc: wallpaperSvc
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

    Process {
        id: ipcChecker
        running: true
        command: ["stdbuf", "-oL", "sh", "-c",
            "while true; do " +
            "  out=''; " +
            "  test -f /tmp/qs-power-menu && rm /tmp/qs-power-menu && out=\"${out}p\"; " +
            "  test -f /tmp/qs-app-launcher && rm /tmp/qs-app-launcher && out=\"${out}a\"; " +
            "  test -f /tmp/qs-wallpaper && rm /tmp/qs-wallpaper && out=\"${out}w\"; " +
            "  test -f /tmp/qs-mode-cycle && rm /tmp/qs-mode-cycle && out=\"${out}m\"; " +
            "  test -f /tmp/qs-toggle-cc && rm /tmp/qs-toggle-cc && out=\"${out}c\"; " +
            "  test -f /tmp/qs-productivity && rm /tmp/qs-productivity && out=\"${out}d\"; " +
            "  test -f /tmp/qs-pomodoro && rm /tmp/qs-pomodoro && out=\"${out}f\"; " +
            "  test -f /tmp/qs-movies && rm /tmp/qs-movies && out=\"${out}v\"; " +
            "  test -f /tmp/qs-sys && rm /tmp/qs-sys && out=\"${out}s\"; " +
            "  test -f /tmp/qs-tray && rm /tmp/qs-tray && out=\"${out}t\"; " +
            "  if [ -n \"$out\" ]; then echo \"$out\"; fi; " +
            "  inotifywait -qq -t 2 -e create,modify /tmp 2>/dev/null || sleep 0.2; " +
            "done"
        ]
        stdout: SplitParser {
            onRead: (data) => {
                var flags = data.trim()
                if (flags.indexOf("p") >= 0 && !island.showAppLauncher) island.openPowerMenu()
                if (flags.indexOf("a") >= 0 && !island.showPowerMenu && !activityManager.activeActivity) island.showAppLauncher = true
                if (flags.indexOf("w") >= 0) island.showWallpaperMenu = !island.showWallpaperMenu
                if (flags.indexOf("m") >= 0) {
                    modeSvc.cycleMode();
                    island.showModeIndicator();
                }
                if (flags.indexOf("c") >= 0) island.showControlCenter = !island.showControlCenter;
                if (flags.indexOf("d") >= 0) island.showProductivity = !island.showProductivity;
                if (flags.indexOf("f") >= 0) island.showPomodoro = !island.showPomodoro;
                if (flags.indexOf("v") >= 0) island.showMovies = !island.showMovies;
                if (flags.indexOf("s") >= 0) island.showSys = !island.showSys;
                if (flags.indexOf("t") >= 0) island.showTray = !island.showTray;
            }
        }
    }
}
