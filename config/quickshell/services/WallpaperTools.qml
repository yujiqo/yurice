pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  readonly property string trashScript: '
    f="$1"
    T="${XDG_DATA_HOME:-$HOME/.local/share}/Trash"
    mkdir -p "$T/files" "$T/info" || exit 1
    base=$(basename "$f")
    stem="${base%.*}"
    ext="${base##*.}"
    name="$base"
    n=1
    while [ -e "$T/files/$name" ] || [ -e "$T/info/$name.trashinfo" ]; do
      name="$stem.$n.$ext"
      n=$((n + 1))
    done
    printf "[Trash Info]\\nPath=%s\\nDeletionDate=%s\\n" "$2" "$(date +%Y-%m-%dT%H:%M:%S)" > "$T/info/$name.trashinfo" || exit 1
    mv -- "$f" "$T/files/$name" || { rm -f "$T/info/$name.trashinfo"; exit 1; }
  '

  function trash(path) {
    if (path === Wallpapers.current) {
      const list = Wallpapers.wallpapers;
      const i = list.indexOf(path);
      const next = list[i + 1] ?? list[i - 1] ?? "";
      if (next !== "")
        Wallpapers.set(next);
    }
    const proc = trasher.createObject(root, {
      path: path
    });
    proc.running = true;
  }

  Component {
    id: trasher

    Process {
      id: proc

      property string path

      command: ["sh", "-c", root.trashScript, "sh", path, encodeURI(path)]
      onExited: code => {
        if (code === 0)
          Wallpapers.forgetResolution(proc.path);
        else
          console.warn("WallpaperTools: trash failed", proc.path);
        proc.destroy();
      }
    }
  }
}
