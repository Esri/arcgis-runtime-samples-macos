# RGB renderer

This sample demonstrates how to use RGB renderer on a raster layer.

## How to use the sample

The sample allows you to change the stretch type and the parameters for each type. You can click on the `Apply` button to update the raster.

![](image1.png)

## How it works

The sample uses `AGSRGBRenderer` class to generate RGB renderers. The settings provided by the user are put in the initializer `init(stretchParameters:bandIndexes:gammas:estimateStatistics:)` to get a new renderer and the renderer is then set on the raster.



