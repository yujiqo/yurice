import QtQuick
import qs.components
import qs.theme

Item {
  id: suite

  width: 300
  height: 600

  Card {
    id: card

    Item {
      width: parent.width
      height: 30
    }

    Item {
      width: parent.width
      height: 20
    }
  }

  Card {
    id: spaced
    padding: 8
    spacing: 8

    Item {
      width: parent.width
      height: 10
    }

    Item {
      width: parent.width
      height: 10
    }
  }

  MenuList {
    id: list
    model: 5
    delegate: Item {
      width: 10
      height: 10
    }
  }

  SwitchRow {
    id: row
    checked: true
    property int toggles: 0
    onToggled: toggles++
  }

  EmptyState {
    id: empty
    text: "Nothing"
  }

  function test_cardSizesToContent(t) {
    t.eq([card.implicitHeight, card.width, card.radius], [58, suite.width, Theme.menuItemRadius]);
    t.eq(spaced.implicitHeight, 10 + 8 + 10 + 16);
  }

  function test_menuListStepClamps(t) {
    list.currentIndex = 0;
    list.step(-1);
    t.eq(list.currentIndex, 0);
    list.step(3);
    t.eq(list.currentIndex, 3);
    list.step(10);
    t.eq(list.currentIndex, 4);
    t.ok(!list.followCurrent, "following the current item is opt-in");
  }

  function test_switchRowForwardsToggle(t) {
    t.eq([row.value, row.width], ["", suite.width]);
    const sw = row.children.find(c => c.toggled !== undefined && c.checked !== undefined);
    t.ok(sw && sw.checked, "inner switch mirrors checked");
    sw.toggled();
    t.eq(row.toggles, 1);
  }

  function test_emptyStateDefaults(t) {
    t.eq([empty.width, empty.height, empty.horizontalAlignment, empty.wrapMode], [suite.width, Theme.menuItemHeight, Text.AlignHCenter, Text.WordWrap]);
  }
}
