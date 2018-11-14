// Copyright 2018 Esri.
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

import AppKit
import ArcGIS

class DisplayKMLViewController: NSViewController {
    
    @IBOutlet weak var mapView: AGSMapView!
    
    /// The layer now loading asynchrounously
    private weak var loadingLayer: AGSKMLLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Instantiate a map with a dark gray basemap centered on the United States
        let map = AGSMap(basemapType: .darkGrayCanvasVector, latitude: 39, longitude: -98, levelOfDetail: 4)
        // Display the map in the map view
        mapView.map = map
        
        // Set the initial KML source
        changeSourceToURL(self)
    }
    
    private func display(kmlLayer: AGSKMLLayer) {
        // Keep a weak reference to the layer being loaded
        loadingLayer = kmlLayer
        
        NSApp.showProgressIndicator()
        
        // Clear the existing layers from the map
        mapView.map?.operationalLayers.removeAllObjects()
        // Add the KML layer to the map
        mapView.map?.operationalLayers.add(kmlLayer)
        
        // This load call is not required, but it allows for error
        // feedback and progress indication
        kmlLayer.load {[weak self] (error) in
            
            NSApp.hideProgressIndicator()
            
            guard let self = self,
                 // If another layer started loading before this one finished, don't proceed
                self.loadingLayer == kmlLayer else {
                return
            }
            
            /// Indicate that no layer is loading
            self.loadingLayer = nil
            
            if let error = error {
                // Display the error if one occurred
                NSAlert(error: error).beginSheetModal(for: self.view.window!)
            }
        }
        
    }
    
    // MARK: - Actions
    
    @IBAction func changeSourceToURL(_ sender: Any) {
        // A URL of a remote KML file
        let kmlDatasetURL = URL(string: "https://www.wpc.ncep.noaa.gov/kml/noaa_chart/WPC_Day1_SigWx.kml")!
        let kmlDataset = AGSKMLDataset(url: kmlDatasetURL)
        /// A KML layer created from a remote KML file
        let kmlLayer = AGSKMLLayer(kmlDataset: kmlDataset)
        display(kmlLayer: kmlLayer)
    }
    
    @IBAction func changeSourceToLocalFile(_ sender: Any) {
        /// A dataset created by referencing the name of a KML file in the app bundle
        let kmlDataset = AGSKMLDataset(name: "US_State_Capitals")
        /// A KML layer created from a local KML file
        let kmlLayer = AGSKMLLayer(kmlDataset: kmlDataset)
        display(kmlLayer: kmlLayer)
    }
    
    @IBAction func changeSourceToPortalItem(_ sender: Any) {
        let portal = AGSPortal.arcGISOnline(withLoginRequired: false)
        /// A remote KML portal item
        let portalItem = AGSPortalItem(portal: portal, itemID: "9fe0b1bfdcd64c83bd77ea0452c76253")
        /// A KML layer created from an ArcGIS Online portal item
        let kmlLayer = AGSKMLLayer(item: portalItem)
        display(kmlLayer: kmlLayer)
    }

}
