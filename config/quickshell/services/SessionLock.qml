pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import QtQuick
import qs.theme

Singleton {
  id: root

  property string phase: "idle"
  property real reveal: 0
  property bool secured: false
  property bool promptOpen: false
  property string promptOutput: ""
  property bool authenticating: false
  property string error: ""
  property var snapshots: ({})
  property var readySurfaces: ({})
  property bool firmwareAvailable: false
  property string pendingPassword: ""

  readonly property bool sessionLocked: phase === "locking" || phase === "locked" || phase === "unlocking"
  readonly property string userName: Quickshell.env("USER")
  readonly property string avatar: WeebMode.hidesAvatar ? Settings.normieAvatarPath : Settings.avatarPath

  function lock() {
    if (phase !== "idle")
      return;
    marker.setText("locked");
    Wallpapers.pickerOpen = false;
    snapshots = {};
    phase = "capturing";
    captureTimeout.restart();
  }

  function snapshotReady(output, url) {
    if (phase !== "capturing")
      return;
    const next = Object.assign({}, snapshots);
    next[output] = url;
    snapshots = next;
    if (Quickshell.screens.every(screen => snapshots[screen.name]))
      engage();
  }

  function engage() {
    if (phase !== "capturing")
      return;
    captureTimeout.stop();
    reveal = 0;
    readySurfaces = {};
    phase = "locking";
    readyTimeout.restart();
    tryReveal();
  }

  function setSecured(on) {
    secured = on;
    tryReveal();
  }

  function surfaceReady(output) {
    const next = Object.assign({}, readySurfaces);
    next[output] = true;
    readySurfaces = next;
    tryReveal();
  }

  function tryReveal() {
    if (secured && Quickshell.screens.every(screen => readySurfaces[screen.name]))
      startReveal();
  }

  function startReveal() {
    if (phase !== "locking" || revealAnim.running)
      return;
    readyTimeout.stop();
    revealAnim.stop();
    revealAnim.to = 1;
    revealAnim.start();
  }

  function openPrompt(output) {
    if (phase !== "locked" || authenticating)
      return;
    promptOutput = output;
    promptOpen = true;
  }

  function closePrompt() {
    if (authenticating)
      return;
    promptOpen = false;
    error = "";
  }

  function submit(password) {
    if (phase !== "locked" || authenticating)
      return;
    error = "";
    authenticating = true;
    pendingPassword = password;
    authTimeout.restart();
    if (!pam.start())
      failAuth("Can't check the password right now");
  }

  function failAuth(message) {
    authTimeout.stop();
    pendingPassword = "";
    authenticating = false;
    error = message;
  }

  function beginUnlock() {
    authTimeout.stop();
    pendingPassword = "";
    authenticating = false;
    error = "";
    promptOpen = false;
    phase = "unlocking";
    revealAnim.stop();
    revealAnim.to = 0;
    revealAnim.start();
  }

  function finishUnlock() {
    marker.setText("");
    phase = "idle";
    snapshots = {};
  }

  function power(action) {
    if (action === "firmware")
      Session.run("reboot", ["--firmware-setup"]);
    else
      Session.run(action);
  }

  NumberAnimation {
    id: revealAnim
    target: root
    property: "reveal"
    duration: Theme.animLock
    easing.type: Easing.InOutCubic
    onFinished: {
      if (root.phase === "locking")
        root.phase = "locked";
      else if (root.phase === "unlocking")
        root.finishUnlock();
    }
  }

  Timer {
    id: captureTimeout
    interval: 500
    onTriggered: root.engage()
  }

  Timer {
    id: authTimeout
    interval: 30000
    onTriggered: {
      pam.abort();
      root.failAuth("Can't check the password right now");
    }
  }

  Timer {
    id: readyTimeout
    interval: 1500
    onTriggered: root.startReveal()
  }

  PamContext {
    id: pam
    config: "login"
    onPamMessage: {
      if (responseRequired)
        respond(root.pendingPassword);
    }
    onCompleted: result => {
      if (result === PamResult.Success)
        root.beginUnlock();
      else
        root.failAuth("Wrong password");
    }
    onError: root.failAuth("Can't check the password right now")
  }

  FileView {
    id: marker
    path: `${Quickshell.env("XDG_RUNTIME_DIR")}/yurice-locked-${Quickshell.env("WAYLAND_DISPLAY")}`
    blockLoading: true
    blockWrites: true
    printErrors: false
  }

  Process {
    running: true
    command: ["test", "-d", "/sys/firmware/efi"]
    onExited: code => root.firmwareAvailable = code === 0
  }

  Timer {
    id: relockDelay
    interval: 6000
    onTriggered: {
      root.reveal = 1;
      root.phase = "locked";
    }
  }

  Timer {
    interval: 8000
    running: root.sessionLocked && !root.secured
    onTriggered: Quickshell.execDetached(["sh", Quickshell.shellDir + "/scripts/recover-session.sh", "-p", Quickshell.shellDir])
  }

  Component.onCompleted: {
    if (marker.text().trim() === "locked") {
      phase = "relocking";
      relockDelay.start();
    }
  }

  IpcHandler {
    target: "lock"

    function lock(): void {
      root.lock();
    }
    function isLocked(): bool {
      return root.sessionLocked;
    }
  }
}
