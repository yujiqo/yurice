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

  readonly property string upscaleScript: '
    src="$1"; dst="$2"; backup="$3"; scale="$4"; size="$5"
    tmp=$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/yurice-upscale.XXXXXX") || exit 1
    trap "rm -rf \\"$tmp\\"" EXIT
    magick "$src[0]" -strip "$tmp/in.png" || exit 1
    realesrgan-ncnn-vulkan -i "$tmp/in.png" -o "$tmp/out.png" -n realesr-animevideov3 -s "$scale" -t 128 || exit 1
    before=$(magick "$tmp/in.png" -format "%[fx:mean]" info:)
    after=$(magick "$tmp/out.png" -format "%[fx:mean]" info:)
    if awk -v a="$after" -v b="$before" "BEGIN { exit !(a < b * 0.6) }"; then
      echo "output looks corrupted (mean $after vs $before)" >&2
      exit 1
    fi
    magick "$tmp/out.png" -filter Lanczos -resize "$size^>" "$tmp/final.png" || exit 1
    mkdir -p "$(dirname "$backup")" || exit 1
    [ -e "$backup" ] && backup="${backup%.*}.$(date +%s).${backup##*.}"
    mv -- "$src" "$backup" || exit 1
    mv -- "$tmp/final.png" "$dst" || { mv -- "$backup" "$src"; exit 1; }
  '

  property list<string> queue: []
  property string active: ""
  property real progress: 0
  readonly property bool upscaling: active !== ""
  readonly property string status: {
    if (!upscaling)
      return "";
    const text = `Upscaling ${Math.floor(progress * 100)}%`;
    return queue.length > 0 ? `${text} · ${queue.length} queued` : text;
  }

  function isBusy(path) {
    return active === path || queue.includes(path);
  }

  function upscale(path) {
    if (isBusy(path) || !Wallpapers.canUpscale(path))
      return;
    queue = queue.concat([path]);
    startNext();
  }

  function startNext() {
    if (active !== "" || queue.length === 0)
      return;
    const src = queue[0];
    queue = queue.slice(1);
    const r = Wallpapers.resolutions[src];
    const target = Wallpapers.upscaleTarget;
    const scale = [2, 3].find(s => r.w * s >= target.width && r.h * s >= target.height) ?? 4;
    const dir = src.slice(0, src.lastIndexOf("/"));
    const name = src.slice(src.lastIndexOf("/") + 1);
    const stem = name.includes(".") ? name.slice(0, name.lastIndexOf(".")) : name;
    let dst = `${dir}/${stem}.png`;
    if (dst.toLowerCase() === src.toLowerCase())
      dst = `${dir}/${stem}-hd.png`;
    progress = 0;
    active = src;
    const proc = upscaler.createObject(root, {
      src: src,
      dst: dst,
      backup: `${dir}/.originals/${name}`,
      scale: scale,
      size: `${target.width}x${target.height}`
    });
    proc.running = true;
  }

  Component {
    id: upscaler

    Process {
      id: job

      property string src
      property string dst
      property string backup
      property int scale
      property string size
      property var errors: []

      command: ["sh", "-c", root.upscaleScript, "sh", src, dst, backup, String(scale), size]
      stderr: SplitParser {
        onRead: line => {
          const m = line.match(/^\s*(\d+(?:\.\d+)?)%\s*$/);
          if (m)
            root.progress = parseFloat(m[1]) / 100;
          else if (!line.startsWith("["))
            job.errors = job.errors.concat([line]).slice(-5);
        }
      }
      onExited: code => {
        if (code === 0) {
          Wallpapers.forgetResolution(job.src);
          const wasCurrent = Wallpapers.current === job.src;
          Wallpapers.moveSafe(job.src, job.dst);
          if (wasCurrent)
            Wallpapers.set(job.dst);
        } else {
          console.warn("WallpaperTools: upscale failed", job.src, job.errors.join("\n"));
        }
        root.active = "";
        job.destroy();
        root.startNext();
      }
    }
  }

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
        if (code === 0) {
          Wallpapers.forgetResolution(proc.path);
          Wallpapers.setSafe(proc.path, false);
        } else
          console.warn("WallpaperTools: trash failed", proc.path);
        proc.destroy();
      }
    }
  }
}
