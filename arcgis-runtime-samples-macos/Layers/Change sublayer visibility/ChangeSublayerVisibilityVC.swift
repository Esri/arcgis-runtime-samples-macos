//
// Copyright 2017 Esri.
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

class ChangeSublayerVisibilityVC: NSViewController, NSTableViewDataSource, NSTableViewDelegate, SublayerCellViewDelegate {

    @IBOutlet var mapView:AGSMapView!
    @IBOutlet var tableView:NSTableView!
    
    private var map:AGSMap!
    private var mapImageLayer:AGSArcGISMapImageLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize map with topographic basemap
        self.map = AGSMap(basemap: .topographic())
        
        //initialize the map image layer using a url
        self.mapImageLayer = AGSArcGISMapImageLayer(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/SampleWorldCities/MapServer")!)
        
        self.mapImageLayer.load { [weak self] (error: Error?) in
            if error == nil {
                self?.tableView.reloadData()
            }
        }
        
        //add the image layer to the map
        self.map.operationalLayers.add(self.mapImageLayer)
        
        //assign the map to the map view
        self.mapView.map = self.map
        
        //zoom to a custom viewpoint
        self.mapView.setViewpointCenter(AGSPoint(x: -11e6, y: 6e6, spatialReference: AGSSpatialReference.webMercator()), scale: 9e7, completion: nil)
    }
    
    //MARK: - NSTableViewDataSource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        let rows = self.mapImageLayer?.mapImageSublayers.count ?? 0
        return rows
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let sublayer = self.mapImageLayer.mapImageSublayers[row] as! AGSArcGISMapImageSublayer
        
        let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SublayerCellView"), owner: self) as! SublayerCellView
        cellView.button.title = sublayer.name
        cellView.delegate = self
        cellView.index = row
        
        return cellView
    }
    
    //MARK: - SublayerCellViewDelegate
    
    func sublayerCellView(_ sublayerCellView: SublayerCellView, didToggleVisibility visible: Bool) {
        let index = sublayerCellView.index
        let sublayer = self.mapImageLayer.mapImageSublayers[index] as! AGSArcGISMapImageSublayer
        sublayer.isVisible = visible
    }
}
