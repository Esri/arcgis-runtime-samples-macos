//
// Copyright 2016 Esri.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import AppKit
import ArcGIS

class VectorTileLayerViewController: NSViewController {

    @IBOutlet var mapView:AGSMapView!
    
    private var midCenturyURLString = "http://www.arcgis.com/home/item.html?id=7675d44bb1e4428aa2c30a9b68f97822"
    private var coloredPencilURLString = "http://www.arcgis.com/home/item.html?id=4cf7e1fb9f254dcda9c8fbadb15cf0f8"
    private var newsPaperURLString = "http://www.arcgis.com/home/item.html?id=dfb04de5f3144a80bc3f9f336228d24a"
    private var novaURLString = "http://www.arcgis.com/home/item.html?id=75f4dfdff19e445395653121a95a85db"
    private var nightURLString = "http://www.arcgis.com/home/item.html?id=86f556a2d1fd468181855a35e344567f"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //create a vector tiled layer
        let vectorTileLayer = AGSArcGISVectorTiledLayer(url: URL(string: midCenturyURLString)!)
        //create a map and set the vector tiled layer as the basemap
        let map = AGSMap(basemap: AGSBasemap(baseLayer: vectorTileLayer))
        
        //assign the map to the map view
        self.mapView.map = map

        //center on Miami, Fl
        self.mapView.setViewpointCenter(AGSPoint(x: -80.18, y: 25.778135, spatialReference: AGSSpatialReference.wgs84()), scale: 150000, completion: nil)

    }
    
    @IBAction func segmentedControlChanged(_ sender:NSSegmentedControl) {
        var urlString:String
        switch sender.selectedSegment {
        case 0:
            urlString = midCenturyURLString
        case 1:
            urlString = coloredPencilURLString
        case 2:
            urlString = newsPaperURLString
        case 3:
            urlString = novaURLString
        default:
            urlString = nightURLString
        }
        
        //create the new vector tiled layer using the url
        let vectorTileLayer = AGSArcGISVectorTiledLayer(url: URL(string: urlString)!)
        //change the basemap to the new layer
        self.mapView.map?.basemap = AGSBasemap(baseLayer: vectorTileLayer)
    }
}
