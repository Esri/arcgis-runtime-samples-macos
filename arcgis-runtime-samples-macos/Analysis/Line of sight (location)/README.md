# Line of sight (location)

This sample demonstrates how to interactively place a line of sight between two locations.

![](image1.png)

## How it works

`AGSLocationLineOfSight` analysis provides an initializer called `init(observerLocation:targetLocation:)` that takes observer and target locations.

Once the `AGSLocationLineOfSight` is created, it is added to a collection of analysis overlays in the `AGSSceneView`. The analysis overlays are used to render the results of visual analysis on the scene view.

The sample uses the `geoView(_:didTapAtScreenPoint:mapPoint:)` method on `AGSGeoViewTouchDelegate` set the `observerLocation` on the `AGSLocationLineOfSight` to the clicked point on the scene view. The sample starts tracking cursor movement for the scene view by settings the scene view's `trackCursorMovement` property to `true` and in the `geoView(_:didMoveCursorToScreenPoint:mapPoint:)` delegate method, sets the `targetLocation` property of the `AGSLocationLineOfSight` to the cursor's current map point.

As a result of the analysis, a line is rendered between the observer and target with distinct colors representing visible and obstructed segments. The sample shows the visible segment in green and obstructed segment(s) in red.
