pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import QtQuick
import qs.theme

Singleton {
  id: root

  readonly property string stateRoot: Quickshell.env("YURICE_STATE_ROOT") || "/var/lib/yurice"
  readonly property var sessionCommand: ["sh", `${Quickshell.shellDir}/scripts/start-session.sh`].concat((Quickshell.env("YURICE_SESSION") || "niri-session").split(" "))

  property string phase: "waiting"
  property real reveal: 0
  property bool promptOpen: false
  property string promptOutput: ""
  property string placeholder: "Password"
  property bool authenticating: false
  property string error: ""
  property string pendingPassword: ""
  property bool passwordSent: false
  property int selected: Math.max(0, users.indexOf(lastUser.text().trim()))
  property var readySurfaces: ({})
  property int pendingSwitch: 0
  property bool firmwareAvailable: false

  readonly property var users: {
    const list = [];
    for (const line of passwd.text().split("\n")) {
      const fields = line.split(":");
      const uid = parseInt(fields[2]);
      if (fields.length < 7 || uid < 1000 || uid >= 60000 || /(nologin|false)$/.test(fields[6]))
        continue;
      list.push(fields[0]);
    }
    return list.sort();
  }
  readonly property string userName: users[selected] ?? ""
  readonly property string userDir: `${stateRoot}/users/${userName}`
  readonly property string wallpaper: userName === "" ? "" : `${userDir}/wallpaper.jpg`
  readonly property string avatar: userName === "" ? "" : `${userDir}/avatar.jpg`

  onUserDirChanged: Theme.paletteFile = `${userDir}/colors.json`
  Component.onCompleted: {
    Theme.paletteFile = `${userDir}/colors.json`;
    readyTimeout.start();
  }

  function surfaceReady(output) {
    const next = Object.assign({}, readySurfaces);
    next[output] = true;
    readySurfaces = next;
    if (Quickshell.screens.every(screen => readySurfaces[screen.name]))
      show();
  }

  function show() {
    if (phase !== "waiting")
      return;
    readyTimeout.stop();
    phase = "showing";
    animate(1);
  }

  function animate(to) {
    revealAnim.stop();
    revealAnim.to = to;
    revealAnim.start();
  }

  function openPrompt(output) {
    if (phase !== "ready" || authenticating)
      return;
    promptOutput = output;
    promptOpen = true;
  }

  function closePrompt() {
    if (authenticating)
      return;
    promptOpen = false;
    error = "";
    placeholder = "Password";
    if (Greetd.state !== GreetdState.Inactive)
      Greetd.cancelSession();
  }

  function switchUser(delta) {
    if (phase !== "ready" || authenticating || users.length < 2)
      return;
    closePrompt();
    pendingSwitch = delta;
    phase = "switching";
    animate(0);
  }

  function submit(password) {
    if (phase !== "ready" || authenticating)
      return;
    error = "";
    authenticating = true;
    pendingPassword = password;
    if (Greetd.state === GreetdState.Authenticating) {
      respond();
      return;
    }
    passwordSent = false;
    Greetd.createSession(userName);
  }

  function respond() {
    const value = pendingPassword;
    pendingPassword = "";
    passwordSent = true;
    Greetd.respond(value);
  }

  function failAuth(message) {
    pendingPassword = "";
    authenticating = false;
    placeholder = "Password";
    error = message;
  }

  function power(action) {
    const args = action === "firmware" ? ["reboot", "--firmware-setup"] : [action];
    powerProcess.command = ["systemctl"].concat(args);
    powerProcess.running = true;
  }

  Connections {
    target: Greetd
    function onAuthMessage(message, isError, responseRequired, echoResponse) {
      if (!responseRequired) {
        if (isError)
          root.error = message;
        Greetd.respond("");
        return;
      }
      if (!root.passwordSent) {
        root.respond();
        return;
      }
      root.authenticating = false;
      root.placeholder = message.trim() || "Password";
    }
    function onAuthFailure(message) {
      if (Greetd.state !== GreetdState.Inactive)
        Greetd.cancelSession();
      root.failAuth("Wrong password");
    }
    function onError(message) {
      root.failAuth("Can't log in right now");
    }
    function onReadyToLaunch() {
      lastUser.setText(root.userName);
      root.authenticating = false;
      root.promptOpen = false;
      root.phase = "leaving";
      root.animate(0);
    }
  }

  NumberAnimation {
    id: revealAnim
    target: root
    property: "reveal"
    duration: Theme.animLock
    easing.type: Easing.InOutCubic
    onFinished: {
      if (root.phase === "showing") {
        root.phase = "ready";
      } else if (root.phase === "leaving") {
        Greetd.launch(root.sessionCommand);
      } else if (root.phase === "switching") {
        root.selected = (root.selected + root.pendingSwitch + root.users.length) % root.users.length;
        root.readySurfaces = {};
        root.phase = "waiting";
        readyTimeout.restart();
      }
    }
  }

  Timer {
    id: readyTimeout
    interval: 2000
    onTriggered: root.show()
  }

  Process {
    id: powerProcess
  }

  Process {
    running: true
    command: ["test", "-d", "/sys/firmware/efi"]
    onExited: code => root.firmwareAvailable = code === 0
  }

  FileView {
    id: passwd
    path: Quickshell.env("YURICE_PASSWD") || "/etc/passwd"
    blockLoading: true
    printErrors: false
  }

  FileView {
    id: lastUser
    path: `${root.stateRoot}/greeter/last-user`
    blockLoading: true
    blockWrites: true
    printErrors: false
  }
}
