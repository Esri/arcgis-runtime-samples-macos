#Change sublayer visibility

This sample demonstrates how you can hide or show sublayers of a map image layer

##How the app works

The list on the side displays the list of sublayers present in the map. Each sublayer in the list has a checkbox, which can be used to toggle visibility of that particular sublayer.

![](image1.png)

##How it works

The `mapImageSublayers` property on `AGSArcGISMapImageLayer` is used to get the list of `AGSArcGISMapImageSublayer`. Each of these sublayer has a property called `isVisible`, which is used to toggle visibility.



