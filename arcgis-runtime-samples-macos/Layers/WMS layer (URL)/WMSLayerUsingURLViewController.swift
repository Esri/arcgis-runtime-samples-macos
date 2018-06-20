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

class WMSLayerUsingURLViewController: NSViewController {
    
    @IBOutlet private weak var mapView:AGSMapView!
    
    private var map:AGSMap!
    private var wmsLayer: AGSWMSLayer!
    
    private let WMS_SERVICE_URL = URL(string: "https://certmapper.cr.usgs.gov/arcgis/services/geology/africa/MapServer/WMSServer?request=GetCapabilities&service=WMS")!
    private let WMS_SERVICE_LAYER_NAMES = ["0"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize the map with imagery basemap, latitude, longitude, and level of detail
        self.map = AGSMap(basemapType: .imagery, latitude: 2.0, longitude: 18.0, levelOfDetail: 3)
        
        //assign the map to the map view
        self.mapView.map = self.map
        
        //initialize the WMS layer with the service URL and uniquely identifying WMS layer names
        self.wmsLayer = AGSWMSLayer(url: WMS_SERVICE_URL, layerNames: WMS_SERVICE_LAYER_NAMES)
        
        //load the WMS layer
        self.wmsLayer.load {[weak self] (error) in
            if let error = error {
                self?.showAlert(messageText: "Error loading WMS layer:", informativeText: error.localizedDescription)
            } else {
                if let weakSelf = self, weakSelf.wmsLayer.loadStatus == .loaded {
                    //add the WMS layer to the map
                    weakSelf.map.operationalLayers.add(weakSelf.wmsLayer)
                }
            }
        }
    }
    
    //MARK: - Helper methods
    
    private func showAlert(messageText:String, informativeText:String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.beginSheetModal(for: self.view.window!)
    }
    
}
