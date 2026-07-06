#!/bin/bash
set -e

# Create directories
mkdir -p shell overlay widgets services animations theme

# Move core to theme
mv core/* theme/ 2>/dev/null || true
rm -rf core

# Move specific overlays
mv Widgets/clock/ClockWidget.qml overlay/DynamicIsland.qml
mv controlCenter/ControlCenter.qml overlay/ControlCenter.qml
mv Widgets/launcher/AppLauncher.qml overlay/Search.qml
mv Widgets/notifications/NotificationBanner.qml overlay/Notifications.qml

# Move services
find Widgets controlCenter -type f -name "*Service.qml" -exec mv {} services/ \;
find Widgets controlCenter -type f -name "StatusService.qml" -exec mv {} services/ \; 2>/dev/null || true

# Move all other QMLs (which are widgets/components) to widgets
find Widgets controlCenter -type f -name "*.qml" -exec mv {} widgets/ \;

# Move config files
find Widgets controlCenter -type f -name "*.conf" -exec mv {} widgets/ \;
find Widgets controlCenter -type f -name "*.json" -exec mv {} widgets/ \;

# Delete old directories
rm -rf Widgets controlCenter

# Now we need to fix imports across all QML files
# They used to import "../" or "../../" stuff. Now everything is in these 5 folders.
# To make it easy, we can just add these 4 imports to EVERY QML file:
# import "../overlay"
# import "../widgets"
# import "../services"
# import "../theme"
# (or absolute imports like import "quickshell/..." wait, QML supports relative imports, but from `shell.qml` it's "./overlay" etc.)

echo "Files moved successfully."
