# Add delete related features

This sample demonstrates how to add or delete related features on an origin feature.

## How to use the sample

Click on a park in the map view. A list of species as related features will be shown. Click on the `Add` button on the top right to add a new specie to the park. To delete a specie select it and press the `Delete` key on the keyboard.

![](image1.png)

## How it works

To add a related feature, the sample uses `createFeature(attributes:geometry:)` method on the related feature table `AGSServiceFeatureTable`. The new feature is then related to the origin feature using `relate(to:)` method on `AGSFeature`. Then its added to the related feature table using `add(_:completion:)` method.

Similary, to delete a related feature, the sample uses `delete(_:completion:)` method on the related feature table `AGSServiceFeatureTable`. The changes are applied to the service by calling `applyEdits(completion:)` on the feature table when tapped on the `Done` button.




