// BrightnessWidget.qml — thin binding of SliderRow to the Brightness service.
import qs.components
import qs.services

SliderRow {
  icon: "☀"
  value: Brightness.value
  visible: Brightness.available
  onMoved: v => Brightness.setValue(v)
}
