# 13. System islands

With the frame done, the islands themselves are short. Most are a service from Part II, a few `Segment`s and `Reveal`s from Part I, and a panel made of building blocks. This chapter goes through the islands that watch your own machine and points out what each one adds that the others don't.

## Segments

Several islands are made of more than one part: levels has brightness and volume, connectivity has network and Bluetooth, battery has charge and power profile. Each part is a [`Segment`](../../config/quickshell/components/Segment.qml): an icon, a label that reveals when the island is expanded, its own hover pill, and its own click and wheel signals.

Islands that show a segment pick its icon, label and color in one binding, using two helpers from [`components/Utility.qml`](../../config/quickshell/components/Utility.qml). `Utility.seg(icon, label, color)` just bundles the three into an object. `Utility.pick(value, steps, fallback)` returns the result for the first threshold the value reaches:

```qml
Utility.pick(percent, [[66, "volume_up"], [33, "volume_down"]], "volume_mute")
```

That reads as "66 or more is `volume_up`, 33 or more is `volume_down`, anything else is `volume_mute`". Battery icons, Wi-Fi bars, brightness icons and battery colors are all written this way.

Between segments sits a `Divider` with `shown: root.expanded`. It's barely there while the island is a pill and opens up with the rest of the island on hover.

## Workspaces

[`modules/bar/Workspaces.qml`](../../config/quickshell/modules/bar/Workspaces.qml) draws one dot per workspace on its own monitor. The active one is wider, occupied ones are brighter, and urgent ones turn the error color.

Chapter 8 mentioned that the dots come from a `ListModel` that `sync()` keeps in step with `Niri.workspaces`, instead of a `Repeater` over the array. Here's why:

```qml
      add: Transition {
        NumberAnimation {
          properties: "opacity,scale"
          from: 0
          to: 1
          duration: Theme.animMove
          easing.type: Easing.OutBack
        }
      }
      remove: Transition {
        NumberAnimation {
          properties: "opacity,scale"
          to: 0
          duration: Theme.animRemove
          easing.type: Easing.InCubic
        }
      }
```

[`modules/bar/Workspaces.qml:162-178`](../../config/quickshell/modules/bar/Workspaces.qml#L162-L178)

A `ListView` can animate rows that are added, removed or moved, but only if it's told which ones. Replacing an array tells it nothing, so every dot would be destroyed and rebuilt. `sync()` compares by workspace id and calls `insert`, `move`, `set` and `remove` on the model, so niri creating a new empty workspace makes exactly one dot pop in.

The hover pill is shared. Instead of one `HoverHighlight` per dot, there's a single one that slides to whichever dot is hovered, which makes moving along the row feel continuous.

## Connectivity

[`ConnectivityIsland.qml`](../../config/quickshell/modules/bar/ConnectivityIsland.qml) shows a segment per active network connection (wired, Wi-Fi, or "Offline" if there's neither) and one for Bluetooth. Each opens its own panel in the same island.

The [Wi-Fi panel](../../config/quickshell/modules/bar/WifiPanel.qml) is the clearest example of the panel lifetime from chapter 11:

```qml
  Component.onCompleted: {
    Network.setScanning(true);
    refreshNetworks();
    startScan();
  }
  Component.onDestruction: Network.setScanning(false)
```

Scanning for networks wakes the Wi-Fi radio and costs battery, so it only runs while the list is on screen. The panel shows a spinner until the list grows or six seconds pass, whichever comes first. Secured networks ask for a password inline with a [`PasswordField`](../../config/quickshell/components/PasswordField.qml), and the panel sets `keepOpen` while you type so the island doesn't close under you.

The [Bluetooth panel](../../config/quickshell/modules/bar/BluetoothPanel.qml) does the same with device discovery. Pairing needs one more piece: something has to answer BlueZ when a device asks "do you accept this pairing?". [`services/BluetoothAgent.qml`](../../config/quickshell/services/BluetoothAgent.qml) runs `bluetoothctl` as an agent and answers its prompts:

```qml
  Process {
    id: proc
    command: ["bluetoothctl", "--agent", "NoInputNoOutput"]
    stdinEnabled: true
    onRunningChanged: {
      if (running)
        write("default-agent\n");
      else if (root.users > 0)
        running = true;
    }
    stdout: SplitParser {
      splitMarker: "(yes/no)"
      onRead: {
        if (proc.running)
          proc.write(root.accept ? "yes\n" : "no\n");
      }
    }
  }
```

[`services/BluetoothAgent.qml:25-42`](../../config/quickshell/services/BluetoothAgent.qml#L25-L42)

`SplitParser` normally splits on newlines, but `bluetoothctl` prompts end in `(yes/no)` with no newline after them. Splitting on that marker makes each prompt arrive as one read, which gets answered on stdin. The agent is reference counted with `acquire()` and `release()`, so it only runs while a Bluetooth panel is open, and it's restarted if it dies while still needed. The panel binds `accept` to whether any listed device is in the middle of pairing, so the agent says no to anything else.

## Levels

[`LevelsIsland.qml`](../../config/quickshell/modules/bar/LevelsIsland.qml) has a brightness segment (on machines with a backlight) and a volume segment. Scrolling over a segment changes it in steps of 5%, and right-clicking volume mutes. Chapter 11 showed how it flashes its panel when a level changes from somewhere else.

Its panel is the smallest in yurice, one row with a mute button, a slider and a percentage, used for both levels:

```qml
  Slider {
    ...
    accent: root.accent
    glide: true
    value: root.value
    onMoved: v => root.isVolume ? Audio.setVolume(v) : Brightness.set(v)
  }
```

[`modules/bar/LevelsPanel.qml:29-39`](../../config/quickshell/modules/bar/LevelsPanel.qml#L29-L39)

`value` comes from the service and `onMoved` goes back to it, the one-source-of-truth loop from chapters 6 and 7.

The volume segment also notices wired headphones. [`Audio.wiredHeadphones`](../../config/quickshell/services/Audio.qml) checks the default sink's PipeWire properties for an ALSA device whose icon or name says headphones, and the island swaps the speaker icon for a headphones one.

## Battery

The battery island is only on the bar if `Battery.available`, so desktops never see it. It shows the charge, a coffee cup while caffeine is on, and the power profile when expanded. Right-clicking cycles through power profiles without opening anything:

```qml
  function cycleProfile(step) {
    const i = profiles.indexOf(PowerProfiles.profile);
    PowerProfiles.profile = profiles[(i + step + profiles.length) % profiles.length];
  }
```

[`modules/bar/BatteryIsland.qml:24-27`](../../config/quickshell/modules/bar/BatteryIsland.qml#L24-L27)

`PowerProfiles` comes straight from quickshell's UPower module, and `profiles` only includes performance on machines that support it. Chapter 6 read the battery panel in full.

## Time and calendar

The clock island shows the time, and the date on hover (chapter 5's `Reveal` example). The time format comes from `Clock.timeFormat`, which is copied from `Settings` in the middle of a fade (chapter 7), so switching to 12-hour time fades the old text out and the new one in.

The [calendar panel](../../config/quickshell/modules/bar/CalendarPanel.qml) builds its grid from three numbers:

```qml
  readonly property int offset: (new Date(year, month, 1).getDay() + 6) % 7
  readonly property int daysInMonth: new Date(year, month + 1, 0).getDate()
  readonly property int cellCount: Math.ceil((offset + daysInMonth) / 7) * 7
```

[`modules/bar/CalendarPanel.qml:13-15`](../../config/quickshell/modules/bar/CalendarPanel.qml#L13-L15)

JavaScript's `getDay()` counts from Sunday, and `+ 6) % 7` turns it into Monday first. Day 0 of the next month is the last day of this one, which is a standard trick for getting the month's length. A `Repeater` then makes `cellCount` cells, and each cell works out its own date from its index, so days from the previous and next months fill the edges.

Scrolling changes the month. Moving by a month slides the grid sideways, and moving by a year or more slides it vertically, so you can tell which kind of jump just happened.

## Media

The media island is three small bars that bounce while something plays, plus the artist and title on hover. It only appears when [`Media.active`](../../config/quickshell/services/Media.qml) has a player.

The [media panel](../../config/quickshell/modules/bar/MediaPanel.qml) is the biggest in this chapter, mostly because of the record. It has two `Disc`s and swaps them when the track changes: the old one grows and fades out, and the new one, with the new cover already loaded, pops in after a short pause. The swap waits until the new art is ready or two seconds have passed, which is the same reasoning as the two covers inside `Disc` from chapter 4, one level up.

The disc spins while music plays, speeding up and slowing down smoothly instead of starting and stopping. You can also grab it and turn it to seek, 30 seconds per full turn:

```qml
      onPositionChanged: event => {
        if (!root.scrubbing)
          return;
        const a = angleAt(event.x, event.y);
        let delta = a - lastAngle;
        if (delta > 180)
          delta -= 360;
        else if (delta < -180)
          delta += 360;
        lastAngle = a;
        root.scrubTurns += delta / 360;
        root.front.angle = (root.front.angle + delta) % 360;
      }
```

[`modules/bar/MediaPanel.qml:288-300`](../../config/quickshell/modules/bar/MediaPanel.qml#L288-L300)

The angle is measured from the disc's center. The `±360` correction handles the jump where `atan2` wraps from 180° to -180°, so turning past that point doesn't look like a full turn backwards. The seek happens on release, and while you scrub the panel sets `keepOpen`.

One more detail: MPRIS players don't send position updates while playing, so the panel asks for the position every 500 ms. After a seek, it ignores reported positions that are still far from the target for up to six seconds, because some players keep reporting the old position for a moment and the progress bar would jump back.

When more than one player is running, a row of chips at the bottom lets you pick which one the island follows.

These islands all watch the machine you're sitting at. The next ones reach out to the internet.
