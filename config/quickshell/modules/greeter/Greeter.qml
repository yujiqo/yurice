pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.theme
import qs.components
import qs.services
import qs.modules.lock

Scope {
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: window

      required property ShellScreen modelData
      screen: modelData

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.namespace: "yurice-greeter"
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
      color: Theme.scrim

      LockSurface {
        anchors.fill: parent
        imageSize: Utility.pixelSize(window.modelData)
        wallpaper: GreeterSession.wallpaper
        reveal: GreeterSession.reveal
        interactive: GreeterSession.phase === "ready"
        primary: window.modelData.name === GreeterSession.promptOutput
        avatar: GreeterSession.avatar
        userName: GreeterSession.userName
        promptOpen: GreeterSession.promptOpen
        placeholder: GreeterSession.placeholder
        busy: GreeterSession.authenticating
        error: GreeterSession.error
        firmwareAvailable: Session.firmwareAvailable
        canSwitchUser: GreeterSession.users.length > 1
        onReady: GreeterSession.surfaceReady(window.modelData.name)
        onPromptRequested: GreeterSession.openPrompt(window.modelData.name)
        onPromptDismissed: GreeterSession.closePrompt()
        onSubmitted: password => GreeterSession.submit(password)
        onPowerRequested: action => Session.power(action)
        onUserSwitchRequested: delta => GreeterSession.switchUser(delta)
      }
    }
  }
}
