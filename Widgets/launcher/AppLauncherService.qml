import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
  id: appService

  property var appModel: []

  function launchApp(desktopId) {
    var p = Qt.createQmlObject('import QtQuick; import Quickshell.Io; Process { command: ["gtk-launch", ' + JSON.stringify(desktopId) + '] }', appService);
    p.running = true;
  }

  property Process scanProc: Process {
    id: scanProc
    command: ["sh", "-c", "XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}; FLATPAK_SYS=/var/lib/flatpak/exports/share; FLATPAK_USER=$HOME/.local/share/flatpak/exports/share; for d in /usr/share/applications \"$HOME/.local/share/applications\" \"$FLATPAK_SYS/applications\" \"$FLATPAK_USER/applications\"; do for f in \"$d\"/*.desktop; do [ -f \"$f\" ] || continue; name=$(grep -m1 '^Name=' \"$f\" 2>/dev/null | cut -d= -f2-); icon=$(grep -m1 '^Icon=' \"$f\" 2>/dev/null | cut -d= -f2-); nodisplay=$(grep -m1 '^NoDisplay=' \"$f\" 2>/dev/null | cut -d= -f2-); [ \"$nodisplay\" = \"true\" ] && continue; [ -z \"$name\" ] && continue; id=$(basename \"$f\" .desktop); unset iconpath; for idir in \"$XDG_DATA_HOME\" /usr/local/share /usr/share \"$FLATPAK_SYS\" \"$FLATPAK_USER\"; do for size in 512 256 128 96 64 48 32 24 16; do for ext in png svg svgz xpm jpg; do icc=\"$idir/icons/hicolor/${size}x${size}/apps/${icon}.${ext}\"; [ -f \"$icc\" ] && iconpath=\"$icc\" && break 3; done; done; done; for ext in png svg svgz xpm jpg; do for idir in \"$XDG_DATA_HOME\" /usr/local/share /usr/share \"$FLATPAK_SYS\" \"$FLATPAK_USER\"; do icc=\"$idir/icons/hicolor/scalable/apps/${icon}.${ext}\"; [ -f \"$icc\" ] && iconpath=\"$icc\" && break 2; done; done; for ext in png xpm svg; do [ -f \"/usr/share/pixmaps/${icon}.${ext}\" ] && iconpath=\"/usr/share/pixmaps/${icon}.${ext}\" && break; done; echo \"$name|${iconpath:-$icon}|$id\"; done; done | sort -f"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        var list = [];
        var lines = this.text.trim().split("\n");
        for (var i = 0; i < lines.length; i++) {
          var parts = lines[i].split("|");
          if (parts.length >= 3 && parts[0]) {
            list.push({ name: parts[0], icon: parts[1] || "", desktopId: parts[2] });
          }
        }
        appService.appModel = list;
      }
    }
  }
}
