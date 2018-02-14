//
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
//

import Cocoa
import ArcGIS

class WMSCatalogViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, LayerCellViewDelegate {

    @IBOutlet var mapView:AGSMapView!
    @IBOutlet var tableView:NSTableView!
    
    private var map: AGSMap!
    private var allLayers = [AGSWMSLayer]()
    private var wmsService: AGSWMSService!
    
    private let WMS_SERVICE_URL = URL(string: "https://idpgis.ncep.noaa.gov/arcgis/services/NWS_Forecasts_Guidance_Warnings/natl_fcst_wx_chart/MapServer/WMSServer?request=GetCapabilities&service=WMS")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // initialize the map with dark gray canvase basemap
        map = AGSMap(basemap: AGSBasemap.darkGrayCanvasVector())
        
        // assign the map to the map view
        mapView.map = map
        
        // zoom to a custom viewpoint
        let viewPoint = AGSViewpoint(targetExtent: AGSEnvelope(xMin: -16390242.238100, yMin: 1229349.831800, xMax: -5413415.367700, yMax: 8519715.614400, spatialReference: AGSSpatialReference.webMercator()))
        self.mapView.setViewpoint(viewPoint)
        
        // initialize the WMS service with the service URL
        wmsService = AGSWMSService(url: WMS_SERVICE_URL)
        
        // load the WMS service
        wmsService.load {[weak self] (error) in
            guard error == nil else {
                self?.showAlert(messageText: "Error", informativeText: "Error loading WMS service :: \(error!.localizedDescription)")
                return
            }
            
            // get the service info (metadata) from the service
            let wmsServiceInfo = self?.wmsService.serviceInfo
            
            // get the list of layer infos from the service info
            let layerInfos = wmsServiceInfo?.layerInfos as! [AGSWMSLayerInfo]
            
            self?.createLayers(using: layerInfos)
        }
    }
    
    // MARK: - Helper methods
    
    func createLayers(using layerInfos: [AGSWMSLayerInfo]) {
        for info in layerInfos {
            for subL in info.sublayerInfos as! [AGSWMSLayerInfo] {
                // initialize the WMS layer with the layer info of the top-most layer
                let wmsLayer = AGSWMSLayer(layerInfos: [subL])
                
                // populate array
                allLayers.append(wmsLayer)
            }
        }
        // reload table view
        tableView.reloadData()
    }
    
    private func showAlert(messageText:String, informativeText:String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
    }
    
    // MARK: - NSTableViewDataSource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
       return allLayers.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let wmsLayer = self.allLayers[row]
        
        let cellView = tableView.make(withIdentifier: "LayerCellView", owner: self) as! LayerCellView
        cellView.button.title = wmsLayer.name
        cellView.delegate = self
        cellView.index = row
        
        return cellView
    }
    
    // MARK: - LayerCellViewDelegate
    
    func layerCellView(_ layerCellView: LayerCellView, didToggleVisibility visible: Bool) {
        let index = layerCellView.index
        let wmsLayer = self.allLayers[index]
        wmsLayer.isVisible = visible
        
        // add or remove layer
        (wmsLayer.isVisible) ? map.operationalLayers.add(wmsLayer) : map.operationalLayers.remove(wmsLayer)
    }
}
