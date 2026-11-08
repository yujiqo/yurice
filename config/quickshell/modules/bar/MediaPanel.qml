import QtQuick
import qs.theme
import qs.components
import qs.services

Column {
  id: root

  readonly property var player: Media.active
  readonly property bool playing: player?.isPlaying ?? false
  readonly property real length: player?.length ?? 0
  readonly property bool canSeek: (player?.canSeek ?? false) && length > 0
  readonly property real secondsPerTurn: 30
  readonly property string trackKey: player ? `${player.dbusName}|${player.trackTitle}|${player.trackArtist}` : ""

  property real position: 0
  property bool scrubbing: false
  property real scrubStart: 0
  property real scrubTurns: 0
  readonly property real scrubPosition: Math.max(0, Math.min(length, scrubStart + scrubTurns * secondsPerTurn))
  readonly property real shownPosition: scrubbing ? scrubPosition : progress.pressed ? progress.dragValue * length : position
  readonly property bool keepOpen: scrubbing || progress.pressed

  property Disc front: discA
  property Disc back: discB
  property real spinSpeed: 0
  property bool preparing: false
  property bool awaitingArt: false
  property real pendingSeek: -1
  property string shownKey: ""
  property string shownTitle: ""
  property string shownArtist: ""

  spacing: 6

  function format(seconds) {
    const s = Math.max(0, Math.floor(seconds));
    const m = Math.floor(s / 60);
    const h = Math.floor(m / 60);
    const ss = String(s % 60).padStart(2, "0");
    return h > 0 ? `${h}:${String(m % 60).padStart(2, "0")}:${ss}` : `${m}:${ss}`;
  }

  function syncPosition() {
    if (!player || scrubbing)
      return;
    player.positionChanged();
    const reported = player.position;
    if (pendingSeek >= 0 && Math.abs(reported - pendingSeek) > 1.5)
      return;
    pendingSeek = -1;
    position = reported;
  }

  function seekTo(target) {
    position = target;
    pendingSeek = target;
    seekHold.restart();
    Media.seek(target);
  }

  Timer {
    id: seekHold
    interval: 6000
    onTriggered: root.pendingSeek = -1
  }

  function showMetadata() {
    shownTitle = player?.trackTitle || "Nothing playing";
    shownArtist = player?.trackArtist || player?.identity || "";
  }

  function prepareSwap() {
    const url = player?.trackArtUrl ?? "";
    if (trackKey === shownKey) {
      preparing = false;
      swapTimeout.stop();
      if (url !== "")
        front.art = url;
      return;
    }
    preparing = true;
    awaitingArt = url === "" || (url === front.art && front.opacity > 0);
    back.angle = 0;
    swapTimeout.interval = awaitingArt ? 1000 : 2000;
    swapTimeout.restart();
    if (!awaitingArt)
      back.art = url;
    checkPrepared();
  }

  function loadArt(url) {
    awaitingArt = false;
    swapTimeout.interval = 2000;
    swapTimeout.restart();
    back.art = url;
    checkPrepared();
  }

  function checkPrepared() {
    if (!preparing || awaitingArt)
      return;
    if (back.art === "" || back.artStatus === Image.Ready || back.artStatus === Image.Error)
      swapDisc();
  }

  function handleSwapTimeout() {
    if (!preparing)
      return;
    if (awaitingArt)
      loadArt(player?.trackArtUrl ?? "");
    else
      swapDisc();
  }

  function swapDisc() {
    if (!preparing)
      return;
    preparing = false;
    swapTimeout.stop();
    shownKey = trackKey;
    const outgoing = front;
    const incoming = back;
    outAnim.target = outgoing;
    inAnim.target = incoming;
    incoming.z = 0;
    outgoing.z = 1;
    front = incoming;
    back = outgoing;
    showMetadata();
    outAnim.restart();
    inAnim.restart();
  }

  Component.onCompleted: {
    syncPosition();
    prepareSwap();
  }

  onTrackKeyChanged: swapTimer.restart()

  Timer {
    id: swapTimer
    interval: 250
    onTriggered: root.prepareSwap()
  }

  Timer {
    id: swapTimeout
    interval: 2000
    onTriggered: root.handleSwapTimeout()
  }

  Connections {
    target: root.back
    function onArtStatusChanged() {
      root.checkPrepared();
    }
  }

  Connections {
    target: root.player
    function onTrackArtUrlChanged() {
      const url = root.player.trackArtUrl;
      if (url === "" || swapTimer.running)
        return;
      if (root.preparing)
        root.loadArt(url);
      else if (root.trackKey === root.shownKey)
        root.front.art = url;
    }
  }

  Timer {
    interval: 500
    running: root.player !== null
    repeat: true
    triggeredOnStart: true
    onTriggered: root.syncPosition()
  }

  FrameAnimation {
    running: root.spinSpeed > 0.5 || root.playing
    onTriggered: {
      const targetSpeed = root.playing && !root.scrubbing ? 90 : 0;
      root.spinSpeed += (targetSpeed - root.spinSpeed) * Math.min(1, frameTime * 3);
      if (!root.scrubbing)
        root.front.angle = (root.front.angle + root.spinSpeed * frameTime) % 360;
    }
  }

  Item {
    id: stage
    width: parent.width
    height: Theme.discSize + 16

    Disc {
      id: discA
      anchors.centerIn: parent
      width: Theme.discSize
      height: Theme.discSize
      opacity: 0
      scale: 0.85
    }

    Disc {
      id: discB
      anchors.centerIn: parent
      width: Theme.discSize
      height: Theme.discSize
      opacity: 0
      scale: 0.85
    }

    ParallelAnimation {
      id: outAnim
      property Item target

      NumberAnimation {
        target: outAnim.target
        property: "scale"
        to: 1.2
        duration: Theme.animRemove * 2.5
        easing.type: Easing.InCubic
      }
      NumberAnimation {
        target: outAnim.target
        property: "opacity"
        to: 0
        duration: Theme.animRemove * 2.5
        easing.type: Easing.InCubic
      }
    }

    SequentialAnimation {
      id: inAnim
      property Item target

      PauseAnimation {
        duration: Theme.animRemove * 1.5
      }
      ParallelAnimation {
        NumberAnimation {
          target: inAnim.target
          property: "scale"
          from: 0.8
          to: 1
          duration: Theme.animSlide * 2.5
          easing.type: Easing.OutBack
        }
        NumberAnimation {
          target: inAnim.target
          property: "opacity"
          from: 0
          to: 1
          duration: Theme.animMove * 2
          easing.type: Easing.OutQuad
        }
      }
    }

    MouseArea {
      id: scrub

      property real lastAngle: 0

      anchors.centerIn: parent
      width: Theme.discSize
      height: Theme.discSize
      enabled: root.canSeek
      preventStealing: true
      cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

      function angleAt(x, y) {
        return Math.atan2(y - height / 2, x - width / 2) * 180 / Math.PI;
      }

      onPressed: event => {
        const dx = event.x - width / 2;
        const dy = event.y - height / 2;
        if (dx * dx + dy * dy > width * width / 4) {
          event.accepted = false;
          return;
        }
        lastAngle = angleAt(event.x, event.y);
        root.scrubStart = root.position;
        root.scrubTurns = 0;
        root.scrubbing = true;
      }
      onPositionChanged: event => {
        if (!root.scrubbing)
          return;
        const a = angleAt(event.x, event.y);
        let delta = a - lastAngle;
        if (delta > 180)
          delta -= 360;
        else if (delta < -180)
          delta += 360;
        lastAngle = a;
        root.scrubTurns += delta / 360;
        root.front.angle = (root.front.angle + delta) % 360;
      }
      onReleased: {
        if (!root.scrubbing)
          return;
        const target = root.scrubPosition;
        root.seekTo(target);
        root.scrubbing = false;
      }
      onCanceled: root.scrubbing = false
    }
  }

  Column {
    width: parent.width
    spacing: 2

    Label {
      anchors.horizontalCenter: parent.horizontalCenter
      maxWidth: parent.width - 24
      text: root.shownTitle
      pixelSize: Theme.menuTitleSize + 1
    }

    Label {
      anchors.horizontalCenter: parent.horizontalCenter
      maxWidth: parent.width - 24
      text: root.shownArtist
      color: Theme.textVariant
      pixelSize: Theme.menuSubtitleSize
    }
  }

  Item {
    width: parent.width
    height: 28

    Text {
      id: elapsed
      anchors.left: parent.left
      anchors.leftMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      width: 40
      text: root.format(root.shownPosition)
      color: root.scrubbing || progress.pressed ? Theme.music : Theme.textVariant
      font.family: Theme.labelFont
      font.pixelSize: Theme.menuSubtitleSize
    }

    Slider {
      id: progress

      function seekFraction(fraction) {
        root.seekTo(fraction * root.length);
      }

      anchors.left: elapsed.right
      anchors.right: total.left
      anchors.leftMargin: 6
      anchors.rightMargin: 6
      anchors.verticalCenter: parent.verticalCenter
      height: 20
      trackHeight: 6
      interactive: root.canSeek
      step: root.length > 0 ? Math.min(0.2, 5 / root.length) : 0.05
      accent: Theme.music
      value: root.length > 0 ? root.shownPosition / root.length : 0
      onPressedChanged: {
        if (!pressed)
          seekFraction(dragValue);
      }
      onMoved: v => {
        if (!pressed)
          seekFraction(v);
      }
    }

    Text {
      id: total
      anchors.right: parent.right
      anchors.rightMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      width: 40
      horizontalAlignment: Text.AlignRight
      text: root.length > 0 ? root.format(root.length) : "–:––"
      color: Theme.textVariant
      font.family: Theme.labelFont
      font.pixelSize: Theme.menuSubtitleSize
    }
  }

  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: 18

    IconButton {
      anchors.verticalCenter: parent.verticalCenter
      implicitWidth: 40
      implicitHeight: 40
      icon: "skip_previous"
      iconColor: Theme.text
      opacity: root.player?.canGoPrevious ? 1 : 0.4
      onClicked: root.player?.previous()
    }

    Rectangle {
      width: 52
      height: 52
      radius: playMouse.pressed ? 16 : 26
      color: Theme.music
      scale: playMouse.pressed ? 0.92 : 1
      activeFocusOnTab: true

      function keyActivate() {
        root.player?.togglePlaying();
      }

      FocusRing {}

      Behavior on radius {
        NumberAnimation {
          duration: Theme.animMove
          easing.type: Theme.easeOut
        }
      }
      Behavior on scale {
        NumberAnimation {
          duration: Theme.animPress
        }
      }

      Icon {
        anchors.centerIn: parent
        text: root.playing ? "pause" : "play_arrow"
        color: Theme.surface
        size: 28
        fill: 1
      }

      MouseArea {
        id: playMouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.player?.togglePlaying()
      }
    }

    IconButton {
      anchors.verticalCenter: parent.verticalCenter
      implicitWidth: 40
      implicitHeight: 40
      icon: "skip_next"
      iconColor: Theme.text
      opacity: root.player?.canGoNext ? 1 : 0.4
      onClicked: root.player?.next()
    }
  }

  Item {
    width: parent.width
    height: 4
    visible: sources.visible
  }

  Flickable {
    id: sources
    width: parent.width
    height: 34
    visible: Media.players.length > 1
    contentWidth: sourceRow.width
    flickableDirection: Flickable.HorizontalFlick
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentWidth > width
    clip: true

    Row {
      id: sourceRow
      x: Math.max(0, (sources.width - width) / 2)
      spacing: 6

      Repeater {
        model: Media.players

        Chip {
          required property var modelData
          height: 32
          icon: modelData.isPlaying ? "graphic_eq" : "music_note"
          text: modelData.identity || modelData.dbusName
          selected: modelData === root.player
          onClicked: Media.select(modelData)
        }
      }
    }
  }
}
