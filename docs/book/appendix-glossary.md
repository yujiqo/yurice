# Appendix: glossary

The terms this book uses, in alphabetical order, with the chapter that explains each one.

| Term                              | Meaning                                                                                                                                 | Chapter |
| --------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| `activeFocusOnTab`                | QML property that makes an item focusable. yurice's keyboard navigation collects every visible item that sets it.                       | 6, 12   |
| alias                             | A QML property that is another object's property, like `property alias text: label.text`.                                               | 2       |
| `available` / `ready`             | The flag a service exposes when its hardware or data might be missing, so modules can hide or dim.                                      | 7       |
| backdrop                          | niri's background behind workspaces in the overview. The wallpaper layer is placed in it by a layer rule.                               | 21      |
| `BarSlot`                         | A spring-driven wrapper that lets an island appear and disappear from the bar without its neighbours jumping.                           | 10      |
| base16                            | A 16-color scheme format (`base00` to `base0F`). matugen writes one for neovim.                                                         | 22      |
| binding                           | A property whose value is an expression. QML re-evaluates it whenever anything it reads changes. Assigning to the property removes it.  | 2       |
| `Behavior`                        | Makes a property animate whenever it changes. Used for short hover and color transitions.                                               | 2, 5    |
| cache                             | `~/.cache/yurice`: generated files that can always be rebuilt, like colors and thumbnails.                                              | 7       |
| cliphist                          | The clipboard history daemon behind `Mod+Y`.                                                                                            | 18      |
| `closeGrace`                      | The 400 ms an island waits after the mouse leaves before closing its panel.                                                             | 11      |
| component                         | A file in `components/`: a small reusable QML type that knows the theme but not the system.                                             | 1, 4    |
| `Component`                       | A QML recipe for objects that haven't been created yet. Island panels are `Component`s created by a `Loader`.                           | 11      |
| critically damped                 | A spring with damping ratio 1: it reaches the target as fast as possible without overshooting.                                          | 5       |
| custom                            | `~/.config/yurice/custom/`: your overrides, loaded last by every config. The installer only creates the empty folder.                   | 21, 22  |
| default property                  | The property that nested children go into, like `default property alias content: column.data`.                                          | 4, 5    |
| delay inhibitor                   | A systemd lock that makes logind wait a few seconds before sleeping. Used to lock the screen first.                                     | 20      |
| `dropdown`                        | The property on each bar that names its open panel, or `""`.                                                                            | 10, 11  |
| event stream                      | `niri msg --json event-stream`: niri's full state followed by one JSON line per change.                                                 | 8       |
| exclusive zone                    | The strip of screen a layer-shell surface reserves, which tiled windows stay out of.                                                    | 2, 10   |
| `ext-session-lock`                | The Wayland protocol for lock screens. If the locker crashes, the screen stays locked.                                                  | 20      |
| `FileView`                        | quickshell type that reads a file, and with `watchChanges`, re-reads it when it changes.                                                | 3, 7    |
| `FocusRing`                       | The ring drawn around the focused control. Shown only after a navigation key is pressed.                                                | 4, 12   |
| generation / request id           | A counter each request remembers, so answers that arrive after a newer request are dropped.                                             | 14      |
| greetd                            | The login daemon that runs yurice's greeter and then starts your session.                                                               | 20      |
| `handleNavKey`                    | The function in `Island.qml` that turns keys into focus movement, activation and adjustment.                                            | 12      |
| `hides*`                          | `WeebMode` properties that combine a hide flag with the current mode. What other services read.                                         | 16      |
| `host`                            | The bar an island belongs to. How an island reads `dropdown` and calls `request`.                                                       | 10, 11  |
| implicit size                     | `implicitWidth` and `implicitHeight`: how big an item wants to be, used when nobody sets a size.                                        | 2       |
| input mask                        | The region of a window that accepts input. Everything outside it passes through to what's below.                                        | 10      |
| `IpcHandler`                      | quickshell type that exposes typed functions to `qs ipc call`.                                                                          | 9       |
| island                            | A rounded pill on the bar that grows into its panel.                                                                                    | 10, 11  |
| `JsonAdapter`                     | Maps a JSON file's keys onto QML properties, both ways. Used for the palette and for state.                                             | 3, 7    |
| `keepOpen`                        | Property a panel sets while it's busy, so its island doesn't close on mouse leave.                                                      | 11      |
| keyboard contract                 | `activeFocusOnTab`, `FocusRing`, `keyActivate`/`clicked` and `keyAdjust`. Follow it and a component works with the keyboard everywhere. | 6       |
| KDL                               | The config language niri uses.                                                                                                          | 9, 21   |
| `KeyFile`                         | Component that reads a key file as lines and writes it with umask 077.                                                                  | 7, 14   |
| layer shell                       | Wayland protocol that lets shell windows sit on a layer (background, bottom, top, overlay), anchor to edges and reserve space.          | 2       |
| `Loader`                          | Creates its content only while `active` is true. Panels exist only while open.                                                          | 2, 11   |
| manifest                          | `~/.local/state/yurice/installed`: every change `install.sh` made, used by `--uninstall`.                                               | 23      |
| matugen                           | Generates a Material You palette from an image and fills templates with it.                                                             | 1, 3    |
| `mkOutOfStoreSymlink`             | home-manager helper that links to a live folder instead of the Nix store. Used when `configDir` is a string.                            | 23      |
| modelData                         | The item a `Repeater` or `Variants` hands each copy. In `Bar.qml` it's the screen.                                                      | 2       |
| module                            | A file in `modules/`: the actual UI, built from components and services.                                                                | 1       |
| namespace                         | The name a layer-shell window gives itself, like `yurice-wallpaper`. niri rules match on it.                                            | 17, 21  |
| normie / weeb                     | The default names of the second and first mode. Both can be renamed.                                                                    | 16      |
| `notifyLocal`                     | Adds a shell toast. Repeats with the same key replace each other.                                                                       | 18      |
| PAM                               | The system authentication library. The lock screen checks passwords through it.                                                         | 20      |
| panel                             | The content an island grows to show.                                                                                                    | 11      |
| `Panels`                          | Service holding the panel opened by keybind, and the monitor it was opened on.                                                          | 9       |
| post hook                         | A command matugen runs after writing a template, to tell the program to reload.                                                         | 3       |
| `pragma ComponentBehavior: Bound` | Stricter id scoping, at the top of every file. Delegates must declare `required` properties.                                            | 2       |
| `progress`                        | A spring's value clamped to 0–1, safe for opacity.                                                                                      | 5       |
| `qs`                              | The quickshell command. `qs ipc call` runs IPC functions, `qs log` shows logs.                                                          | 9       |
| `.qsb`                            | A compiled Qt shader, made from a `.frag` file by `shaders/build.sh`.                                                                   | 4, 24   |
| `Region`                          | quickshell type describing part of a window, used for input masks.                                                                      | 10      |
| `Reveal` / `Collapse`             | Components that show content by springing its width or height.                                                                          | 5       |
| role                              | A Material You color named by purpose, like `surface` or `primary`, rather than by look.                                                | 3       |
| `ScreencopyView`                  | quickshell type that shows a capture of a screen. Used for screenshots and the lock transition.                                         | 19, 20  |
| segment                           | One part of a multi-part island, like the volume half of the levels island.                                                             | 13      |
| semantic alias                    | A theme color named after a thing, like `Theme.wifi`, defined as a role.                                                                | 3       |
| service                           | A singleton in `services/` that knows one thing about the system and offers functions to change it.                                     | 7       |
| settings                          | `custom/quickshell/settings.json`: your preferences, editable by hand or in the user panel.                                             | 7, 15   |
| shared                            | `/var/lib/yurice`: files your session publishes for the greeter.                                                                        | 17, 20  |
| signal                            | A QML announcement, handled with `on<Signal>`. Every property has a `<name>Changed` signal.                                             | 2       |
| singleton                         | A QML type with exactly one instance, used by name. The theme and every service are singletons.                                         | 2       |
| `SplitParser`                     | Hands a process's output to you one line at a time, as it arrives.                                                                      | 8       |
| `Spring`                          | yurice's critically damped spring, simulated in 1 ms steps and slowed by niri's `slowdown`.                                             | 5       |
| state                             | `~/.local/state/yurice/*.json`: what the shell remembers. Safe to delete.                                                               | 7       |
| `StdioCollector`                  | Collects a process's whole output and hands it to you when the process ends.                                                            | 7       |
| token                             | A named design decision in `Theme.qml`, like `panelRadius` or `animHover`.                                                              | 3       |
| `Variants`                        | Makes one copy of its child per item, usually one per screen.                                                                           | 2       |
| `vim.pack`                        | neovim 0.12's built-in plugin manager, with a committed lock file.                                                                      | 22      |
| xwayland-satellite                | Runs X11 apps under niri.                                                                                                               | 21      |
