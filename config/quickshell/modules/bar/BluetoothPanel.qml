import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.theme
import qs.components
import qs.services

Column {
  id: root

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property bool powered: adapter?.enabled ?? false
  readonly property var devices: (adapter?.devices.values ?? []).filter(d => !d.blocked)
  readonly property var known: devices.filter(d => d.paired || d.bonded).sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
  readonly property var available: devices.filter(d => !d.paired && !d.bonded && d.deviceName !== "").sort((a, b) => a.name.localeCompare(b.name))

  function iconFor(device) {
    const icon = device.icon;
    if (icon.includes("headset") || icon.includes("headphone"))
      return "headphones";
    if (icon.includes("audio") || icon.includes("speaker"))
      return "speaker";
    if (icon.includes("mouse"))
      return "mouse";
    if (icon.includes("keyboard"))
      return "keyboard";
    if (icon.includes("gaming"))
      return "sports_esports";
    if (icon.includes("phone"))
      return "smartphone";
    if (icon.includes("computer"))
      return "computer";
    if (icon.includes("display") || icon.includes("video"))
      return "tv";
    return "bluetooth";
  }

  property string pendingAddress: ""

  onKnownChanged: {
    const device = known.find(d => d.address === pendingAddress);
    if (device && device.paired) {
      pendingAddress = "";
      device.trusted = true;
      device.connect();
    }
  }

  property bool discoveryRequested: false

  function setDiscovering(on) {
    const want = on && powered;
    if (want === discoveryRequested)
      return;
    discoveryRequested = want;
    if (adapter && adapter.enabled)
      adapter.discovering = want;
  }

  spacing: Theme.menuGap

  Component.onCompleted: {
    BluetoothAgent.acquire();
    setDiscovering(true);
  }
  Component.onDestruction: {
    setDiscovering(false);
    BluetoothAgent.release();
  }

  Binding {
    target: BluetoothAgent
    property: "accept"
    value: root.devices.some(d => d.pairing)
  }
  onPoweredChanged: setDiscovering(powered)

  component SectionLabel: Text {
    leftPadding: 12
    topPadding: 6
    bottomPadding: 2
    color: Theme.textVariant
    font.family: Theme.labelFont
    font.pixelSize: Theme.menuSubtitleSize
  }

  component DeviceItem: MenuItem {
    id: item

    required property var modelData
    readonly property var device: modelData
    readonly property bool busy: device.pairing || device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting
    property bool failed: false

    width: parent ? parent.width : 0
    icon: root.iconFor(device)
    title: device.name || device.deviceName || device.address
    active: device.connected
    subtitle: {
      if (device.pairing)
        return "Pairing…";
      if (device.state === BluetoothDeviceState.Connecting)
        return "Connecting…";
      if (device.state === BluetoothDeviceState.Disconnecting)
        return "Disconnecting…";
      if (failed)
        return "Pairing failed";
      if (device.connected)
        return device.batteryAvailable ? `Connected · ${Math.round(device.battery * 100)}%` : "Connected";
      if (device.paired || device.bonded)
        return "Paired";
      return "Tap to pair";
    }

    onClicked: {
      failed = false;
      if (device.pairing) {
        root.pendingAddress = "";
        device.cancelPair();
      } else if (device.connected) {
        device.disconnect();
      } else if (device.paired || device.bonded) {
        device.connect();
      } else {
        root.pendingAddress = device.address;
        device.pair();
      }
    }

    Connections {
      target: item.device
      function onPairingChanged() {
        if (!item.device.pairing && !item.device.paired && root.pendingAddress === item.device.address) {
          item.failed = true;
        }
      }
    }

    Spinner {
      anchors.verticalCenter: parent.verticalCenter
      visible: item.busy
      tint: item.device.connected ? Theme.onPrimary : Theme.primary
    }

    IconButton {
      visible: (item.device.paired || item.device.bonded) && !item.busy
      icon: "delete"
      iconColor: item.device.connected ? Theme.onPrimary : Theme.textVariant
      onClicked: item.device.forget()
    }
  }

  Item {
    width: parent.width
    height: 44

    Text {
      anchors.left: parent.left
      anchors.leftMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      text: "Bluetooth"
      color: Theme.text
      font.family: Theme.labelFont
      font.pixelSize: Theme.menuHeaderSize
    }

    Spinner {
      anchors.right: btSwitch.left
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      visible: root.adapter?.discovering ?? false
    }

    Switch {
      id: btSwitch
      anchors.right: parent.right
      anchors.rightMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      visible: root.adapter !== null
      checked: root.powered
      onToggled: root.adapter.enabled = !root.adapter.enabled
    }
  }

  Text {
    width: parent.width
    height: Theme.menuItemHeight
    visible: !root.powered
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    text: root.adapter ? "Bluetooth is off" : "No Bluetooth adapter"
    color: Theme.textVariant
    font.family: Theme.labelFont
    font.pixelSize: Theme.menuTitleSize
  }

  Flickable {
    width: parent.width
    height: Math.min(contentHeight, Theme.menuListMaxHeight)
    visible: root.powered
    clip: true
    contentHeight: sections.implicitHeight
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height

    Column {
      id: sections
      width: parent.width
      spacing: Theme.menuGap

      SectionLabel {
        visible: root.known.length > 0
        text: "My devices"
      }

      Repeater {
        model: ScriptModel {
          values: root.known
        }

        DeviceItem {}
      }

      SectionLabel {
        text: "Available devices"
      }

      Repeater {
        model: ScriptModel {
          values: root.available
        }

        DeviceItem {}
      }

      Text {
        width: parent.width
        height: Theme.menuItemHeight
        visible: root.available.length === 0
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: "Searching…"
        color: Theme.textVariant
        font.family: Theme.labelFont
        font.pixelSize: Theme.menuSubtitleSize
      }
    }
  }
}
