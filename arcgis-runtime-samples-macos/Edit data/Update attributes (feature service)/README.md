# Update attributes (feature service)

This sample demonstrates how to edit the attributes of features in a feature service.

![](image1.png)

## How to use the sample

Features in the map represent properties. Click a house icon to display a callout. Callouts contain information about the type of damage for each property. Click the callout to open the editor for the type of property damage. Select a new value and click Apply to update the damage type for the selected property.


## How it works

The sample uses the `attributes` property on `AGSFeature` to get the current damage type for a selected property. On selection of a new damage type, the app sets the new value in the same  `attributes` dictionary. In order to apply the changes to the service, `applyEdits(completion:)` is called on the `AGSServiceFeatureTable` for the feature.

