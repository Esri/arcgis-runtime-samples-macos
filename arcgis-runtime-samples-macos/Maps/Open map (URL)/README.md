# Open map (URL)

This sample demonstrates how to open a web map from a URL on your Mac.

## How to use the sample

The sample opens with a web map displayed by default. You can select other web maps from the popup button. On selection, the web map opens up in the map view.

![](image1.png)

## How it works

The sample already has a set of URLs of three different web maps. Every time a selection is made, it creates a new instance of `AGSMap` using the `init(url:)` initializer and assigns it to the map view.




