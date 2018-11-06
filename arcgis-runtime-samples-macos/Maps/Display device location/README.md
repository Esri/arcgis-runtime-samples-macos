# Display device location

This sample demonstrates how you can enable location services and switch between different types of auto-pan modes.

## How to use the sample

Use the "Show Location" checkbox to toggle the visibility of the location indicator in the map view. If you have not yet used location services in this app, you will be asked by the system to provide permission to use your device's location.

Change the "Auto-Pan Mode" to choose if and how the SDK will position the map view's viewpoint to keep the location indicator in-frame. See the [documentation](https://developers.arcgis.com/qt/latest/cpp/api-reference/esri-arcgisruntime-locationdisplayautopanmode.html) for descriptions of the different modes. Note that manually panning the map will reset the auto-pan mode back to "Off".

![](image1.png)

## How it works

Each `AGSMapView` has its own instance of `AGSLocationDisplay`, stored as `locationDisplay`. The `dataSource` on `AGSLocationDisplay` is responsible for providing periodic location updates. The default `dataSource` uses the platform's location service (`CLLocationManager`). To start displaying location, you need to call `start(completion: )`. To stop displaying location, you need to call `stop()`. Use the `autoPanMode` property to change the how the map behaves when location updates are received.