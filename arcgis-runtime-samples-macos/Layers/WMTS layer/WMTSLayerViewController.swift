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

class WMTSLayerViewController: NSViewController {
    @IBOutlet private weak var mapView: AGSMapView!
    
    private var map: AGSMap!
    private var wmtsService: AGSWMTSService!
    
    private let wmtsServiceURL = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/WorldTimeZones/MapServer/WMTS")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize the map
        self.map = AGSMap()
        
        //assign the map to the map view
        self.mapView.map = self.map
        
        //create a WMTS service with the service URL
        self.wmtsService = AGSWMTSService(url: wmtsServiceURL)
        
        //load the WMTS service to access the service information
        self.wmtsService.load { [weak self] (error) in
            if let error = error {
                self?.showAlert(messageText: "Error loading WMTS service:", informativeText: error.localizedDescription)
            } else {
                //get the service information or metadata about the WMTS service
                if let weakSelf = self, let wmtsServiceInfo = weakSelf.wmtsService.serviceInfo {
                    //get information about the layers available in the WMTS service
                    let layerInfos = wmtsServiceInfo.layerInfos
                    
                    //create a WMTS layer using the first element in the collection of WMTS layer info objects
                    let wmtsLayer = AGSWMTSLayer(layerInfo: layerInfos[0])
                    
                    //set the basemap of the map with WMTS layer
                    weakSelf.map.basemap = AGSBasemap(baseLayer: wmtsLayer)
                }
            }
        }
    }
    
    // MARK: - Helper methods
    
    private func showAlert(messageText: String, informativeText: String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.beginSheetModal(for: self.view.window!)
    }
}
