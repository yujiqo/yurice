import QtQuick
import qs.components

Item {
  id: suite

  property QtObject host: QtObject {
    property string dropdown: ""

    function request(name) {
      dropdown = dropdown === name ? "" : name;
    }
  }

  Component {
    id: first

    Item {}
  }

  Component {
    id: second

    Item {}
  }

  Island {
    id: single
    host: suite.host
    panels: ({
        calendar: first
      })
  }

  Island {
    id: multi
    host: suite.host
    panels: ({
        wifi: first,
        bluetooth: second
      })
  }

  Island {
    id: detached
    panels: ({
        calendar: first
      })
  }

  function test_closedByDefault(t) {
    host.dropdown = "";
    t.eq([single.open, single.panel, multi.open, multi.panel], [false, null, false, null]);
    t.eq(single.panelNames, ["calendar"]);
  }

  function test_opensMatchingPanel(t) {
    host.dropdown = "calendar";
    t.ok(single.open);
    t.ok(single.panel === first);
    t.ok(!multi.open);
    t.ok(!detached.open, "an island without host never follows the bar");
    host.dropdown = "";
  }

  function test_multiPanelIndex(t) {
    host.dropdown = "bluetooth";
    t.ok(multi.open);
    t.ok(multi.panel === second);
    t.eq(multi.panelIndex, 1);
    host.dropdown = "wifi";
    t.eq(multi.panelIndex, 0);
    host.dropdown = "";
  }

  function test_requestTogglesHost(t) {
    host.dropdown = "";
    single.request("calendar");
    t.eq(host.dropdown, "calendar");
    single.request("calendar");
    t.eq(host.dropdown, "");
  }

  function test_dismissClearsHost(t) {
    host.dropdown = "wifi";
    multi.dismissed();
    t.eq(host.dropdown, "");
    detached.dismissed();
  }
}
