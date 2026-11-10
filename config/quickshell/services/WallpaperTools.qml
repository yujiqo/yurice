pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

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
    const dir = Paths.dirName(src);
    const name = Paths.baseName(src);
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

      command: ["sh", Paths.scripts + "/upscale-wallpaper.sh", src, dst, backup, String(scale), size]
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

      command: ["sh", Paths.scripts + "/trash.sh", path, encodeURI(path)]
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
