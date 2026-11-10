pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.theme
import qs.components
import qs.services

Scope {
  Variants {
    model: Quickshell.screens

    LockSnapshot {}
  }

  WlSessionLock {
    locked: SessionLock.sessionLocked
    onSecureChanged: SessionLock.setSecured(secure)

    WlSessionLockSurface {
      id: surface

      color: Theme.scrim

      LockSurface {
        anchors.fill: parent
        imageSize: Utility.pixelSize(surface.screen)
        onReady: SessionLock.surfaceReady(surface.screen?.name)
        wallpaper: WallpaperPublish.displayFile
        snapshot: SessionLock.snapshots[surface.screen?.name] ?? ""
        reveal: SessionLock.reveal
        interactive: SessionLock.phase === "locked"
        primary: surface.screen?.name === SessionLock.promptOutput
        avatar: WeebMode.avatar
        userName: Session.userName
        promptOpen: SessionLock.promptOpen
        busy: SessionLock.authenticating
        error: SessionLock.error
        firmwareAvailable: Session.firmwareAvailable
        onPromptRequested: SessionLock.openPrompt(surface.screen?.name)
        onPromptDismissed: SessionLock.closePrompt()
        onSubmitted: password => SessionLock.submit(password)
        onPowerRequested: action => Session.power(action)
      }
    }
  }
}
