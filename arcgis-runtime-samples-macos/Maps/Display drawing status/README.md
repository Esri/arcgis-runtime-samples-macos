#Display drawing status

This sample displays the current drawing status of the map in the toolbar.

##How it works

The AGSMapView:drawStatusChangedHandler block is called each time the AGSDrawStatus changes on the map. In this sample the block shows a NSProgressIndicator when the AGSDrawStatus is InProgress.

![](image1.png)





