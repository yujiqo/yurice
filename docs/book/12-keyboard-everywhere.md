# 12. Keyboard everywhere

Every panel in yurice works without a mouse. `Tab` and `Shift+Tab` cycle through controls, `hjkl` and the arrows move in a direction, `Enter` and `Space` activate, `←` and `→` adjust sliders, and `Esc` closes. Panels don't implement it themselves. It lives in about 150 lines of [`components/Island.qml`](../../config/quickshell/components/Island.qml), on top of the keyboard contract from chapter 6.

## Getting the keys at all

Chapter 2 showed this line in the bar:

```qml
  WlrLayershell.keyboardFocus: dropdown !== "" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
```

[`modules/bar/Bar.qml:104`](../../config/quickshell/modules/bar/Bar.qml#L104)

A layer-shell surface doesn't get keyboard input unless it asks. The bar asks for exclusive focus only while a panel is open, and gives it back when the panel closes, so you're never typing into a bar you can't see.

Inside the window, Qt sends each key press to the item with active focus. If that item doesn't accept the event, it goes to its parent, then that parent's parent, and so on up the tree. The island puts its handler on `panelArea`, the item wrapping the panel, so it sees every key the panel's own controls didn't want:

```qml
  Item {
    id: panelArea
    ...
    focus: true
    ...
    Keys.onPressed: event => event.accepted = root.handleNavKey(event)
    Keys.onEscapePressed: root.dismissed()
```

[`components/Island.qml:318-331`](../../config/quickshell/components/Island.qml#L318-L331)

When the island opens, it gives `panelArea` focus:

```qml
  onOpenChanged: {
    if (open)
      panelArea.forceActiveFocus();
  }
```

[`components/Island.qml:268-271`](../../config/quickshell/components/Island.qml#L268-L271)

`panelArea` isn't one of the focusable controls, so nothing has a focus ring yet. That's why mouse users never see one (chapter 4). The ring only appears once you press a navigation key and focus moves onto an actual control.

`Esc` is handled by `onEscapePressed`. `handleNavKey` returns false for it, which leaves the event unaccepted, and Qt then calls the more specific handler. It dismisses the island, which clears the bar's `dropdown` and closes the panel.

## The dispatcher

`handleNavKey` turns a key into an intent:

```qml
  function handleNavKey(event) {
    if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
      return false;
    let dx = 0;
    let dy = 0;
    switch (event.key) {
    case Qt.Key_H:
    case Qt.Key_Left:
      dx = -1;
      break;
    ...
    case Qt.Key_Tab:
      return cycleFocus(1);
    case Qt.Key_Backtab:
      return cycleFocus(-1);
    case Qt.Key_Return:
    case Qt.Key_Enter:
    case Qt.Key_Space:
      return activateFocused();
    default:
      return false;
    }
    const item = focusedItem();
    if (dx !== 0 && item?.keyAdjust) {
      item.keyAdjust(dx);
      return true;
    }
    moveFocus(dx, dy, true);
    return true;
  }
```

[`components/Island.qml:154-194`](../../config/quickshell/components/Island.qml#L154-L194)

Keys with `Ctrl`, `Alt` or `Super` are left alone, so niri's shortcuts and panels' own shortcuts (like `Ctrl+D` in the cheatsheet) still work. A horizontal key on something with `keyAdjust`, such as a slider, adjusts it instead of moving away. Everything else becomes a direction.

## Finding the controls

Every navigation step starts by collecting what can be focused:

```qml
  function navTargets(node, found) {
    for (const child of node.children) {
      if (!child.visible || !child.enabled || child.opacity <= 0)
        continue;
      if (child.activeFocusOnTab)
        found.push(child);
      navTargets(child, found);
    }
    return found;
  }
```

[`components/Island.qml:47-56`](../../config/quickshell/components/Island.qml#L47-L56)

It walks the panel's item tree and keeps every visible, enabled item that set `activeFocusOnTab: true`. Hidden branches are skipped whole. That matters because panels hide things all the time: a collapsed section, an inactive tab fading out, a control at opacity 0. An item you can't see is never a target.

The list is built fresh on every key press. Nothing is registered or kept in sync, so a panel can add and remove controls freely, and a new component that follows the contract is reachable the moment it exists.

`Tab` uses the list in tree order:

```qml
  function cycleFocus(delta) {
    const targets = navTargets(panelLoader, []);
    if (targets.length === 0)
      return false;
    const index = targets.indexOf(focusedItem());
    focusOn(targets[index < 0 ? 0 : (index + delta + targets.length) % targets.length]);
    return true;
  }
```

[`components/Island.qml:132-139`](../../config/quickshell/components/Island.qml#L132-L139)

It wraps around at both ends. If nothing is focused yet, the first press lands on the first control.

## Moving in a direction

`hjkl` is harder. "The control to the right" depends on layout, not on tree order. `moveFocus` measures it:

```qml
    const origin = centerOf(from);
    let best = null;
    let bestScore = Infinity;
    for (const target of targets) {
      if (target === from)
        continue;
      const center = centerOf(target);
      const along = (center.x - origin.x) * dx + (center.y - origin.y) * dy;
      if (along < 2)
        continue;
      const across = Math.abs((center.x - origin.x) * dy) + Math.abs((center.y - origin.y) * dx);
      const score = along + across * 3;
      if (score < bestScore) {
        best = target;
        bestScore = score;
      }
    }
```

[`components/Island.qml:103-119`](../../config/quickshell/components/Island.qml#L103-L119)

For each candidate, it takes the vector from the focused control's center to the candidate's center. `along` is how far it is in the direction you pressed, and anything not at least 2 pixels ahead is ignored. `across` is how far it is off to the side. The score adds them, with sideways distance counting three times as much, and the lowest score wins.

The weight of 3 is what makes it feel right. Press `j` in a grid of wallpapers and you want the one directly below, even if a thumbnail diagonally below is a few pixels closer. Sideways drift is expensive, so straight down wins.

`centerOf` maps each item's center into `panelArea`'s coordinates, so it doesn't matter how deeply a control is nested.

### Scrolling to it

Long panels scroll, and moving focus onto a control half outside the view isn't enough. `focusOn` also reveals it:

```qml
  function reveal(item) {
    const scroller = scrollerOf(item);
    if (!scroller)
      return;
    const top = item.mapToItem(scroller.contentItem, 0, 0).y;
    if (top < scroller.contentY)
      scroller.contentY = top;
    else if (top + item.height > scroller.contentY + scroller.height)
      scroller.contentY = top + item.height - scroller.height;
  }
```

[`components/Island.qml:79-88`](../../config/quickshell/components/Island.qml#L79-L88)

`scrollerOf` walks up from the item until it finds something with `contentY`, which is any `Flickable` or `ListView`. The scroller moves just enough to show the item, and no further.

There's one more case. In a long list, the next row down may not exist yet, because a `ListView` only creates the delegates on screen. When `moveFocus` finds nothing below, it scrolls by one row and tries again on the next frame with `Qt.callLater`, after the new row has been created:

```qml
    const scroller = scrollerOf(from);
    if (scroller && dy !== 0 && canScroll) {
      scroller.contentY = Math.max(0, Math.min(scroller.contentHeight - scroller.height, scroller.contentY + dy * from.height));
      Qt.callLater(moveFocus, dx, dy, false);
    }
```

[`components/Island.qml:124-128`](../../config/quickshell/components/Island.qml#L124-L128)

`canScroll` is false on the retry, so it can't loop.

## Activating

```qml
  function activateFocused() {
    const item = focusedItem();
    if (!item || !item.activeFocusOnTab)
      return false;
    if (item.keyActivate)
      item.keyActivate();
    else if (item.clicked)
      item.clicked();
    else
      return false;
    return true;
  }
```

[`components/Island.qml:141-152`](../../config/quickshell/components/Island.qml#L141-L152)

This is the other half of the contract from chapter 6. Most buttons only have a `clicked` signal, and `Enter` emits it exactly as a mouse click would, so the panel's `onClicked` handler runs either way. Components where a click means something more specific define `keyActivate`: the switch toggles, a choice group selects the focused option.

## Text fields

A text field is the hard case, since it needs most keys for typing. Chapter 6 covered the two ways [`TextField`](../../config/quickshell/components/TextField.qml) hands keys back. Here's how `escapeLeaves` cooperates with the island.

The text field is a rectangle with a `TextInput` inside. With `escapeLeaves: true`, the outer rectangle is focusable and the inner input isn't. `Tab` lands on the rectangle and shows its ring, and `Enter` calls its `keyActivate`, which focuses the input so you can type. While typing, `Esc` moves focus back to the rectangle instead of closing the panel. The arrows and `Tab` do the same, and they leave the event unaccepted, so it bubbles up to `handleNavKey` and focus moves on as if you'd never been typing.

The launcher works differently. It's a search box first, so its input keeps focus the whole time and its `navigate` signal moves the selection in the results list while you type.

## Panels that do their own thing

A panel can always handle keys before the island does, since the island only sees what the panel lets through. The cheatsheet (chapter 9) is a long read-only list with nothing focusable, so it takes focus itself and turns `j`, `k`, `Ctrl+D`, `Ctrl+U`, `g` and `G` into scrolling. The power menu keeps its own selection and moves it with `h`, `l`, the arrows and `Tab`, and the clipboard deletes an entry with `Shift+Delete`. The island's navigation is the default, and any panel can override any key.

The bar is now complete as a frame: islands, panels and the keys that drive them. The next chapters go through the islands one by one, starting with the ones that watch your own machine.
