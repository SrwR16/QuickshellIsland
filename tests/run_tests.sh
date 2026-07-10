#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0
FAILURES=""

pass() { PASS=$((PASS+1)); echo "  PASS: $1"; }
fail() { FAIL=$((FAIL+1)); FAILURES="$FAILURES\n  FAIL: $1"; echo "  FAIL: $1"; }

check() {
  local label="$1" cmd="$2"
  if eval "$cmd" 2>/dev/null; then pass "$label"; else fail "$label"; fi
}

check_not() {
  local label="$1" cmd="$2"
  if eval "$cmd" 2>/dev/null; then fail "$label"; else pass "$label"; fi
}

echo "=== QuickshellIsland Test Suite ==="
echo ""

# ── 1. File Existence ──────────────────────────────────────────
echo "--- File Existence ---"

check "ActivityManager.qml exists"  "test -f '$ROOT/services/ActivityManager.qml'"
check "DynamicIsland.qml exists"    "test -f '$ROOT/overlay/DynamicIsland.qml'"
check "Notifications.qml exists"    "test -f '$ROOT/overlay/Notifications.qml'"
check "PowerSection.qml exists"     "test -f '$ROOT/widgets/PowerSection.qml'"
check "StatusCapsule.qml exists"    "test -f '$ROOT/widgets/StatusCapsule.qml'"
check "MediaService.qml exists"     "test -f '$ROOT/services/MediaService.qml'"
check "HardwareMonitor.qml exists"  "test -f '$ROOT/services/HardwareMonitor.qml'"
check "OverlayRoot.qml exists"      "test -f '$ROOT/overlay/OverlayRoot.qml'"
check "NotificationService.qml exists" "test -f '$ROOT/services/NotificationService.qml'"
check "ControlCenter.qml exists"    "test -f '$ROOT/overlay/ControlCenter.qml'"
check "shell.qml exists"            "test -f '$ROOT/shell.qml'"

# ── 2. Removed API Regression Check ────────────────────────────
echo ""
echo "--- Removed API Regression ---"

# These symbols should NOT appear in the codebase anymore
for symbol in \
  'PriorityCritical' \
  'PriorityInteractive' \
  'PriorityTimeSensitive' \
  'PriorityPassive' \
  'notifUnpinTimer' \
  'showPowerMenuRequested' \
  'powerMenuTimer' \
  'batteryAlertTimer' \
  'sysStatus' \
  'onNotifDismissed' \
  'onNotifBannerDismissed' \
; do
  check_not "No reference to '$symbol'" "grep -qr '$symbol' '$ROOT' --include='*.qml' --exclude='Clock.qml'"
done

# ── 3. New API Availability ────────────────────────────────────
echo ""
echo "--- New API Availability ---"

# ActivityManager should define key properties/methods
check "ActivityManager has priorityCritical" \
  "grep -q 'priorityCritical' '$ROOT/services/ActivityManager.qml'"
check "ActivityManager has priorityInteractive" \
  "grep -q 'priorityInteractive' '$ROOT/services/ActivityManager.qml'"
check "ActivityManager has priorityTimeSensitive" \
  "grep -q 'priorityTimeSensitive' '$ROOT/services/ActivityManager.qml'"
check "ActivityManager has priorityPassive" \
  "grep -q 'priorityPassive' '$ROOT/services/ActivityManager.qml'"
check "ActivityManager has push()" \
  "grep -q 'function push(' '$ROOT/services/ActivityManager.qml'"
check "ActivityManager has dismiss()" \
  "grep -q 'function dismiss(' '$ROOT/services/ActivityManager.qml'"
check "ActivityManager has dismissByType()" \
  "grep -q 'function dismissByType(' '$ROOT/services/ActivityManager.qml'"
check "ActivityManager has dismissAll()" \
  "grep -q 'function dismissAll(' '$ROOT/services/ActivityManager.qml'"
check "ActivityManager has pauseAutoDismiss()" \
  "grep -q 'function pauseAutoDismiss(' '$ROOT/services/ActivityManager.qml'"
check "ActivityManager has resumeAutoDismiss()" \
  "grep -q 'function resumeAutoDismiss(' '$ROOT/services/ActivityManager.qml'"
check "ActivityManager has activityDismissed signal" \
  "grep -q 'signal activityDismissed' '$ROOT/services/ActivityManager.qml'"
check "ActivityManager has activeActivity property" \
  "grep -q 'property.*activeActivity' '$ROOT/services/ActivityManager.qml'"
check "ActivityManager has pendingCount property" \
  "grep -q 'property.*pendingCount' '$ROOT/services/ActivityManager.qml'"

# New states in DynamicIsland (use double quotes in file)
check "DynamicIsland has 'notification' state" \
  "grep -q 'name: \"notification\"' '$ROOT/overlay/DynamicIsland.qml'"
check "DynamicIsland has 'powerSection' state" \
  "grep -q 'name: \"powerSection\"' '$ROOT/overlay/DynamicIsland.qml'"
check "DynamicIsland has _queueState()" \
  "grep -q 'function _queueState' '$ROOT/overlay/DynamicIsland.qml'"
check "DynamicIsland has showPowerSection property" \
  "grep -q 'property bool showPowerSection' '$ROOT/overlay/DynamicIsland.qml'"
check "DynamicIsland has pushBatteryAlert()" \
  "grep -q 'function pushBatteryAlert' '$ROOT/overlay/DynamicIsland.qml'"
check "DynamicIsland has activityManager property" \
  "grep -q 'property QtObject activityManager' '$ROOT/overlay/DynamicIsland.qml'"
check "DynamicIsland has statusSvc property" \
  "grep -q 'property QtObject statusSvc' '$ROOT/overlay/DynamicIsland.qml'"
check "DynamicIsland has notifService property" \
  "grep -q 'property QtObject notifService' '$ROOT/overlay/DynamicIsland.qml'"

# ── 4. Key Fixes Verification ──────────────────────────────────
echo ""
echo "--- Fix Verification ---"

# Bug #1: exclusiveOpen no longer has inline showBatteryAlert assignment
check_not "exclusiveOpen no showBatteryAlert assignment" \
  "grep -q 'showBatteryAlert = ' '$ROOT/overlay/DynamicIsland.qml'"

# shell.qml: duplicate import removed
check_not "shell.qml has duplicate import" \
  "grep -c 'import.*theme' '$ROOT/shell.qml' | grep -q '^2$'"

# shell.qml: unused shortcut removed
check_not "shell.qml has Alt+F5 shortcut" \
  "grep -q 'Alt+F5' '$ROOT/shell.qml'"

# HardwareMonitor: poll rate reduced
check "HardwareMonitor poll rate is 300ms" \
  "grep -q 'sleep 0.3' '$ROOT/services/HardwareMonitor.qml'"
check_not "HardwareMonitor does not have 50ms poll" \
  "grep -q 'sleep 0.05' '$ROOT/services/HardwareMonitor.qml'"

# MediaService: redundant pollTimer removed
check_not "MediaService has no pollTimer" \
  "grep -q 'pollTimer' '$ROOT/services/MediaService.qml'"

# ControlCenter: pctlMetaTimer removed
check_not "ControlCenter has no pctlMetaTimer" \
  "grep -q 'pctlMetaTimer' '$ROOT/overlay/ControlCenter.qml'"

# ControlCenter: audio sync conditional on isOpen
check "ControlCenter audio sync runs only when open" \
  "grep -q 'running: controlCenter.isOpen' '$ROOT/overlay/ControlCenter.qml'"

# StatusCapsule uses shared statusSvc
check "StatusCapsule uses shared statusSvc" \
  "grep -q 'property QtObject statusSvc' '$ROOT/widgets/StatusCapsule.qml'"
check_not "StatusCapsule has no inline StatusService" \
  "grep -q 'StatusService {.*id: status' '$ROOT/widgets/StatusCapsule.qml'"

# WifiPage distinct signal icons
check "WifiPage has distinct signal icons" \
  "grep -q '󰤨.*󰤢.*󰤟' '$ROOT/widgets/WifiPage.qml'"

# PowerSection button size
check "PowerSection buttons are 56x56" \
  "grep -q 'width: 56; height: 56; radius: 16' '$ROOT/widgets/PowerSection.qml'"

# Notifications no longer has state transitions
check_not "Notifications has no PropertyChanges" \
  "grep -q 'PropertyChanges' '$ROOT/overlay/Notifications.qml'"
check_not "Notifications has no state transitions" \
  "grep -q 'transitions:' '$ROOT/overlay/Notifications.qml'"
check_not "Notifications has no Behavior on dragOffset" \
  "grep -q 'Behavior on dragOffset' '$ROOT/overlay/Notifications.qml'"

# OverlayRoot wires ActivityManager
check "OverlayRoot instantiates ActivityManager" \
  "grep -q 'ActivityManager {.*id: activityManager' '$ROOT/overlay/OverlayRoot.qml'"
check "OverlayRoot wires notificationReceived" \
  "grep -q 'onNotificationReceived' '$ROOT/overlay/OverlayRoot.qml'"
check "OverlayRoot wires activityDismissed" \
  "grep -q 'onActivityDismissed' '$ROOT/overlay/OverlayRoot.qml'"

# NotificationService emits signal
check "NotificationService has notificationReceived signal" \
  "grep -q 'signal notificationReceived' '$ROOT/services/NotificationService.qml'"

# PrivacyService uses Corked: no for mic detection
check "PrivacyService uses Corked: no for mic detection" \
  "grep -q 'Corked: no' '$ROOT/services/PrivacyService.qml'"

# Battery alert debounce: extends existing alert instead of pushing duplicate
check "Battery alert extends existing timer" \
  "grep -q 'cur.dismissAt = Date.now' '$ROOT/overlay/DynamicIsland.qml'"

# Initial battery/charging check after _ready
check_not "DynamicIsland does not push battery alert on _ready" \
  "grep -q 'statusSvc.charging.*pushBatteryAlert.*charging' '$ROOT/overlay/DynamicIsland.qml'"

# Case-insensitive battery status comparison (upower uses lowercase)
check "StatusService uses case-insensitive charging check" \
  "grep -q 'toLowerCase' '$ROOT/services/StatusService.qml'"
check "StatusService powerState uses case-insensitive check" \
  "grep -q 'powerStatus.toLowerCase' '$ROOT/services/StatusService.qml'"

# ── 5. Config Load Test (quickshell) ──────────────────────────
echo ""
echo "--- Config Load Test ---"

QS_OUTPUT=$(timeout 8 quickshell --path "$ROOT/shell.qml" 2>&1 || true)

if echo "$QS_OUTPUT" | grep -q "Configuration Loaded"; then
  pass "quickshell loads config successfully"
else
  fail "quickshell fails to load config"
fi

ERRORS=$(echo "$QS_OUTPUT" | grep 'ERROR' || true)
if [ -z "$ERRORS" ]; then
  pass "No ERROR messages during config load"
else
  echo "    Errors detected:"
  echo "$ERRORS" | sed 's/^/    /'
  fail "ERROR messages during config load"
fi

# ── Summary ────────────────────────────────────────────────────
echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -ne 0 ]; then
  echo -e "Failures:$FAILURES"
  exit 1
fi
exit 0
