# Map loaded

This sample shows how to tell what the map's load status is. This is obtained from the enum value from a LoadStatus class. The LoadStatus is considered loaded when any of the following are true:

- The map has a valid spatial reference
- The map has an an initial viewpoint
- One of the map's predefined layers has been created.

![](image1.png)

## How it works

The sample uses Key-Value Observing to register and receive observations on the `loadStatus` property of the `AGSMap`. The banner label will be updated everytime the status changes.



