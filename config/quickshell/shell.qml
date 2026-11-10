pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import qs.services
import qs.modules.bar
import qs.modules.wallpaper
import qs.modules.lock
import qs.modules.screenshot

ShellRoot {
  settings.watchFiles: !SessionLock.sessionLocked

  Component.onCompleted: {
    Keyboard.watch();
    WallpaperPublish.schedule();
  }

  Variants {
    model: Quickshell.screens

    Wallpaper {}
  }

  WallpaperPicker {}

  LockScreen {}

  SessionIntro {}

  SessionOutro {}

  Variants {
    model: Quickshell.screens

    ScreenshotOverlay {}
  }

  Variants {
    model: Quickshell.screens

    DisplayConfirm {}
  }

  Variants {
    model: Quickshell.screens

    Bar {}
  }
}
