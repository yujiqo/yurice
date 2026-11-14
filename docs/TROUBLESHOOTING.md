# Troubleshooting

When something looks wrong, start with the shell's log. Most problems leave a line there.

## Reading the logs

```sh
qs log              # the running shell's log
qs log -f           # keep following it
qs list             # is the shell running at all?
```

If you started it from niri (the default), niri's own output goes to the journal:

```sh
journalctl --user -b | grep -i niri
```

## The shell is gone or frozen

Restart it from a terminal (`Mod+T`):

```sh
qs kill; qs -d
```

`-d` runs it in the background, so you can close the terminal afterwards. If even that doesn't help, I prepared a harder reset that kills every instance and starts a fresh one:

```sh
sh ~/.config/quickshell/scripts/recover-session.sh
```

The lock screen runs this script by itself if it ever fails to lock properly, so you can't get stuck in front of a broken lock.

## Resetting state

Everything the shell _remembers_ is in `~/.local/state/yurice/`: the current wallpaper, theme, mode, launcher history and search filters. Your settings are in `custom/`, so deleting state never loses them:

```sh
rm -rf ~/.local/state/yurice/*.json
qs kill; qs -d
```

Don't delete `~/.local/state/yurice/installed` or `backup/` if you used `install.sh`, because `--uninstall` needs them.

Generated colors and thumbnails are in `~/.cache/yurice/` and can always be deleted.

## Colors didn't change with the wallpaper

The palette comes from matugen. Run it by hand to see the error:

```sh
qs ipc call wallpaper regenerate
qs log | grep -i matugen
```

If `~/.cache/yurice/colors.json` doesn't exist, the shell falls back to built-in colors. The usual cause is matugen missing from `PATH`.

## Wallpaper upscaling doesn't work

Upscaling uses `realesrgan-ncnn-vulkan`, which needs a working Vulkan driver:

```sh
command -v realesrgan-ncnn-vulkan   # is it installed?
vulkaninfo --summary                # does Vulkan see your GPU?
```

- If you installed with `--upscaler=none`, re-run `./install.sh desktop --upscaler=build` (Arch) or `--upscaler=release` (Debian, x86_64 only).
- Without a GPU driver, install your distro's Vulkan package (`vulkan-intel`, `vulkan-radeon`, `mesa-vulkan-drivers`, `nvidia-utils`…).
- If the result comes out black or broken, the script notices, and the original wallpaper is kept.

## Danbooru says something's wrong

The danbooru panel shows the reason:

| Message                                     | What to do                                                                                                    |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| _Wrong username or API key_                 | Check `~/.config/yurice/danbooru.key`: username on line 1, key on line 2, nothing else.                       |
| A permission error                          | The key needs `counts:posts`, `posts:index` and `users:profile` (see [CUSTOMIZING](CUSTOMIZING.md#api-keys)). |
| _Too many requests_                         | Wait a minute.                                                                                                |
| _No connection_ / _Danbooru is unavailable_ | The shell checks again every 30 seconds and comes back by itself.                                             |

If the island is missing completely, you're probably in the second mode, which hides it by default.

## Something is missing from the bar

An island can be hidden for four reasons:

- **You hid it** in the user panel's settings. It's in `hiddenIslands` in `settings.json`.
- **The current mode hides it.** Check the mode panel (`Mod+S`).
- **There's nothing to show.** The media island only appears while something is playing, and the battery island only on machines with a battery.

## The greeter doesn't start

Switch to a text console with `Ctrl+Alt+F2`, log in, and look at greetd:

```sh
journalctl -b -u greetd
```

To get your old login manager back:

- **Arch / Debian:** `./install.sh --uninstall` restores `/etc/greetd/config.toml` and re-enables the display manager that was there before. To remove only the greeter, disable greetd and enable your old one by hand (`sudo systemctl disable greetd && sudo systemctl enable gdm`, for example).
- **NixOS:** set `programs.yurice.greeter.enable = false;` and rebuild, or boot the previous generation.

If the greeter starts but at the wrong scale, see [CUSTOMIZING → The greeter](CUSTOMIZING.md#the-greeter).

## Nautilus can't open the trash or a drive

Nautilus needs gvfs for the trash, phones and network shares, udisks2 to see and mount drives, and a polkit agent to ask for your password when a partition needs it. Without the agent, those mounts fail with "Not authorized" and no prompt ever appears.

Check that the agent is running:

```sh
systemctl --user status yurice-polkit-agent            # Arch / Debian
systemctl --user status polkit-gnome-authentication-agent-1   # NixOS
```

- **Arch / Debian:** if `install.sh` warned that no polkit agent was found, install `polkit-gnome` (Arch) or `mate-polkit` (Debian) and run `./install.sh` again.
- **NixOS:** gvfs and udisks2 come from `programs.yurice.enable` and the agent from `programs.yurice.desktop.enable`, so make sure you didn't turn them off in your host config.

## Wrong shell in kitty

kitty reads the path to fish from `~/.config/kitty/kitty.local.conf`. Make sure it points at the real binary (`command -v fish`). See [CUSTOMIZING → The kitty quirk](CUSTOMIZING.md#the-kitty-quirk-kittylocalconf).

## Uninstalling

```sh
./install.sh --uninstall
```

This replays `~/.local/state/yurice/installed` backwards:

- removes every link, file and unit the installer created
- restores everything it backed up
- puts your greetd config and previous display manager back

Packages stay installed, because the script can't know which ones you already had. Your `~/.config/yurice/` (custom files and keys) is left alone too.

On NixOS, remove the `programs.yurice` options and the flake input, then rebuild.

## Still stuck?

Open an issue with:

- your distro
- how you installed: flake or `install.sh`, and with which components
- the relevant part of `qs log`
