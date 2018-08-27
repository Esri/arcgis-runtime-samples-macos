# Distance composite symbol

Demonstrates how to create a graphic using a distance composite scene symbol. Distance composite scene symbols can render different symbols depending on the distance between the camera and the graphic.

![](image1.png)

# How to use the sample

The symbol of graphic will change while zooming in or out.

## How it works

To create and display a `AGSDistanceCompositeSceneSymbol`:

1. Create an `AGSGraphicsOverlay` and add it to the `AGSSceneView`.
1. Create symbols for each `AGSRange` the composite symbol.
1. Create a distance composite scene symbol.
1. Add a range for each symbol to `distanceCompositeSceneSymbol.ranges.append(AGSDistanceSymbolRange(symbol:minDistance:maxDistance:))`.
  * symbol: A symbol to be used within the given min/max range.
  * min/max distance: The minimum and maximum distance that the symbol will be displayed from the `AGSCamera`.
1. Create a `AGSGraphic` with the symbol: `AGSGraphic(geometry:symbol:attributes:)`
1. Add the graphic to the graphics overlay.