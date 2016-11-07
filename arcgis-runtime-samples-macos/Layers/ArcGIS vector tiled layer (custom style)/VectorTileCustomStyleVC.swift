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

import Cocoa
import ArcGIS

class VectorTileCustomStyleVC: NSViewController, VectorStylesVCDelegate {

    @IBOutlet private var mapView:AGSMapView!
    @IBOutlet private var collectionView:NSCollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //default vector tiled layer
        let vectorTiledLayer = AGSArcGISVectorTiledLayer(URL: NSURL(string: "https://arcgisruntime.maps.arcgis.com/home/item.html?id=1349bfa0ed08485d8a92c442a3850b06")!)
        
        //initialize map with vector tiled layer as the basemap
        let map = AGSMap(basemap: AGSBasemap(baseLayer: vectorTiledLayer))
        
        //initial viewpoint
        let centerPoint = AGSPoint(x: 1990591.559979, y: 794036.007991, spatialReference: AGSSpatialReference(WKID: 3857))
        map.initialViewpoint = AGSViewpoint(center: centerPoint, scale: 88659253.829259947)
        
        //assign map to map view
        self.mapView.map = map
    }
    
    private func showSelectedItem(itemID: String) {
        let vectorTiledLayer = AGSArcGISVectorTiledLayer(URL: NSURL(string: "https://arcgisruntime.maps.arcgis.com/home/item.html?id=\(itemID)")!)
        self.mapView.map?.basemap = AGSBasemap(baseLayer: vectorTiledLayer)
    }
    
    //MARK: - Navigation

    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "VectorStylesSegue" {
            let controller = segue.destinationController as! VectorStylesViewController
            controller.delegate = self
        }
    }
    
    //MARK: - VectorStylesVCDelegate
    
    func vectorStylesViewController(vectorStylesViewController: VectorStylesViewController, didSelectItemWithID itemID: String) {
        
        //dismiss sheet
        self.dismissViewController(vectorStylesViewController)
        
        //show newly selected vector layer
        self.showSelectedItem(itemID)
    }

    func vectorStylesViewControllerDidCancel(vectorStylesViewController: VectorStylesViewController) {
        
        //dismiss sheet
        self.dismissViewController(vectorStylesViewController)
    }
    
}

