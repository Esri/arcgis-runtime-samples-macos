#Identify graphics

This sample demonstrates how to identify graphics in a graphics overlay.

##How to use the sample

When you tap on a graphic on the map, you should see an alert view.

![](image1.png)
![](image2.png)

##How it works

The sample implements the `mapView:didTapAtPoint:mapPoint:` delegate method on `AGSMapViewTouchDelegate` to determine when a user tapped on the map. The method provides a property `screenPoint` which specifies the corresponding point in the map. The app then uses the `identifyGraphicsOverlay:screenPoint:tolerance:maximumResults:completion:` method on `AGSMapView` to identify graphics at that particular location.




