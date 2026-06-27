import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications

import Quickshell.Bluetooth
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Widgets/notifications"

PanelWindow {
    id: controlCenter
    property bool isOpen: false
    visible: isOpen

    property string page: "main"
    onIsOpenChanged: if (isOpen) page = "main"

    WlrLayershell.layer: WlrLayer.Overlay

    signal closeRequested()
    signal dismissNotif(var notifRef)
    signal clearNotifs()
    signal dndToggled(bool val)
    property bool doNotDisturb: false
    property var storedNotifications: []



    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    color: "transparent"

    // --- Audio (Pipewire) ---
    readonly property PwNode audioSink: Pipewire.defaultAudioSink
    readonly property PwNode audioSource: Pipewire.defaultAudioSource
    readonly property bool audioMuted: !!audioSink?.audio?.muted
    readonly property bool audioSourceMuted: !!audioSource?.audio?.muted
    readonly property real audioVolume: Math.min(1, Math.max(0, audioSink?.audio?.volume ?? 0))
    readonly property real audioSourceVolume: Math.min(1, Math.max(0, audioSource?.audio?.volume ?? 0))

    readonly property var audioSinks: {
        var list = [];
        var nodes = Pipewire.nodes;
        if (nodes) {
            for (var i = 0; i < nodes.length; i++) {
                var n = nodes[i];
                if (n && n.ready && n.isSink && !n.isStream) list.push(n);
            }
        }
        list.sort(function(a, b) { return (a.description || a.name || "").localeCompare(b.description || b.name || ""); });
        return list;
    }

    readonly property var audioSources: {
        var list = [];
        var nodes = Pipewire.nodes;
        if (nodes) {
            for (var i = 0; i < nodes.length; i++) {
                var n = nodes[i];
                if (n && n.ready && !n.isSink && !n.isStream) list.push(n);
            }
        }
        list.sort(function(a, b) { return (a.description || a.name || "").localeCompare(b.description || b.name || ""); });
        return list;
    }

    function setAudioSourceVolume(vol) {
        if (audioSource?.ready && audioSource?.audio) {
            audioSource.audio.muted = false;
            audioSource.audio.volume = Math.max(0, Math.min(1, vol));
        }
    }

    function toggleAudioSourceMute() {
        if (audioSource?.ready && audioSource?.audio) {
            audioSource.audio.muted = !audioSource.audio.muted;
        }
    }

    function setDefaultSink(node) {
        if (node) Pipewire.preferredDefaultAudioSink = node;
    }

    function setDefaultSource(node) {
        if (node) Pipewire.preferredDefaultAudioSource = node;
    }

    PwObjectTracker {
        objects: controlCenter.audioSink ? [controlCenter.audioSink] : []
    }

    function setVolume(vol) {
        if (audioSink?.ready && audioSink?.audio) {
            audioSink.audio.muted = false;
            audioSink.audio.volume = Math.max(0, Math.min(1, vol));
        }
    }

    function toggleMute() {
        if (audioSink?.ready && audioSink?.audio) {
            audioSink.audio.muted = !audioSink.audio.muted;
        }
    }

    function volumeIcon(vol, muted) {
        if (muted || vol <= 0) return "󰝟";
        if (vol < 0.34) return "󰕿";
        if (vol < 0.67) return "󰖀";
        return "󰕾";
    }

    // --- Wi-Fi ---
    property bool wifiEnabled: true
    property string wifiName: "Disconnected"
    property string wifiSecurity: ""
    property var wifiNetworks: []
    property bool wifiScanning: false

    Process {
        id: wifiStatusProc
        command: ["sh", "-c", "e=$(nmcli -t -f WIFI g 2>/dev/null); s=$(nmcli -t -f TYPE,NAME con show --active 2>/dev/null | grep '^802-11-wireless:' | cut -d: -f2); sec=$(nmcli -t -f IN-USE,SECURITY dev wifi 2>/dev/null | grep '^*' | cut -d: -f2); echo \"$e|${s:-}|${sec:-}\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = this.text;
                const parts = out.split("|");
                if (parts.length > 0) controlCenter.wifiEnabled = parts[0].trim() === "enabled";
                const ssid = parts.length > 1 ? parts[1].trim() : "";
                const sec = parts.length > 2 ? parts[2].trim() : "";
                if (ssid) {
                    controlCenter.wifiName = ssid;
                    controlCenter.wifiSecurity = sec;
                } else if (controlCenter.wifiEnabled) {
                    controlCenter.wifiName = "No network";
                    controlCenter.wifiSecurity = "";
                } else {
                    controlCenter.wifiName = "Off";
                    controlCenter.wifiSecurity = "";
                }
            }
        }
    }

    function refreshWifi() { wifiStatusProc.running = true; }

    function toggleWifi() {
        var turningOff = wifiEnabled;
        wifiToggleProc.command = ["nmcli", "radio", "wifi", turningOff ? "off" : "on"];
        wifiToggleProc.running = true;
        wifiEnabled = !wifiEnabled;
        if (turningOff) { wifiName = "Off"; wifiSecurity = ""; }
        wifiRefreshDelay.start();
    }

    Process { id: wifiToggleProc }
    Timer { id: wifiRefreshDelay; interval: 800; onTriggered: refreshWifi() }

    Process {
        id: wifiScanProc
        command: ["sh", "-c", "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list --rescan yes 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n").filter(l => l.trim().length > 0);
                const seen = {};
                const list = [];
                for (const line of lines) {
                    const fields = line.split(":");
                    if (fields.length < 4) continue;
                    const inUse = fields[0] === "*";
                    const ssid = fields[1];
                    const signal = parseInt(fields[2]) || 0;
                    const security = fields[3];
                    if (!ssid || seen[ssid]) continue;
                    seen[ssid] = true;
                    list.push({ ssid: ssid, signal: signal, security: security, active: inUse });
                }
                list.sort((a, b) => b.signal - a.signal);
                controlCenter.wifiNetworks = list;
                controlCenter.wifiScanning = false;
            }
        }
    }

    function scanWifi() {
        wifiScanning = true;
        wifiScanProc.running = true;
    }

    Timer {
        interval: 8000
        running: controlCenter.isOpen && controlCenter.page === "wifi"
        repeat: true
        triggeredOnStart: true
        onTriggered: controlCenter.scanWifi()
    }

    property string wifiPendingSsid: ""
    property bool wifiNeedsPassword: false
    property string wifiConnectError: ""
    property bool wifiConnecting: false

    function connectToWifi(ssid, security, password) {
        wifiConnecting = true;
        wifiConnectError = "";
        const args = password
            ? ["nmcli", "dev", "wifi", "connect", ssid, "password", password]
            : ["nmcli", "connection", "up", "id", ssid];
        wifiConnectProc.command = args;
        wifiConnectProc.running = true;
    }

    Process {
        id: wifiConnectProc
        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: {
                controlCenter.wifiConnecting = false;
                if (this.text && this.text.toLowerCase().includes("error")) {
                    controlCenter.wifiConnectError = "Couldn't connect — check the password and try again.";
                } else {
                    controlCenter.wifiConnectError = "";
                    controlCenter.wifiPendingSsid = "";
                    controlCenter.refreshWifi();
                    controlCenter.scanWifi();
                }
            }
        }
    }

    function disconnectWifi() {
        wifiDisconnectProc.command = ["sh", "-c", "nmcli -t -f device,type connection show --active | grep wifi | cut -d: -f1 | xargs -r -I{} nmcli con down {}"];
        wifiDisconnectProc.running = true;
        refreshWifiDelay.start();
    }

    Process { id: wifiDisconnectProc }
    Timer { id: refreshWifiDelay; interval: 600; onTriggered: { controlCenter.refreshWifi(); controlCenter.scanWifi(); } }

    function forgetWifi(ssid) {
        forgetProc.command = ["nmcli", "connection", "delete", "id", ssid];
        forgetProc.running = true;
        refreshWifiDelay.start();
    }
    Process { id: forgetProc }

    property string wifiCurrentPassword: ""
    property bool wifiPasswordRevealed: false
    property string wifiQrPath: ""

    Process {
        id: wifiPasswordProc
        stdout: StdioCollector {
            onStreamFinished: { controlCenter.wifiCurrentPassword = this.text.trim(); }
        }
    }

    function loadCurrentWifiPassword() {
        if (!wifiName || wifiName === "No network" || wifiName === "Off") return;
        wifiPasswordProc.command = ["sh", "-c", `nmcli -s -g 802-11-wireless-security.psk connection show '${wifiName.replace(/'/g, "'\\''")}' 2>/dev/null`];
        wifiPasswordProc.running = true;
    }

    Process {
        id: wifiQrProc
        command: ["sh", "-c", "true"]
    }

    function generateWifiQr() {
        if (!wifiCurrentPassword) { wifiQrPath = ""; return; }
        const security = wifiSecurity && wifiSecurity !== "--" ? "WPA" : "nopass";
        const payload = `WIFI:T:${security};S:${wifiName};P:${wifiCurrentPassword};;`;
        const escaped = payload.replace(/'/g, "'\\''");
        const path = Quickshell.cachePath("wifi-qr.png");
        wifiQrProc.command = ["sh", "-c", `qrencode -t PNG -s 6 -o '${path}' '${escaped}'`];
        wifiQrProc.running = true;
        wifiQrPath = "";
        wifiQrReadyDelay.start();
        wifiQrProc.exited.connect(() => { controlCenter.wifiQrPath = "file://" + path; });
    }

    Timer { id: wifiQrReadyDelay; interval: 50 }

    // --- Bluetooth ---
    readonly property BluetoothAdapter btAdapter: Bluetooth.defaultAdapter
    readonly property var btDevices: btAdapter ? btAdapter.devices.values : []

    function toggleBluetooth() {
        if (btAdapter) btAdapter.enabled = !btAdapter.enabled;
    }

    property bool btScanning: false
    onBtAdapterChanged: { if (!btAdapter) { btScanning = false; } }
    Connections {
        target: controlCenter.btAdapter
        enabled: !!controlCenter.btAdapter
        function onDiscoveringChanged() {
            if (controlCenter.btAdapter && !controlCenter.btAdapter.discovering)
                controlCenter.btScanning = false;
        }
        function onEnabledChanged() {
            if (controlCenter.btAdapter && !controlCenter.btAdapter.enabled)
                controlCenter.btScanning = false;
        }
    }

    function btDeviceSubtitle(dev) {
        if (dev.state === BluetoothDeviceState.Connected) return "Connected";
        if (dev.state === BluetoothDeviceState.Connecting) return "Connecting…";
        if (dev.pairing) return "Pairing…";
        if (dev.paired) return "Paired";
        return "Available";
    }

    function toggleBtConnection(dev) {
        if (dev.state === BluetoothDeviceState.Connected) {
            dev.disconnect();
        } else {
            dev.connect();
        }
    }

    function toggleBtScan() {
        if (!btAdapter) return;
        btScanning = !btScanning;
        btAdapter.discovering = btScanning;
    }

    function pairDevice(dev) {
        dev.pair();
    }

    function forgetDevice(dev) {
        if (dev.state === BluetoothDeviceState.Connected)
            dev.disconnect();
        dev.forget();
    }

    // --- Night Light ---
    property bool nightLightEnabled: false

    function toggleNightLight() {
        nightLightEnabled = !nightLightEnabled;
        nightLightProc.command = ["sh", "-c", nightLightEnabled
            ? "pkill -x gammastep; gammastep -O 4500 &"
            : "pkill -x gammastep"];
        nightLightProc.running = true;
    }

    Process { id: nightLightProc }

    // --- Brightness ---
    property real brightness: 0.8
    property string backlightDevice: ""

    Process {
        id: backlightDetectProc
        command: ["sh", "-c", "ls /sys/class/backlight 2>/dev/null | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const name = this.text.trim();
                if (name) controlCenter.backlightDevice = name;
            }
        }
    }

    FileView {
        id: brightnessCurrentFile
        path: controlCenter.backlightDevice
            ? `/sys/class/backlight/${controlCenter.backlightDevice}/brightness`
            : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: controlCenter.syncBrightnessFromSysfs()
        onTextChanged: controlCenter.syncBrightnessFromSysfs()
    }

    FileView {
        id: brightnessMaxFile
        path: controlCenter.backlightDevice
            ? `/sys/class/backlight/${controlCenter.backlightDevice}/max_brightness`
            : ""
    }

    function syncBrightnessFromSysfs() {
        const cur = parseInt(brightnessCurrentFile.text());
        const max = parseInt(brightnessMaxFile.text());
        if (!isNaN(cur) && !isNaN(max) && max > 0) {
            brightness = cur / max;
        }
    }

    function setBrightness(val) {
        brightness = Math.max(0, Math.min(1, val));
        brightnessSetProc.command = ["brightnessctl", "set", Math.round(brightness * 100) + "%"];
        brightnessSetProc.running = true;
    }

    Process { id: brightnessSetProc }

    function brightnessIcon(val) {
        if (val < 0.34) return "󰃞";
        if (val < 0.67) return "󰃟";
        return "󰃠";
    }

    // --- MPRIS media player ---
    property MprisPlayer lastActivePlayer: null

    readonly property MprisPlayer activePlayer: {
        const list = Mpris.players.values;
        if (list.length === 0) return null;
        for (const p of list) {
            if (p.playbackState === MprisPlaybackState.Playing) return p;
        }
        for (const p of list) {
            if (p.trackTitle) return p;
        }
        return list[0];
    }

    onActivePlayerChanged: {
        if (activePlayer) lastActivePlayer = activePlayer;
    }

    function artFromUrl(url) {
        if (!url) return "";
        var match = url.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})/);
        return match ? "https://img.youtube.com/vi/" + match[1] + "/hqdefault.jpg" : "";
    }

    readonly property string playerArt: {
        var p = controlCenter.activePlayer;
        if (!p) return "";
        if (p.trackArtUrl) return p.trackArtUrl;
        var url = p.metadata && p.metadata["xesam:url"] || "";
        return artFromUrl(url);
    }

    Component.onCompleted: {
        refreshWifi();
        backlightDetectProc.running = true;
    }

    // ---- Inline components ----
    component ToggleTile: Rectangle {
        id: tile
        property string iconText: ""
        property string label: ""
        property string sublabel: ""
        property bool active: false
        property bool expandable: false
        signal tapped()
        signal expandTapped()

        Layout.fillWidth: true
        Layout.preferredHeight: 56
        radius: 16
        color: active ? "#3ba889" : "#1a2421"

        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Rectangle {
                width: 32; height: 32; radius: 16
                color: tile.active ? "#2f8f76" : "#0a1411"

                Text {
                    anchors.centerIn: parent
                    text: tile.iconText
                    color: tile.active ? "#eae6dc" : "#3ba889"
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 14 }
                }
            }
            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                Text {
                    text: tile.label
                    color: tile.active ? "#000" : "#eae6dc"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    font { family: "Inter"; pixelSize: 13; weight: 700 }
                }
                Text {
                    text: tile.sublabel
                    color: tile.active ? "#000" : "#eae6dc"
                    opacity: 0.7
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    font { family: "Inter"; pixelSize: 10 }
                }
            }
            Text {
                visible: tile.expandable
                text: "󰅂"
                color: tile.active ? "#000" : "#eae6dc"
                opacity: 0.6
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 14 }
            }
        }

        MouseArea {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: tile.expandable ? parent.width * 0.72 : parent.width
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: tile.tapped()
        }

        MouseArea {
            visible: tile.expandable
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * 0.28
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: tile.expandTapped()
        }
    }

    component IconSlider: Item {
        id: slider
        property string iconText: ""
        property real value: 0
        signal moved(real val)

        Layout.fillWidth: true
        height: 40

        Rectangle {
            id: track
            anchors.fill: parent
            radius: 20
            color: "#1a2421"

            Rectangle {
                width: Math.max(40, parent.width * slider.value)
                height: parent.height
                radius: 20
                color: "#3ba889"
                Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: 100 } }
            }

            RowLayout {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 14
                spacing: 0
                Text {
                    text: slider.iconText
                    color: "#000"
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 15 }
                }
            }

            MouseArea {
                id: drag
                anchors.fill: parent
                onPressed: mouse => slider.moved(mouse.x / width)
                onPositionChanged: mouse => { if (pressed) slider.moved(mouse.x / width) }
            }
        }
    }

    component PageHeader: RowLayout {
        property string title: ""
        signal backTapped()

        Layout.fillWidth: true
        spacing: 8

        Text {
            text: "󰅁"
            color: "#eae6dc"
            font { family: "JetBrainsMono Nerd Font"; pixelSize: 18 }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -8
                cursorShape: Qt.PointingHandCursor
                onClicked: parent.parent.backTapped()
            }
        }
        Text {
            text: parent.title
            color: "#eae6dc"
            font { family: "Inter"; pixelSize: 15; weight: 700 }
            Layout.fillWidth: true
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (controlCenter.page !== "main") controlCenter.page = "main";
            else controlCenter.closeRequested();
        }
    }

    // ---- Panel ----
    Rectangle {
        id: panel
        width: 480
        height: Math.min(controlCenter.page === "main" ? mainPageHeightHint : 620, parent.height - 20)

        property real mainPageHeightHint: 310
            + (controlCenter.activePlayer ? 160 : 0)
            + 30
            + 50
            + 30
            + 80
            + 60

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 10

        color: "#0a1411"
        radius: 24
        border.color: "#1a2421"
        border.width: 2
        clip: true

        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            // ---- HEADER ----
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "󰅁"
                    color: "#eae6dc"
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 18 }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (controlCenter.page !== "main") controlCenter.page = "main";
                            else controlCenter.closeRequested();
                        }
                    }
                }

                Text {
                    text: controlCenter.page === "wifi" ? "Wi-Fi"
                        : controlCenter.page === "bluetooth" ? "Bluetooth"
                        : controlCenter.page === "audio" ? "Audio"
                        : "Control Center"
                    color: "#eae6dc"
                    font { family: "Inter"; pixelSize: 15; weight: 700 }
                    Layout.fillWidth: true
                }
            }

            // ---- MAIN PAGE ----
            ColumnLayout {
                visible: controlCenter.page === "main"
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        ToggleTile {
                            iconText: controlCenter.wifiEnabled ? "" : "󰖪"
                            label: "Wi-Fi"
                            sublabel: controlCenter.wifiEnabled ? controlCenter.wifiName : "Off"
                            active: controlCenter.wifiEnabled
                            expandable: true
                            onTapped: controlCenter.toggleWifi()
                            onExpandTapped: {
                                controlCenter.page = "wifi";
                                controlCenter.scanWifi();
                                controlCenter.loadCurrentWifiPassword();
                            }
                        }

                        ToggleTile {
                            iconText: controlCenter.volumeIcon(controlCenter.audioVolume, controlCenter.audioMuted)
                            label: "Audio"
                            sublabel: controlCenter.audioMuted ? "Muted" : (controlCenter.audioSink?.description || controlCenter.audioSink?.name || "Speaker")
                            active: !controlCenter.audioMuted
                            expandable: true
                            onTapped: controlCenter.toggleMute()
                            onExpandTapped: controlCenter.page = "audio"
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        ToggleTile {
                            iconText: "󰂯"
                            label: "Bluetooth"
                            sublabel: controlCenter.btAdapter?.enabled ? "On" : "Off"
                            active: !!controlCenter.btAdapter?.enabled
                            expandable: true
                            onTapped: controlCenter.toggleBluetooth()
                            onExpandTapped: controlCenter.page = "bluetooth"
                        }

                        ToggleTile {
                            iconText: "󰂚"
                            label: "Night Light"
                            sublabel: controlCenter.nightLightEnabled ? "On" : "Off"
                            active: controlCenter.nightLightEnabled
                            onTapped: controlCenter.toggleNightLight()
                        }

                        ToggleTile {
                            iconText: ""
                            label: "Peace"
                            sublabel: controlCenter.doNotDisturb ? "On" : "Off"
                            active: controlCenter.doNotDisturb
                            onTapped: {
                                controlCenter.doNotDisturb = !controlCenter.doNotDisturb;
                                controlCenter.dndToggled(controlCenter.doNotDisturb);
                            }
                        }
                    }

                    IconSlider {
                        iconText: controlCenter.volumeIcon(controlCenter.audioVolume, controlCenter.audioMuted)
                        value: controlCenter.audioMuted ? 0 : controlCenter.audioVolume
                        onMoved: val => controlCenter.setVolume(val)
                    }

                    IconSlider {
                        iconText: controlCenter.brightnessIcon(controlCenter.brightness)
                        value: controlCenter.brightness
                        onMoved: val => controlCenter.setBrightness(val)
                    }

                    // ---- Media Player Card ----
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 160
                        radius: 18
                        clip: true
                        visible: controlCenter.activePlayer !== null
                        color: "#1a1f1d"

                        Image {
                            anchors.fill: parent
                            source: controlCenter.playerArt || ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: controlCenter.playerArt.length > 0 && status === Image.Ready
                            opacity: 0.35
                        }
                        Rectangle {
                            anchors.fill: parent
                            color: "#000"
                            opacity: 0.3
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 14

                            Rectangle {
                                width: 64
                                height: 64
                                radius: 14
                                color: "#14221d"
                                clip: true

                                Image {
                                    id: artThumb
                                    anchors.fill: parent
                                    source: controlCenter.playerArt || ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true

                                    Rectangle {
                                        anchors.fill: parent
                                        color: "#14221d"
                                        visible: parent.status !== Image.Ready

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰎆"
                                            color: "#3ba889"
                                            font { family: "JetBrainsMono Nerd Font"; pixelSize: 24 }
                                        }
                                    }
                                }


                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 6

                                Text {
                                    text: controlCenter.activePlayer?.identity || "Media Player"
                                    color: "#eae6dc"
                                    opacity: 0.6
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    font { family: "Inter"; pixelSize: 10 }
                                }

                                Text {
                                    text: controlCenter.activePlayer?.trackTitle || "Nothing playing"
                                    color: "#fff"
                                    font { family: "Inter"; pixelSize: 15; weight: 700 }
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: controlCenter.activePlayer?.trackArtist || ""
                                    color: "#eae6dc"
                                    opacity: 0.7
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    font { family: "Inter"; pixelSize: 12 }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Layout.topMargin: 2

                                    Text {
                                        text: "󰒮"
                                        color: "#889994"
                                        font { family: "JetBrainsMono Nerd Font"; pixelSize: 12 }
                                        MouseArea {
                                            anchors.fill: parent
                                            anchors.margins: -6
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: controlCenter.activePlayer?.previous()
                                        }
                                    }

                                    Rectangle {
                                        id: playBtn
                                        width: 30
                                        height: 30
                                        radius: 15
                                        color: "#eae6dc"

                                        Text {
                                            anchors.centerIn: parent
                                            text: controlCenter.activePlayer?.isPlaying ? "" : ""
                                            color: "#1a1f1d"
                                            font { family: "JetBrainsMono Nerd Font"; pixelSize: 12 }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            hoverEnabled: true
                                            onEntered: playBtn.color = "#fff"
                                            onExited: playBtn.color = "#eae6dc"
                                            onClicked: controlCenter.activePlayer?.togglePlaying()
                                        }
                                    }

                                    Text {
                                        text: "󰒭"
                                        color: "#889994"
                                        font { family: "JetBrainsMono Nerd Font"; pixelSize: 12 }
                                        MouseArea {
                                            anchors.fill: parent
                                            anchors.margins: -6
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: controlCenter.activePlayer?.next()
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 3
                                        radius: 1.5
                                        color: "#ffffff"
                                        opacity: 0.15
                                        Layout.alignment: Qt.AlignVCenter

                                        Rectangle {
                                            height: parent.height
                                            radius: 1.5
                                            color: "#eae6dc"
                                            width: parent.width * (controlCenter.activePlayer && controlCenter.activePlayer.length > 0
                                                ? controlCenter.activePlayer.position / controlCenter.activePlayer.length
                                                : 0)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    NotificationHistory {
                        Layout.fillWidth: true
                        Layout.fillHeight: controlCenter.storedNotifications.length > 0
                        Layout.preferredHeight: controlCenter.storedNotifications.length > 0 ? 200 : 0
                        Layout.minimumHeight: controlCenter.storedNotifications.length > 0 ? 120 : 0
                        Layout.maximumHeight: controlCenter.storedNotifications.length > 0 ? 400 : 0
                        storedNotifications: controlCenter.storedNotifications
                        onDismissNotif: (notifRef) => controlCenter.dismissNotif(notifRef)
                        onClearAll: controlCenter.clearNotifs()
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.topMargin: 8
                        visible: controlCenter.storedNotifications.length === 0
                        text: "No notifications"
                        color: "#eae6dc"
                        opacity: 0.3
                        horizontalAlignment: Text.AlignHCenter
                        font { family: "Inter"; pixelSize: 12 }
                    }

                    Item { Layout.fillHeight: true }
                }

            // ---- WI-FI PAGE ----
            ScrollView {
                visible: controlCenter.page === "wifi"
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ColumnLayout {
                    width: panel.width - 40
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        radius: 14
                        color: "#1a2421"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            Text { text: "Wi-Fi"; color: "#eae6dc"; font { family: "Inter"; pixelSize: 14; weight: 700 } }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                width: 46; height: 26; radius: 13
                                color: controlCenter.wifiEnabled ? "#3ba889" : "#33403c"
                                Rectangle {
                                    width: 20; height: 20; radius: 10; color: "#fff"
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: controlCenter.wifiEnabled ? parent.width - width - 3 : 3
                                    Behavior on x { NumberAnimation { duration: 120 } }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: controlCenter.toggleWifi() }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        visible: controlCenter.wifiEnabled && controlCenter.wifiName !== "No network" && controlCenter.wifiName !== "Off"
                        Layout.preferredHeight: connectedCol.implicitHeight + 28
                        radius: 16
                        color: "#13201c"
                        border.color: "#3ba889"
                        border.width: 1

                        ColumnLayout {
                            id: connectedCol
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: ""; color: "#3ba889"; font { family: "JetBrainsMono Nerd Font"; pixelSize: 16 } }
                                ColumnLayout {
                                    spacing: 0
                                    Layout.fillWidth: true
                                    Text { text: controlCenter.wifiName; color: "#fff"; font { family: "Inter"; pixelSize: 14; weight: 700 } }
                                    Text { text: "Connected"; color: "#3ba889"; font { family: "Inter"; pixelSize: 11 } }
                                }
                                Text {
                                    text: "Disconnect"
                                    color: "#eae6dc"; opacity: 0.7
                                    font { family: "Inter"; pixelSize: 11; weight: 600 }
                                    MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: controlCenter.disconnectWifi() }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                visible: controlCenter.wifiCurrentPassword.length > 0
                                spacing: 8

                                Text { text: "Password:"; color: "#eae6dc"; opacity: 0.7; font { family: "Inter"; pixelSize: 12 } }
                                Text {
                                    text: controlCenter.wifiPasswordRevealed ? controlCenter.wifiCurrentPassword : "•".repeat(Math.max(6, controlCenter.wifiCurrentPassword.length))
                                    color: "#fff"
                                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 12 }
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: controlCenter.wifiPasswordRevealed ? "󰋭" : "󰋬"
                                    color: "#eae6dc"
                                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 14 }
                                    MouseArea {
                                        anchors.fill: parent; anchors.margins: -8
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            controlCenter.wifiPasswordRevealed = !controlCenter.wifiPasswordRevealed;
                                            if (controlCenter.wifiPasswordRevealed && !controlCenter.wifiQrPath) controlCenter.generateWifiQr();
                                        }
                                    }
                                }
                            }

                            Image {
                                visible: controlCenter.wifiPasswordRevealed && controlCenter.wifiQrPath.length > 0
                                source: controlCenter.wifiQrPath
                                Layout.preferredWidth: 140
                                Layout.preferredHeight: 140
                                Layout.alignment: Qt.AlignHCenter
                                fillMode: Image.PreserveAspectFit
                                smooth: false
                            }

                            Text {
                                visible: controlCenter.wifiPasswordRevealed && controlCenter.wifiCurrentPassword.length === 0
                                text: "No saved password found for this network."
                                color: "#eae6dc"; opacity: 0.5
                                font { family: "Inter"; pixelSize: 11 }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        Text { text: "Networks"; color: "#eae6dc"; opacity: 0.7; font { family: "Inter"; pixelSize: 12; weight: 700 } }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: controlCenter.wifiScanning ? "Scanning…" : "Refresh"
                            color: "#3ba889"
                            font { family: "Inter"; pixelSize: 11; weight: 600 }
                            MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: controlCenter.scanWifi() }
                        }
                    }

                    Repeater {
                        model: controlCenter.wifiNetworks

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            radius: 14
                            color: modelData.active ? "#16241f" : "#1a2421"

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: modelData.signal > 66 ? "" : modelData.signal > 33 ? "" : ""
                                    color: "#eae6dc"
                                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 15 }
                                }

                                ColumnLayout {
                                    spacing: 0
                                    Layout.fillWidth: true
                                    Text { text: modelData.ssid; color: "#fff"; elide: Text.ElideRight; Layout.fillWidth: true; font { family: "Inter"; pixelSize: 13; weight: 600 } }
                                    Text {
                                        text: modelData.active ? "Connected" : (modelData.security && modelData.security !== "--" ? "Secured" : "Open")
                                        color: modelData.active ? "#3ba889" : "#eae6dc"
                                        opacity: modelData.active ? 1 : 0.6
                                        font { family: "Inter"; pixelSize: 10 }
                                    }
                                }

                                Text {
                                    visible: modelData.security && modelData.security !== "--"
                                    text: "󰲛"
                                    color: "#eae6dc"; opacity: 0.5
                                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.active) return;
                                    controlCenter.wifiConnectError = "";
                                    if (modelData.security && modelData.security !== "--") {
                                        controlCenter.wifiPendingSsid = modelData.ssid;
                                        controlCenter.wifiNeedsPassword = true;
                                    } else {
                                        controlCenter.connectToWifi(modelData.ssid, modelData.security, "");
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible: controlCenter.wifiNetworks.length === 0 && !controlCenter.wifiScanning
                        text: "No networks found"
                        color: "#eae6dc"; opacity: 0.4
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 12
                        font { family: "Inter"; pixelSize: 12 }
                    }

                    Item { Layout.preferredHeight: 4 }
                }
            }

            // ---- BLUETOOTH PAGE ----
            ScrollView {
                visible: controlCenter.page === "bluetooth"
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ColumnLayout {
                    width: panel.width - 40
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        radius: 14
                        color: "#1a2421"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            Text { text: "Bluetooth"; color: "#eae6dc"; font { family: "Inter"; pixelSize: 14; weight: 700 } }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                width: 46; height: 26; radius: 13
                                color: controlCenter.btAdapter?.enabled ? "#3ba889" : "#33403c"
                                Rectangle {
                                    width: 20; height: 20; radius: 10; color: "#fff"
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: controlCenter.btAdapter?.enabled ? parent.width - width - 3 : 3
                                    Behavior on x { NumberAnimation { duration: 120 } }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: controlCenter.toggleBluetooth() }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        spacing: 8

                        Text {
                            text: "Devices"
                            color: "#eae6dc"; opacity: 0.7
                            font { family: "Inter"; pixelSize: 12; weight: 700 }
                            Layout.fillWidth: true
                        }

                        Text {
                            text: controlCenter.btScanning ? "Scanning…" : "Scan"
                            color: "#3ba889"
                            font { family: "Inter"; pixelSize: 11; weight: 600 }
                            MouseArea {
                                anchors.fill: parent; anchors.margins: -6
                                cursorShape: Qt.PointingHandCursor
                                onClicked: controlCenter.toggleBtScan()
                            }
                        }
                    }

                    Repeater {
                        model: controlCenter.btDevices

                        delegate: Rectangle {
                            id: btCard
                            required property BluetoothDevice modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 56
                            radius: 14
                            color: modelData.state === BluetoothDeviceState.Connected ? "#16241f" : (modelData.pairing ? "#1d2a25" : "#1a2421")

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: modelData.pairing ? "󰄉" : (modelData.state === BluetoothDeviceState.Connected ? "󰂱" : "󰂯")
                                    color: modelData.state === BluetoothDeviceState.Connected ? "#3ba889" : "#eae6dc"
                                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 16 }
                                }

                                ColumnLayout {
                                    spacing: 0
                                    Layout.fillWidth: true
                                    Text { text: btCard.modelData.name || btCard.modelData.deviceName || "Unknown device"; color: "#fff"; elide: Text.ElideRight; Layout.fillWidth: true; font { family: "Inter"; pixelSize: 13; weight: 600 } }
                                    Text {
                                        text: controlCenter.btDeviceSubtitle(btCard.modelData)
                                        color: modelData.state === BluetoothDeviceState.Connected ? "#3ba889" : "#eae6dc"
                                        opacity: modelData.state === BluetoothDeviceState.Connected ? 1 : 0.6
                                        font { family: "Inter"; pixelSize: 10 }
                                    }
                                }

                                Text {
                                    text: modelData.pairing ? "" : (modelData.paired ? "Forget" : "Pair")
                                    visible: !modelData.pairing
                                    color: "#e06c75"
                                    font { family: "Inter"; pixelSize: 11; weight: 600 }
                                    MouseArea {
                                        anchors.fill: parent; anchors.margins: -8
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: modelData.paired ? controlCenter.forgetDevice(modelData) : controlCenter.pairDevice(modelData)
                                    }
                                }

                                Text {
                                    text: modelData.state === BluetoothDeviceState.Connected ? "Disconnect" : "Connect"
                                    visible: modelData.paired && !modelData.pairing
                                    color: "#3ba889"
                                    font { family: "Inter"; pixelSize: 11; weight: 600 }
                                    MouseArea {
                                        anchors.fill: parent; anchors.margins: -8
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: controlCenter.toggleBtConnection(modelData)
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible: controlCenter.btDevices.length === 0 && !controlCenter.btScanning
                        text: controlCenter.btAdapter?.enabled ? "No devices found" : "Turn on Bluetooth to see devices"
                        color: "#eae6dc"; opacity: 0.4
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 12
                        font { family: "Inter"; pixelSize: 12 }
                    }

                    Text {
                        visible: controlCenter.btScanning && controlCenter.btDevices.length === 0
                        text: "Scanning for devices…"
                        color: "#3ba889"; opacity: 0.6
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 12
                        font { family: "Inter"; pixelSize: 12 }
                    }

                    Item { Layout.preferredHeight: 4 }
                }
            }
        }

            // ---- AUDIO PAGE ----
            ScrollView {
                visible: controlCenter.page === "audio"
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                Column {
                    width: parent.width
                    spacing: 10

                    PageHeader {
                        title: "Audio"
                        onBackTapped: controlCenter.page = "main"
                    }

                    Text {
                        text: "Output"
                        color: "#8fa59c"
                        font { family: "Inter"; pixelSize: 11; weight: 700 }
                        leftPadding: 4
                    }

                    Repeater {
                        model: controlCenter.audioSinks

                        Rectangle {
                            required property var modelData
                            width: parent.width
                            height: 40
                            radius: 10
                            color: modelData === controlCenter.audioSink ? "#1d2a25" : "#16241f"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8

                                Text {
                                    text: modelData === controlCenter.audioSink ? "✓" : "  "
                                    color: "#3ba889"
                                    font { family: "Inter"; pixelSize: 13; weight: 700 }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: modelData.description || modelData.name || ""
                                        color: "#eae6dc"
                                        font { family: "Inter"; pixelSize: 12; weight: modelData === controlCenter.audioSink ? 600 : 400 }
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: modelData.nickname || ""
                                        visible: text !== ""
                                        color: "#6a8078"
                                        font { family: "Inter"; pixelSize: 9 }
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: controlCenter.setDefaultSink(modelData)
                            }
                        }
                    }

                    IconSlider {
                        iconText: controlCenter.volumeIcon(controlCenter.audioVolume, controlCenter.audioMuted)
                        value: controlCenter.audioMuted ? 0 : controlCenter.audioVolume
                        onMoved: val => controlCenter.setVolume(val)
                    }

                    Item { Layout.preferredHeight: 8 }

                    Text {
                        text: "Input"
                        color: "#8fa59c"
                        font { family: "Inter"; pixelSize: 11; weight: 700 }
                        leftPadding: 4
                    }

                    Repeater {
                        model: controlCenter.audioSources

                        Rectangle {
                            required property var modelData
                            width: parent.width
                            height: 40
                            radius: 10
                            color: modelData === controlCenter.audioSource ? "#1d2a25" : "#16241f"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8

                                Text {
                                    text: modelData === controlCenter.audioSource ? "✓" : "  "
                                    color: "#3ba889"
                                    font { family: "Inter"; pixelSize: 13; weight: 700 }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: modelData.description || modelData.name || ""
                                        color: "#eae6dc"
                                        font { family: "Inter"; pixelSize: 12; weight: modelData === controlCenter.audioSource ? 600 : 400 }
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: modelData.nickname || ""
                                        visible: text !== ""
                                        color: "#6a8078"
                                        font { family: "Inter"; pixelSize: 9 }
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: controlCenter.setDefaultSource(modelData)
                            }
                        }
                    }

                    IconSlider {
                        iconText: controlCenter.volumeIcon(controlCenter.audioSourceVolume, controlCenter.audioSourceMuted)
                        value: controlCenter.audioSourceMuted ? 0 : controlCenter.audioSourceVolume
                        onMoved: val => controlCenter.setAudioSourceVolume(val)
                    }

                    Item { Layout.preferredHeight: 4 }
                }
            }
    }

    // ---- Wi-Fi password dialog ----
    Rectangle {
        anchors.fill: parent
        visible: controlCenter.wifiNeedsPassword
        color: "#000"
        opacity: 0.5

        MouseArea { anchors.fill: parent; onClicked: controlCenter.wifiNeedsPassword = false }
    }

    Rectangle {
        visible: controlCenter.wifiNeedsPassword
        anchors.centerIn: parent
        width: 320
        height: pwCol.implicitHeight + 32
        radius: 18
        color: "#101a17"
        border.color: "#1a2421"
        border.width: 1

        ColumnLayout {
            id: pwCol
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            Text {
                text: "Connect to " + controlCenter.wifiPendingSsid
                color: "#fff"
                font { family: "Inter"; pixelSize: 14; weight: 700 }
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Rectangle {
                Layout.fillWidth: true
                height: 40
                radius: 10
                color: "#1a2421"

                TextField {
                    id: pwField
                    anchors.fill: parent
                    anchors.margins: 4
                    color: "#fff"
                    echoMode: revealBtn.checked ? TextInput.Normal : TextInput.Password
                    placeholderText: "Password"
                    placeholderTextColor: "#888"
                    background: null
                    font { family: "Inter"; pixelSize: 13 }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                CheckBox {
                    id: revealBtn
                    text: "Show password"
                    contentItem: Text { text: revealBtn.text; color: "#eae6dc"; opacity: 0.7; leftPadding: revealBtn.indicator.width + 6; font { family: "Inter"; pixelSize: 11 } }
                }
            }

            Text {
                visible: controlCenter.wifiConnectError.length > 0
                text: controlCenter.wifiConnectError
                color: "#e06c75"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                font { family: "Inter"; pixelSize: 11 }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Layout.topMargin: 4

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 10
                    color: "#1a2421"
                    Text { anchors.centerIn: parent; text: "Cancel"; color: "#eae6dc"; font { family: "Inter"; pixelSize: 12; weight: 600 } }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { controlCenter.wifiNeedsPassword = false; pwField.text = ""; } }
                }
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 10
                    color: "#3ba889"
                    Text { anchors.centerIn: parent; text: controlCenter.wifiConnecting ? "Connecting…" : "Connect"; color: "#000"; font { family: "Inter"; pixelSize: 12; weight: 700 } }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: !controlCenter.wifiConnecting
                        onClicked: {
                            controlCenter.connectToWifi(controlCenter.wifiPendingSsid, "secured", pwField.text);
                        }
                    }
                }
            }
        }
    }
}
