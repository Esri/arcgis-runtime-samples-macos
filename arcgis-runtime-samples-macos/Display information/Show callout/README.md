#Show callout

This sample demonstrates how to show location coordinates on a map using a callout.

##How to use the sample

Tap on the map to get the coordinates for the location in a callout. Tap again to hide it.

![](image1.png)

##How it works

When the user does long press on the map view the `geoView(_:didLongPressAtScreenPoint:mapPoint:)` method on the `AGSGeoViewTouchDelegate` is fired. Inside this method we setup the `callout` object on the `mapView`, by setting the `title` property as "Location" and `detail` property as a string composed using `mapPoint`. Then the `show(at:screenOffset:rotateOffsetWithMap:animated:)` method is called to display the callout at the selected point.






