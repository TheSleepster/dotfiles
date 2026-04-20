// ================================================================
// shell.qml — Complete Quickshell bar
// Translated from config.jsonc + style.css
// ================================================================
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: shell

    // ════════════════════════════════════════════════════════════
    // PALETTE  — direct translation of @define-color in style.css
    // ════════════════════════════════════════════════════════════
    readonly property color clrBg:  Qt.rgba(15/255, 7/255, 7/255, 0.8)
    readonly property color clrFg:  "#B5ADAD"
    readonly property color clr0:   "#302F2F"
    readonly property color clr2:   "#191D07"
    readonly property color clr3:   "#740E0E"
    readonly property color clr4:   "#4E4747"
    readonly property color clr6:   "#B14D4D"
    readonly property string fnt:   "LiterationMono Nerd Font Propo"
    readonly property int    fSm:   16   // * { font-size: 12px }
    readonly property int    fLg:   16   // #clock { font-size: 14px }
    readonly property int    fMd:   16   // #custom-mpd-* { font-size: 15px }

    // ════════════════════════════════════════════════════════════
    // BAR — spawned once per screen
    // ════════════════════════════════════════════════════════════
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors { top: true; left: true; right: true }
            margins { top: 5; left: 5; right: 5; bottom: 0 }
            implicitHeight: 30

            color: "transparent"

            // ── Outer bar: background + 2px accent border ─────
            // #window#waybar { background: @bg; border: 2px solid @color6 }
            Item {
                anchors.fill: parent

                Item {
                    anchors {
                        fill:         parent
                        leftMargin:   4; rightMargin: 4
                        topMargin:    3; bottomMargin: 3
                    }

                    // ══════════════════════════════════════════
                    // LEFT — group-1 · group-2 · group-3
                    // ══════════════════════════════════════════
                    Row {
                        anchors.left:           parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        // ── group-1: Hyprland Workspaces ──────
                        Rectangle {
                            color: shell.clrBg; border.color: shell.clr4
                            border.width: 1; radius: 6; height: 24
                            width: wsRow.implicitWidth + 12

                            Row {
                                id: wsRow
                                anchors.centerIn: parent
                                spacing: 2

                                Repeater {
                                    model: Hyprland.workspaces

                                    delegate: Rectangle {
                                        id: wsBtn
                                        required property HyprlandWorkspace modelData

                                        // Hide special:magic and any other special workspaces —
                                        // Row automatically excludes invisible items from layout
                                        visible: !wsBtn.modelData.name.startsWith("special:")

                                        readonly property bool isActive:
                                            Hyprland.focusedMonitor?.activeWorkspace?.id === wsBtn.modelData.id
                                        property bool hov: false

                                        height: 22
                                        radius: isActive ? 6 : 8
                                        width:  isActive ? wsLbl.implicitWidth + 16
                                                         : wsLbl.implicitWidth + 6
                                        color: {
                                            if (isActive) return shell.clr6
                                            if (hov)      return shell.clr0
                                            return "transparent"
                                        }

                                        // Width animates with cubic-bezier (matches CSS transition)
                                        Behavior on width {
                                            NumberAnimation { duration: 400; easing.type: Easing.InOutCubic }
                                        }

                                        Text {
                                            id: wsLbl
                                            anchors.centerIn: parent
                                            text:           wsBtn.modelData.name
                                            color:          wsBtn.isActive ? shell.clr0 : shell.clrFg
                                            font.family:    shell.fnt
                                            font.pixelSize: shell.fSm
                                        }

                                        MouseArea {
                                            anchors.fill: parent; hoverEnabled: true
                                            onEntered: wsBtn.hov = true
                                            onExited:  wsBtn.hov = false
                                            onClicked: Hyprland.dispatch("workspace " + wsBtn.modelData.id)
                                        }
                                    }
                                }
                            }
                        }

                        // ── group-2: Pacman update counter ────
                        Rectangle {
                            id: pacGrp
                            color: shell.clrBg; border.color: shell.clr4
                            border.width: 1; radius: 6; height: 24
                            width: pacLbl.implicitWidth + 16

                            property int  updates: 0
                            property bool hov: false

                            Process {
                                id: checkUpd
                                command: ["bash", "-c", "checkupdates 2>/dev/null | wc -l"]
                                stdout: SplitParser {
                                    onRead: data => pacGrp.updates = parseInt(data.trim()) || 0
                                }
                            }
                            Process {
                                id: openUpd
                                command: ["ghostty", "-e", "zsh", "-c",
                                    "fastfetch && sleep 0.5 && sudo pacman -Syu; exec zsh"]
                            }
                            Timer {
                                interval: 3600000; running: true; repeat: true; triggeredOnStart: true
                                onTriggered: if (!checkUpd.running) checkUpd.running = true
                            }

                            Text {
                                id: pacLbl
                                anchors.centerIn: parent
                                text:           "󰮯 " + pacGrp.updates
                                color:          pacGrp.hov ? shell.clr6 : shell.clrFg
                                font.family:    shell.fnt
                                font.pixelSize: shell.fSm
                            }
                            MouseArea {
                                anchors.fill: parent; hoverEnabled: true
                                onEntered: pacGrp.hov = true
                                onExited:  pacGrp.hov = false
                                onClicked: if (!openUpd.running) openUpd.running = true
                            }
                        }

                        // ── group-3: MPD controls + song bar ──
                        Rectangle {
                            id: mpdGrp
                            color: shell.clrBg; border.color: shell.clr4
                            border.width: 1; radius: 6; height: 24
                            width: mpdRow.implicitWidth + 12

                            property string ppIcon:    "\uF04B"  // nf-fa-play default
                            property string song:      "—"
                            property bool   isPlaying: false
                            property int    progress:  0         // 0–100

                            // ── Processes ────────────────────────────────────────────
                            Process {
                                id: mpdStat
                                command: ["bash", "-c",
                                    "mpc status 2>/dev/null | grep -q '\\[playing\\]' && echo playing || echo stopped"]
                                stdout: SplitParser {
                                    onRead: data => {
                                        const playing      = data.trim() === "playing"
                                        mpdGrp.isPlaying   = playing
                                        mpdGrp.ppIcon      = playing ? "\uF04C" : "\uF04B"
                                    }
                                }
                            }
                            Process {
                                id: mpdProgressP
                                // Extracts the "(XX%)" from mpc status
                                command: ["bash", "-c",
                                    "mpc status 2>/dev/null | grep -oP '\\(\\K[0-9]+(?=%)' | head -1"]
                                stdout: SplitParser {
                                    onRead: data => mpdGrp.progress = parseInt(data.trim()) || 0
                                }
                            }
                            Process {
                                id: mpdTrack
                                command: ["bash", "-c",
                                    "mpc current --format '%title% - %artist%' 2>/dev/null || echo '—'"]
                                stdout: SplitParser {
                                    onRead: data => mpdGrp.song = data.trim() || "—"
                                }
                            }
                            Timer {
                                interval: 1000; running: true; repeat: true; triggeredOnStart: true
                                onTriggered: {
                                    if (!mpdStat.running)      mpdStat.running      = true
                                    if (!mpdProgressP.running) mpdProgressP.running = true
                                    if (!mpdTrack.running)     mpdTrack.running     = true
                                }
                            }

                            Process { id: mpcPrev;   command: ["mpc", "prev"]   }
                            Process { id: mpcToggle; command: ["mpc", "toggle"] }
                            Process { id: mpcNext;   command: ["mpc", "next"]   }

                            // ── Progress bar — creeps across the bottom of the pill ──
                            Rectangle {
                                anchors {
                                    bottom: parent.bottom
                                    left:   parent.left;  leftMargin:  1
                                    right:  parent.right; rightMargin: 1
                                }
                                height: 2; radius: 1
                                color: "transparent"

                                Rectangle {
                                    width:  parent.width * (mpdGrp.progress / 100)
                                    height: 2; radius: 1
                                    color:  shell.clr6
                                    Behavior on width {
                                        NumberAnimation { duration: 900; easing.type: Easing.OutCubic }
                                    }
                                }
                            }

                            // ── Main content row ─────────────────────────────────────
                            Row {
                                id: mpdRow
                                anchors.centerIn: parent
                                spacing: 0

                                // ── Animated equalizer bars ───────────────────────────
                                // 4 bars with staggered peak heights & durations;
                                // they bounce while playing and settle flat when paused.
                                Item {
                                    width: 22
                                    height: parent.height
                                    anchors.verticalCenter: parent.verticalCenter

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 3

                                        Repeater {
                                            model: 4

                                            Rectangle {
                                                required property int index
                                                width:  3
                                                radius: 1
                                                color:  shell.clr6
                                                anchors.verticalCenter: parent.verticalCenter

                                                // Per-bar personality: [peakHeight, animDuration]
                                                readonly property var cfg: [
                                                    [13, 290], [9, 180], [15, 370], [7, 240]
                                                ][index]

                                                property real barH: 4
                                                height: barH

                                                // Bounce animation — runs only while playing
                                                SequentialAnimation on barH {
                                                    running: mpdGrp.isPlaying
                                                    loops:   Animation.Infinite
                                                    NumberAnimation {
                                                        to: cfg[0]; duration: cfg[1]
                                                        easing.type: Easing.InOutSine
                                                    }
                                                    NumberAnimation {
                                                        to: 3; duration: cfg[1] * 0.65
                                                        easing.type: Easing.InOutSine
                                                    }
                                                }

                                                // Smoothly settle to rest when paused
                                                NumberAnimation on barH {
                                                    running:  !mpdGrp.isPlaying
                                                    to:       4
                                                    duration: 350
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }
                                    }
                                }

                                // "󰒮" prev — faded until hover
                                Text {
                                    id: mpdPrevBtn
                                    property bool hov: false
                                    text: "󰒮"; color: shell.clr6
                                    opacity: hov ? 1.0 : 0.35
                                    font.family: shell.fnt; font.pixelSize: shell.fMd
                                    leftPadding: 2; rightPadding: 2
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                    MouseArea {
                                        anchors.fill: parent; hoverEnabled: true
                                        onEntered: mpdPrevBtn.hov = true
                                        onExited:  mpdPrevBtn.hov = false
                                        onClicked: if (!mpcPrev.running) mpcPrev.running = true
                                    }
                                }

                                // play / pause — faded until hover
                                Text {
                                    id: mpdPlayBtn
                                    property bool hov: false
                                    text: mpdGrp.ppIcon; color: shell.clr6
                                    opacity: hov ? 1.0 : 0.35
                                    font.family: shell.fnt; font.pixelSize: shell.fMd
                                    leftPadding: 3; rightPadding: 3
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                    MouseArea {
                                        anchors.fill: parent; hoverEnabled: true
                                        onEntered: mpdPlayBtn.hov = true
                                        onExited:  mpdPlayBtn.hov = false
                                        onClicked: if (!mpcToggle.running) mpcToggle.running = true
                                    }
                                }

                                // "󰒭" next — faded until hover
                                Text {
                                    id: mpdNextBtn
                                    property bool hov: false
                                    text: "󰒭"; color: shell.clr6
                                    opacity: hov ? 1.0 : 0.35
                                    font.family: shell.fnt; font.pixelSize: shell.fMd
                                    leftPadding: 2; rightPadding: 4
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                    MouseArea {
                                        anchors.fill: parent; hoverEnabled: true
                                        onEntered: mpdNextBtn.hov = true
                                        onExited:  mpdNextBtn.hov = false
                                        onClicked: if (!mpcNext.running) mpcNext.running = true
                                    }
                                }

                                // Song title — elided, fixed width
                                Text {
                                    text:              mpdGrp.song
                                    color:             shell.clrFg
                                    font.family:       shell.fnt
                                    font.pixelSize:    shell.fSm
                                    width:             200
                                    elide:             Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding:       4
                                }
                            }
                        }
                    }

                    // ══════════════════════════════════════════
                    // CENTER — group-4 (Clock)
                    // ══════════════════════════════════════════
                    Rectangle {
                        id: clockGrp
                        anchors.centerIn: parent
                        color: shell.clrBg; border.color: shell.clr4
                        border.width: 1; radius: 6; height: 24
                        width: clockTxt.implicitWidth + 20

                        property var now: new Date()
                        Timer {
                            interval: 1000; running: true; repeat: true
                            onTriggered: clockGrp.now = new Date()
                        }

                        Text {
                            id: clockTxt
                            anchors.centerIn: parent
                            // Matches strftime "%H:%M - %h %d"  e.g. "14:30 - Apr 18"
                            text: {
                                const d  = clockGrp.now
                                const hh = String(d.getHours()).padStart(2, "0")
                                const mm = String(d.getMinutes()).padStart(2, "0")
                                const mo = ["Jan","Feb","Mar","Apr","May","Jun",
                                            "Jul","Aug","Sep","Oct","Nov","Dec"][d.getMonth()]
                                const dd = String(d.getDate()).padStart(2, "0")
                                return hh + ":" + mm + " - " + mo + " " + dd
                            }
                            color: shell.clrFg; font.family: shell.fnt; font.pixelSize: shell.fLg
                        }
                    }

                    // ══════════════════════════════════════════
                    // RIGHT — group-6 · group-5
                    // ══════════════════════════════════════════
                    Row {
                        anchors.right:          parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        // ── group-6: CPU · GPU · Disk · Memory ──
                        Rectangle {
                            id: statsGrp
                            color: shell.clrBg; border.color: shell.clr4
                            border.width: 1; radius: 6; height: 24
                            width: statsRow.implicitWidth + 12

                            property int  cpu:  0
                            property int  gpu:  0
                            property int  dsk:  0
                            property real memU: 0.0
                            property real memT: 0.0

                            // cpu interval: 5s
                            Process {
                                id: cpuP
                                command: ["bash", "-c", "top -bn1 | awk '/^%Cpu/{print int($2+$4)}'"]
                                stdout: SplitParser { onRead: data => statsGrp.cpu = parseInt(data) || 0 }
                            }
                            // custom/gpu — exact exec from config.jsonc
                            Process {
                                id: gpuP
                                command: ["bash", "-c",
                                    "nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null " +
                                    "|| sensors | grep -i GPU | awk '{print $2}' | tr -d '+°C' | head -1"]
                                stdout: SplitParser { onRead: data => statsGrp.gpu = parseInt(data) || 0 }
                            }
                            // disk interval: 30s  path: /
                            Process {
                                id: dskP
                                command: ["bash", "-c", "df / | awk 'NR==2{print $5}' | tr -d '%'"]
                                stdout: SplitParser { onRead: data => statsGrp.dsk = parseInt(data) || 0 }
                            }
                            // memory interval: 30s  (free gives KiB → divide to GiB)
                            Process {
                                id: memP
                                command: ["bash", "-c",
                                    "free | awk '/^Mem:/{printf \"%.1f %.1f\",$3/1048576,$2/1048576}'"]
                                stdout: SplitParser {
                                    onRead: data => {
                                        const p = data.trim().split(" ")
                                        statsGrp.memU = parseFloat(p[0]) || 0
                                        statsGrp.memT = parseFloat(p[1]) || 0
                                    }
                                }
                            }
                            Timer {
                                interval: 1000; running: true; repeat: true; triggeredOnStart: true
                                onTriggered: {
                                    if (!cpuP.running) cpuP.running = true
                                    if (!gpuP.running) gpuP.running = true
                                }
                            }
                            Timer {
                                interval: 30000; running: true; repeat: true; triggeredOnStart: true
                                onTriggered: {
                                    if (!dskP.running) dskP.running = true
                                    if (!memP.running) memP.running = true
                                }
                            }

                            Row {
                                id: statsRow
                                anchors.centerIn: parent
                                spacing: 8

                                // CPU
                                Text {
                                    text: " " + statsGrp.cpu + "%"
                                    color: statsGrp.cpu > 80 ? shell.clr3 : shell.clrFg
                                    font.family: shell.fnt; font.pixelSize: shell.fSm
                                }

                                // GPU
                                Text {
                                    text: "󰾲 " + statsGrp.gpu + "% "
                                    color: statsGrp.gpu > 80 ? shell.clr3 : shell.clrFg
                                    font.family: shell.fnt; font.pixelSize: shell.fSm
                                }

                                // Memory  e.g. " 6.1/15.4G"
                                Text {
                                    text: "\uefc5 " + statsGrp.memU.toFixed(1) + "/" + statsGrp.memT.toFixed(1) + "G "
                                    color: (statsGrp.memT > 0 && statsGrp.memU / statsGrp.memT > 0.85)
                                           ? shell.clr3 : shell.clrFg
                                    font.family: shell.fnt; font.pixelSize: shell.fSm
                                }

                                // Disk
                                Text {
                                    text: "󰋊 " + statsGrp.dsk + "%"
                                    color: statsGrp.dsk > 90 ? shell.clr3 : shell.clrFg
                                    font.family: shell.fnt; font.pixelSize: shell.fSm
                                }
                            }
                        }


                        // ── group-5: Backlight · Vol · Bat · BT · Net · Power ──
                        Rectangle {
                            id: statGrp
                            color: shell.clrBg; border.color: shell.clr4
                            border.width: 1; radius: 6; height: 24
                            width: statRow.implicitWidth + 12

                            // State
                            property int    bright:    50
                            property int    vol:       50
                            property bool   muted:     false
                            property int    bat:       100
                            property bool   charging:  false
                            property bool   batCrit:   false
                            property bool   blinkOn:   true
                            property string netIcon:   "󰖪"
                            property bool   netUp:     false
                            property string btIcon:    "󰂯"

                            // Critical battery blink — 0.5s alternating (matches @keyframes blink)
                            Timer {
                                interval: 500; repeat: true; running: statGrp.batCrit
                                onTriggered: statGrp.blinkOn = !statGrp.blinkOn
                                onRunningChanged: if (!running) statGrp.blinkOn = true
                            }

                            // ── Backlight ────────────────────────────────────────────
                            Process {
                                id: brightP
                                command: ["bash", "-c", "brightnessctl -m | awk -F, '{print $4}' | tr -d '%'"]
                                stdout: SplitParser { onRead: data => statGrp.bright = parseInt(data) || 0 }
                            }
                            Process {
                                id: brightSet
                                property int target: 50
                                command: ["bash", "-c", "brightnessctl set " + target + "%"]
                            }

                            // ── Volume via pactl ─────────────────────────────────────
                            //   "Volume: 0.65" or "Volume: 0.65 [MUTED]"
                            Process {
                                id: volP
                                command: ["bash", "-c", "pactl get-volume @DEFAULT_AUDIO_SINK@"]
                                stdout: SplitParser {
                                    onRead: data => {
                                        const m = data.match(/Volume:\s*([0-9.]+)(\s*\[MUTED\])?/)
                                        if (m) {
                                            statGrp.vol   = Math.round(parseFloat(m[1]) * 100)
                                            statGrp.muted = !!m[2]
                                        }
                                    }
                                }
                            }
                            Process { id: volSet;    property string pct: "50%"; command: ["wpactl","set-volume","@DEFAULT_AUDIO_SINK@", pct] }
                            Process { id: muteTogP;  command: ["wpactl","set-mute","@DEFAULT_AUDIO_SINK@","toggle"] }

                            // ── Battery ──────────────────────────────────────────────
                            Process {
                                id: batCapP
                                command: ["bash", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1"]
                                stdout: SplitParser {
                                    onRead: data => {
                                        statGrp.bat     = parseInt(data) || 0
                                        statGrp.batCrit = statGrp.bat <= 15 && !statGrp.charging
                                    }
                                }
                            }
                            Process {
                                id: batStatP
                                command: ["bash", "-c", "cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1"]
                                stdout: SplitParser {
                                    onRead: data => {
                                        statGrp.charging = (data.trim() === "Charging" || data.trim() === "Full")
                                        statGrp.batCrit  = statGrp.bat <= 15 && !statGrp.charging
                                    }
                                }
                            }

                            // ── Network ──────────────────────────────────────────────
                            Process {
                                id: netP
                                command: ["bash", "-c",
                                "nmcli -t -f TYPE,STATE dev 2>/dev/null | grep ':connected' | head -1 | cut -d: -f1"]
                                stdout: SplitParser {
                                    onRead: data => {
                                        const t = data.trim()
                                        if      (t === "wifi")     { statGrp.netIcon = "󰤨"; statGrp.netUp = true  }
                                        else if (t === "ethernet") { statGrp.netIcon = "󰌗"; statGrp.netUp = true  }
                                        else                       { statGrp.netIcon = "󰖪"; statGrp.netUp = false }
                                    }
                                }
                            }

                            // ── Bluetooth ─────────────────────────────────────────────
                            Process {
                                id: btP
                                command: ["bash", "-c",
                                "if bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then " +
                                "  bluetoothctl devices Connected 2>/dev/null | grep -q Device && echo connected || echo on; " +
                                "else echo off; fi"]
                                stdout: SplitParser {
                                    onRead: data => {
                                        const s = data.trim()
                                        statGrp.btIcon = s === "connected" ? "󰤾"
                                        : s === "on"        ? "󰂯"
                                        :                     "󰂲"
                                    }
                                }
                            }

                            // 3-second refresh for all status modules
                            Timer {
                                interval: 3000; running: true; repeat: true; triggeredOnStart: true
                                onTriggered: {
                                    if (!brightP.running)  brightP.running  = true
                                    if (!volP.running)     volP.running     = true
                                    if (!batCapP.running)  batCapP.running  = true
                                    if (!batStatP.running) batStatP.running = true
                                    if (!netP.running)     netP.running     = true
                                    if (!btP.running)      btP.running      = true
                                }
                            }

                            // App launchers
                            Process { id: pavuP;   command: ["pavucontrol"] }
                            Process { id: bluebP;  command: ["blueberry"]   }
                            Process { id: wlogP;   command: ["wlogout"]     }
                            Process { id: nmguiP;  command: ["nmgui"]       }

                            Row {
                                id: statRow
                                anchors.centerIn: parent
                                spacing: 7

                                // Battery (read-only, no click action)
                                Text {
                                    property var bats: ["\uF244", "\uF243", "\uF242", "\uF241", "\uF240"]
                                    text: {
                                        if (statGrp.charging) return "\uF0E7  " + statGrp.bat + "% "
                                        return bats[Math.min(Math.floor(statGrp.bat / 20), 4)] +
                                        " " + statGrp.bat + "% "
                                    }
                                    color: {
                                        if (statGrp.charging) return shell.clr2
                                        if (statGrp.batCrit)  return statGrp.blinkOn ? shell.clr3 : shell.clrFg
                                        return shell.clrFg
                                    }
                                    font.family: shell.fnt; font.pixelSize: shell.fSm
                                }

                                // Volume — hover highlights, click → pavucontrol, scroll → adjust
                                Text {
                                    id: volStatLbl
                                    property bool hov: false
                                    property string vIcon: {
                                        if (statGrp.muted || statGrp.vol === 0) return "\uF026"
                                        if (statGrp.vol < 34)  return "\uF026"
                                        if (statGrp.vol < 67)  return "\uF027"
                                        return "\uF028"
                                    }
                                    text:  vIcon + " " + statGrp.vol + "% "
                                    color: statGrp.muted ? shell.clr3 : (hov ? shell.clr6 : shell.clrFg)
                                    font.family: shell.fnt; font.pixelSize: shell.fSm
                                    MouseArea {
                                        anchors.fill: parent; hoverEnabled: true
                                        onEntered: volStatLbl.hov = true
                                        onExited:  volStatLbl.hov = false
                                        onClicked: if (!pavuP.running) pavuP.running = true
                                        onWheel: event => {
                                            const d = event.angleDelta.y > 0 ? 5 : -5
                                            volSet.pct = Math.max(0, Math.min(150, statGrp.vol + d)) + "%"
                                            if (!volSet.running) volSet.running = true
                                        }
                                    }
                                }

                                // Bluetooth — hover highlights, click → blueberry
                                Text {
                                    id: btStatLbl
                                    property bool hov: false
                                    text: statGrp.btIcon
                                    color: hov ? shell.clr6 : shell.clrFg
                                    font.family: shell.fnt; font.pixelSize: shell.fSm
                                    MouseArea {
                                        anchors.fill: parent; hoverEnabled: true
                                        onEntered: btStatLbl.hov = true
                                        onExited:  btStatLbl.hov = false
                                        onClicked: if (!bluebP.running) bluebP.running = true
                                    }
                                }

                                // Network — hover highlights, disconnected → red, click → nm-connection-editor
                                Text {
                                    id: netStatLbl
                                    property bool hov: false
                                    text:  statGrp.netIcon
                                    color: statGrp.netUp ? (hov ? shell.clr6 : shell.clrFg) : shell.clr3
                                    font.family: shell.fnt; font.pixelSize: shell.fSm
                                    MouseArea {
                                        anchors.fill: parent; hoverEnabled: true
                                        onEntered: netStatLbl.hov = true
                                        onExited:  netStatLbl.hov = false
                                        onClicked: if (!nmguiP.running) nmguiP.running = true
                                    }
                                }

                                // Power — hover turns red, click → wlogout
                                Text {
                                    id: pwrStatLbl
                                    property bool hov: false
                                    text: "\uF011"
                                    color: hov ? shell.clr3 : shell.clrFg
                                    font.family: shell.fnt; font.pixelSize: shell.fSm
                                    leftPadding: 2
                                    MouseArea {
                                        anchors.fill: parent; hoverEnabled: true
                                        onEntered: pwrStatLbl.hov = true
                                        onExited:  pwrStatLbl.hov = false
                                        onClicked: if (!wlogP.running) wlogP.running = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
