#Feature layer (geodatabase)

This sample demonstrates how to show a feature layer on a map using a geodatabase

![](image1.png)

##How it works

The sample creates an instance of `AGSGeodatabase` using the initializer `init(name:)` where the name refers to a geodatabase file that has been included in the application bundle. When the geodatabase has loaded the TrailHeads feature table is used to create a feature layer that is then added to the list of operational layers of the map.



