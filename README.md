# shell

my personal [quickshell](https://quickshell.outfoxxed.me/) config for [niri](https://github.com/YaLTeR/niri) on NixOS. been slowly building this out after moving away from AwesomeWM, figured i'd clean it up and put it out there.

> **warning** - this is my daily config, not a distro rice. things might break, i might do something weird, no guarantees. was learning quickshell as i built this so the code is a bit rough in places, also used ai to help figure out the quickshell/QML side of things.

**Screenshots tba**

---

### what it looks like

bar with clock, weather inline, volume, battery, profile pic that opens the dashboard. popups for everything else, calendar, mpris player, wifi/bt management, notifications. pretty standard stuff.

---

### stack

| | |
|---|---|
| os | NixOS |
| compositor | niri |
| icons | gwnce (custom font) |
| mono font | JetBrains Mono Nerd Font |

---

### features

**bar**
- date + time + live weather (wttr.in, refreshes every 2h)
- volume + battery with reactive icons
- profile pic → dashboard

**date panel** - opens on clock click
- monthly calendar, click a day to open Google Calendar
- weather card with hourly and 2-day forecast (wttr.in)
- gcalcli events - shows course code, time, room, prof

**dashboard** - opens on profile pic click, three tabs:

- *overview* - wifi list with signal strength, saved profiles, password input on failed auth; bluetooth connect/disconnect/pair/scan; mpris player with cover art, progress bar, controls; volume + mic sliders (event-driven via `pactl subscribe`, no polling); uptime, power buttons; rotating quote
- *wallpaper* - paginated 3×3 grid of wallpapers from a folder, thumbnail previews, active indicator, sets via `swaybg` with no flash (new instance before killing old one)
- *schedule* - compact week view, one row per day with event chips (code + time + room), hover tooltip with full details (name, prof, room, hours), powered by gcalcli

**notifications**
- grouped by app so you don't get spammed
- inline images, action buttons
- screenshot save/cancel flow via `x-file` hint
- vesktop "View" opens the app directly

---

### deps

```bash
# core
quickshell niri foot fuzzel

# screenshots
grim slurp wl-clipboard

# audio
pipewire wireplumber

# network / bluetooth
networkmanager bluez

# wallpaper
swaybg

# misc
brightnessctl gcalcli curl
```

---

### install

```bash
git clone https://github.com/ks/shell ~/.config/quickshell
qs
```

profile pics are in `~/Documents/Medias/avatars/` or change the path in `bar/Bar.qml`.

wallpapers are loaded from `~/Documents/Medias/Wallpapers/` - change the path in `popup/dashboard/WallpaperPicker.qml`.

gcalcli needs to be authenticated (`gcalcli init`) for the schedule and events widgets to work.

---

### structure

```
quickshell/
├── shell.qml
├── themes/
│   ├── Colors.qml          // color palette
│   └── Glyphs.qml          // icons from the custom gwnce font
├── bar/
│   ├── Bar.qml
│   ├── Clock.qml           // date, time, inline weather
│   ├── StatusWidget.qml    // volume + battery
│   ├── Workspaces.qml
│   ├── Windows.qml
│   ├── SearchBtn.qml
│   ├── SystrayBtn.qml
│   └── Keyboard.qml
└── popup/
    ├── date/
    │   ├── DatePanel.qml
    │   ├── Calendar.qml
    │   ├── Weather.qml
    │   └── Events.qml      // today's gcalcli events
    ├── dashboard/
    │   ├── Dashboard.qml
    │   ├── UserCard.qml
    │   ├── NetworkPanel.qml
    │   ├── MediaPlayer.qml
    │   ├── AudioSliders.qml
    │   ├── WallpaperPicker.qml
    │   ├── WeekSchedule.qml
    │   ├── Quote.qml
    │   └── networkComp/
    │       ├── NetMenu.qml
    │       ├── BtMenu.qml
    │       ├── BtButton.qml
    │       └── PassInput.qml
    ├── notification/
    │   ├── Daemon.qml
    │   └── Toast.qml
    ├── Launcher.qml
    ├── SystrayMenu.qml
    └── VolumeOSD.qml
```

---

heavily inspired by [gwileful](https://github.com/sewergweller/gwileful), an awesomewm config i used for a long time before moving to niri. a lot of the ideas here, the widget layout, the dashboard structure, come directly from there. artwork i use as wallpapers is not mine.
