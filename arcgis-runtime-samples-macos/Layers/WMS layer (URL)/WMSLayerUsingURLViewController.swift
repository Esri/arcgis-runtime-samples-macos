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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize the map with a light gray basemap centered on the United States
        let map = AGSMap(basemapType: .lightGrayCanvasVector, latitude: 39, longitude: -98, levelOfDetail: 4)
        //assign the map to the map view
        mapView.map = map
        
        // a URL to the GetCapabilities endpoint of a WMS service
        let wmsServiceURL = URL(string: "https://nowcoast.noaa.gov/arcgis/services/nowcoast/radar_meteo_imagery_nexrad_time/MapServer/WMSServer?request=GetCapabilities&service=WMS")!
        // the names of the layers to load at the WMS service
        let wmsServiceLayerNames = ["1"]
        
        //initialize the WMS layer with the service URL and uniquely identifying WMS layer names
        let wmsLayer = AGSWMSLayer(url: wmsServiceURL, layerNames: wmsServiceLayerNames)
        
        NSApp.mainWindow?.showProgressIndicator()
        
        //load the WMS layer
        wmsLayer.load {[weak self] (error) in
            
            guard let self = self else{
                return
            }
            
            self.view.window?.hideProgressIndicator()
            
            if let error = error {
                self.showAlert(messageText: "Error loading WMS layer:", informativeText: error.localizedDescription)
            } else if wmsLayer.loadStatus == .loaded {
                //add the WMS layer to the map
                map.operationalLayers.add(wmsLayer)
            }
        }
    }
    
    //MARK: - Helper methods
    
    private func showAlert(messageText:String, informativeText:String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.beginSheetModal(for: view.window!)
    }
    
}
