pragma Singleton
import Quickshell
import QtQuick
import qs.theme

Singleton {
  id: root

  property real autoLatitude: NaN
  property real autoLongitude: NaN
  property string autoCity: ""
  readonly property var manual: Settings.weatherLocation
  readonly property real latitude: manual ? manual.latitude : autoLatitude
  readonly property real longitude: manual ? manual.longitude : autoLongitude
  readonly property string targetCity: manual ? manual.name : autoCity
  property string city: ""
  property bool cityIsManual: false
  property real fade: 1
  property bool animateNext: false
  property var pendingData: null
  readonly property string temperatureUnit: Settings.weatherFahrenheit ? "°F" : "°C"
  readonly property string windUnit: Settings.weatherFahrenheit ? "mph" : "km/h"
  property int generation: 0

  property var searchResults: []
  property bool searching: false
  property int searchGeneration: 0

  readonly property string settingsKey: JSON.stringify([manual, Settings.weatherFahrenheit])
  onSettingsKeyChanged: reload()

  property bool ready: false
  property bool loading: false
  property string error: ""

  property real temperature: 0
  property real feelsLike: 0
  property int humidity: 0
  property real wind: 0
  property int code: 0
  property bool isDay: true
  property var days: []

  readonly property var current: describe(code, isDay)

  function describe(code, day) {
    const d = day === undefined ? true : day;
    if (code === 0)
      return {
        text: d ? "Sunny" : "Clear",
        icon: d ? "clear_day" : "bedtime"
      };
    if (code === 1 || code === 2)
      return {
        text: "Partly cloudy",
        icon: d ? "partly_cloudy_day" : "partly_cloudy_night"
      };
    if (code === 3)
      return {
        text: "Cloudy",
        icon: "cloud"
      };
    if (code === 45 || code === 48)
      return {
        text: "Fog",
        icon: "foggy"
      };
    if (code >= 51 && code <= 57)
      return {
        text: "Drizzle",
        icon: "rainy_light"
      };
    if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82))
      return {
        text: code === 65 || code === 82 ? "Heavy rain" : "Rain",
        icon: code === 65 || code === 82 ? "rainy_heavy" : "rainy"
      };
    if ((code >= 71 && code <= 77) || code === 85 || code === 86)
      return {
        text: "Snow",
        icon: "weather_snowy"
      };
    if (code >= 95)
      return {
        text: "Thunderstorm",
        icon: "thunderstorm"
      };
    return {
      text: "Unknown",
      icon: "filter_drama"
    };
  }

  function request(url, done) {
    const xhr = new XMLHttpRequest();
    xhr.onreadystatechange = () => {
      if (xhr.readyState !== XMLHttpRequest.DONE)
        return;
      if (xhr.status !== 200) {
        done(null);
        return;
      }
      try {
        done(JSON.parse(xhr.responseText));
      } catch (e) {
        done(null);
      }
    };
    xhr.open("GET", url);
    xhr.send();
  }

  function fail(message) {
    loading = false;
    error = message;
    retry.restart();
  }

  function reload() {
    loading = false;
    retry.stop();
    animateNext = ready;
    refresh();
  }

  function apply(data) {
    const c = data.current;
    temperature = c.temperature_2m;
    feelsLike = c.apparent_temperature;
    humidity = c.relative_humidity_2m;
    wind = c.wind_speed_10m;
    code = c.weather_code;
    isDay = c.is_day === 1;
    const d = data.daily;
    days = d.time.map((t, i) => ({
          date: new Date(t + "T12:00:00"),
          code: d.weather_code[i],
          max: d.temperature_2m_max[i],
          min: d.temperature_2m_min[i],
          rain: d.precipitation_probability_max[i] ?? 0,
          sunrise: new Date(d.sunrise[i]),
          sunset: new Date(d.sunset[i])
        }));
    city = targetCity;
    cityIsManual = manual !== null;
    ready = true;
  }

  function refresh() {
    if (loading)
      return;
    loading = true;
    const token = ++generation;
    if (isNaN(latitude) || isNaN(longitude)) {
      request("https://ipinfo.io/json", data => {
        if (token !== generation)
          return;
        const loc = (data?.loc ?? "").split(",").map(Number);
        if (loc.length !== 2 || loc.some(isNaN)) {
          fail("Couldn't find location");
          return;
        }
        autoLatitude = loc[0];
        autoLongitude = loc[1];
        autoCity = data.city ?? "";
        fetchForecast(token);
      });
    } else {
      fetchForecast(token);
    }
  }

  function search(query) {
    const name = query.trim();
    const token = ++searchGeneration;
    if (name.length < 2) {
      searching = false;
      searchResults = [];
      return;
    }
    searching = true;
    request(`https://geocoding-api.open-meteo.com/v1/search?count=6&language=en&format=json&name=${encodeURIComponent(name)}`, data => {
      if (token !== searchGeneration)
        return;
      searching = false;
      searchResults = (data?.results ?? []).map(r => ({
            name: r.name,
            region: [r.admin1, r.country].filter(Boolean).join(", "),
            latitude: r.latitude,
            longitude: r.longitude
          }));
    });
  }

  function clearSearch() {
    searchGeneration++;
    searching = false;
    searchResults = [];
  }

  function fetchForecast(token) {
    const units = Settings.weatherFahrenheit ? "&temperature_unit=fahrenheit&wind_speed_unit=mph" : "";
    const url = "https://api.open-meteo.com/v1/forecast" + `?latitude=${latitude}&longitude=${longitude}` + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,is_day" + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset" + "&timezone=auto&forecast_days=7" + units;
    request(url, data => {
      if (token !== generation)
        return;
      if (!data || !data.current || !data.daily) {
        fail("Couldn't load weather");
        return;
      }
      error = "";
      loading = false;
      if (animateNext) {
        animateNext = false;
        pendingData = data;
        swap.restart();
      } else {
        apply(data);
      }
    });
  }

  SequentialAnimation {
    id: swap

    NumberAnimation {
      target: root
      property: "fade"
      to: 0
      duration: Theme.animMove
      easing.type: Easing.InQuad
    }
    ScriptAction {
      script: {
        root.apply(root.pendingData);
        root.pendingData = null;
      }
    }
    NumberAnimation {
      target: root
      property: "fade"
      to: 1
      duration: Theme.animMove
      easing.type: Easing.OutQuad
    }
  }

  Timer {
    interval: 15 * 60 * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Timer {
    id: retry
    interval: 60 * 1000
    onTriggered: root.refresh()
  }
}
