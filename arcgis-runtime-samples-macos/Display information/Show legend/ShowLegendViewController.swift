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

class ShowLegendViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {

    @IBOutlet private var mapView: AGSMapView!
    @IBOutlet private var outlineView: NSOutlineView!
    @IBOutlet private var legendView: NSVisualEffectView!
    
    private var map: AGSMap!
    private var mapImageLayer: AGSArcGISMapImageLayer!
    var legendInfosDict = [String: [AGSLegendInfo]]()
    private var orderArray = [AGSLayerContent]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize the map
        self.map = AGSMap(basemap: .topographic())
        
        //create tiled layer
        let tiledLayer = AGSArcGISTiledLayer(url: URL(string: "https://services.arcgisonline.com/ArcGIS/rest/services/Specialty/Soil_Survey_Map/MapServer")!)
        self.map.operationalLayers.add(tiledLayer)
        
        /// The url of a map service containing sample census data of the United States.
        let censusMapServiceURL = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Census/MapServer")!
        //create a map image layer using a url
        self.mapImageLayer = AGSArcGISMapImageLayer(url: censusMapServiceURL)
        //add the image layer to the map
        self.map.operationalLayers.add(self.mapImageLayer)
        
        //create feature table using a url
        let featureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Recreation/FeatureServer/0")!)
        //create feature layer using this feature table
        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
        //add feature layer to the map
        self.map.operationalLayers.add(featureLayer)
        
        AGSLoadObjects(self.map.operationalLayers as! [AGSLayer]) { [weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.orderArray.removeAll()
            strongSelf.populateLegends(with: strongSelf.map.operationalLayers as! [AGSLayerContent])
        }
        
        self.mapView.map = self.map
        
        //zoom to a custom viewpoint
        self.mapView.setViewpointCenter(AGSPoint(x: -11e6, y: 6e6, spatialReference: .webMercator()), scale: 9e7)
    }
    
    func populateLegends<S: Sequence>(with layers: S) where S.Element == AGSLayerContent {
        for layer in layers {
            if !layer.subLayerContents.isEmpty {
                populateLegends(with: layer.subLayerContents)
            } else {
                //else if no sublayers fetch legend info
                orderArray.append(layer)
                
                //show progress indicator
                NSApp.showProgressIndicator()
                
                layer.fetchLegendInfos { [weak self] (legendInfos: [AGSLegendInfo]?, error: Error?) -> Void in
                    guard let strongSelf = self else { return }
                    //hide progress indicator
                    NSApp.hideProgressIndicator()
                    
                    if let error = error {
                        print(error)
                    } else if let legendInfos = legendInfos {
                        strongSelf.legendInfosDict[strongSelf.hashString(for: layer)] = legendInfos
                        strongSelf.outlineView.reloadData()
                    }
                }
            }
            
            //stylize legend view
            legendView.wantsLayer = true
            legendView.layer?.borderColor = NSColor.gray.cgColor
            legendView.layer?.borderWidth = 1
            
            //unhide legend view
            legendView.isHidden = false
        }
    }
    
    // MARK: - NSOutlineViewDataSource
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil { //root
            return orderArray.count
        } else {
            if let layerContent = item as? AGSLayerContent {
                if !layerContent.subLayerContents.isEmpty {
                    return layerContent.subLayerContents.count
                } else {
                    //return legend infos
                    let legendInfos = self.legendInfosDict[self.hashString(for: layerContent)]!
                    return legendInfos.count
                }
            } else {
                return 0
            }
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            let layer = self.orderArray[index]
            return layer
        } else {
            let layer = item as! AGSLayerContent
            let legendInfos = self.legendInfosDict[self.hashString(for: layer)]!
            let legendInfo = legendInfos[index]
            return legendInfo
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return (item is AGSLayerContent)
    }
    
    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        return (item is AGSLayerContent)
    }
    
    // MARK: - NSOutlineViewDelegate
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        
        if let layer = item as? AGSLayerContent {
            let cellView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "LegendGroupCell"), owner: self) as! NSTableCellView
            cellView.textField?.stringValue = self.nameForLayerContent(layer)
            return cellView
        } else {
            let cellView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "LegendCellView"), owner: self) as! LegendCellView

            let legendInfo = item as! AGSLegendInfo
            cellView.legendInfo = legendInfo
            
            return cellView
        }
    }
    
    // MARK: - Helper functions
    
    func geometryTypeForSymbol(_ symbol: AGSSymbol) -> AGSGeometryType {
        if symbol is AGSFillSymbol {
            return AGSGeometryType.polygon
        } else if symbol is AGSLineSymbol {
            return .polyline
        } else {
            return .point
        }
    }
    
    func hashString (for obj: AnyObject) -> String {
        return String(UInt(bitPattern: ObjectIdentifier(obj)))
    }
    
    func nameForLayerContent(_ layerContent: AGSLayerContent) -> String {
        if let layer = layerContent as? AGSLayer {
            return layer.name
        } else {
            return (layerContent as! AGSArcGISSublayer).name
        }
    }
}
