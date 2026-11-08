import Quickshell
import Quickshell.Wayland
import QtQuick
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

      color: "black"

      LockSurface {
        anchors.fill: parent
        imageSize: surface.screen ? Qt.size(surface.screen.width * surface.screen.devicePixelRatio, surface.screen.height * surface.screen.devicePixelRatio) : Qt.size(0, 0)
        onReady: SessionLock.surfaceReady(surface.screen?.name)
        wallpaper: Wallpapers.current
        snapshot: SessionLock.snapshots[surface.screen?.name] ?? ""
        reveal: SessionLock.reveal
        interactive: SessionLock.phase === "locked"
        primary: surface.screen?.name === SessionLock.promptOutput
        avatar: SessionLock.avatar
        userName: SessionLock.userName
        promptOpen: SessionLock.promptOpen
        busy: SessionLock.authenticating
        error: SessionLock.error
        firmwareAvailable: SessionLock.firmwareAvailable
        onPromptRequested: SessionLock.openPrompt(surface.screen?.name)
        onPromptDismissed: SessionLock.closePrompt()
        onSubmitted: password => SessionLock.submit(password)
        onPowerRequested: action => SessionLock.power(action)
      }
    }
  }
}
