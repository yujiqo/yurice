# Keybinds

Press `Mod+Shift+/` to check keybinds! Every bind lives in [`config/niri/modules/binds.kdl`](../config/niri/modules/binds.kdl). The in-shell cheatsheet is generated from that same file, so if you change a bind there, the cheatsheet updates by itself.

`Mod` is the Super / Windows key.

## Changing binds

Don't edit `binds.kdl` in the repo. Put your changes in `~/.config/yurice/custom/niri/config.kdl`, which niri loads last:

```kdl
binds {
  Mod+Return { spawn "kitty"; }
}
```

> [!NOTE]
> The cheatsheet only reads `~/.config/niri/modules/binds.kdl`, so binds you add in `custom/` work but don't show up in it. I think it's one of the next features to implement, if people'll ask for this.
