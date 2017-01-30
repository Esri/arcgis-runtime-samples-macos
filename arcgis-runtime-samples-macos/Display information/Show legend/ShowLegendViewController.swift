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

class ShowLegendViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {

    @IBOutlet private var mapView:AGSMapView!
    @IBOutlet private var outlineView:NSOutlineView!
    @IBOutlet private var legendView:NSVisualEffectView!
    
    private var map:AGSMap!
    private var mapImageLayer:AGSArcGISMapImageLayer!
    var legendInfosDict = [String:[AGSLegendInfo]]()
    private var orderArray:[AGSLayerContent]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize the map
        self.map = AGSMap(basemap: AGSBasemap.topographic())
        
        //create tiled layer
        let tiledLayer = AGSArcGISTiledLayer(url: URL(string: "https://services.arcgisonline.com/ArcGIS/rest/services/Specialty/Soil_Survey_Map/MapServer")!)
        self.map.operationalLayers.add(tiledLayer)
        
        //create a map image layer using a url
        self.mapImageLayer = AGSArcGISMapImageLayer(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Census/MapServer")!)
        //add the image layer to the map
        self.map.operationalLayers.add(self.mapImageLayer)
        
        //create feature table using a url
        let featureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Recreation/FeatureServer/0")!)
        //create feature layer using this feature table
        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
        //add feature layer to the map
        self.map.operationalLayers.add(featureLayer)
        
        AGSLoadObjects(self.map.operationalLayers as AnyObject as! [AGSLayer]) { [weak self] (success) in
            if let weakSelf = self {
                self?.orderArray = [AGSLayerContent]()
                self?.populateLegends(weakSelf.map.operationalLayers as AnyObject as! [AGSLayerContent])
            }
        }
        
        self.mapView.map = self.map
        
        //zoom to a custom viewpoint
        self.mapView.setViewpointCenter(AGSPoint(x: -11e6, y: 6e6, spatialReference: AGSSpatialReference.webMercator()), scale: 9e7, completion: nil)
    }
    
    func populateLegends(_ layers:[AGSLayerContent]) {
        
        for i in 0...layers.count-1 {
            let layer = layers[i]
            
            if layer.subLayerContents.count > 0 {
                self.populateLegends(layer.subLayerContents)
            }
            else {
                //else if no sublayers fetch legend info
                self.orderArray.append(layer)
                
                //show progress indicator
                self.view.window?.showProgressIndicator()
                
                layer.fetchLegendInfos(completion: { [weak self] (legendInfos:[AGSLegendInfo]?, error:Error?) -> Void in
                
                    //hide progress indicator
                    self?.view.window?.hideProgressIndicator()
                    
                    if let error = error {
                        print(error)
                    }
                    else {
                        if let legendInfos = legendInfos {
                            self?.legendInfosDict[self!.hashString(layer)] = legendInfos
                            self?.outlineView.reloadData()
                        }
                    }
                })
            }
            
            //stylize legend view
            self.legendView.wantsLayer = true
            self.legendView.layer?.borderColor = NSColor.gray.cgColor
            self.legendView.layer?.borderWidth = 1
            
            //unhide legend view
            self.legendView.isHidden = false
        }
    }
    
    //MARK: - NSOutlineViewDataSource
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil { //root
            return self.orderArray?.count ?? 0
        }
        else {
            if let layerContent = item as? AGSLayerContent {
                if layerContent.subLayerContents.count > 0 {
                    return layerContent.subLayerContents.count
                }
                else {
                    //return legend infos
                    let legendInfos = self.legendInfosDict[self.hashString(layerContent)]!
                    return legendInfos.count
                }
            }
            else {
                return 0
            }
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            let layer = self.orderArray[index]
            return layer
        }
        else {
            let layer = item as! AGSLayerContent
            let legendInfos = self.legendInfosDict[self.hashString(layer)]!
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
    
    //MARK: - NSOutlineViewDelegate
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        
        if let layer = item as? AGSLayerContent {
            let cellView = outlineView.make(withIdentifier: "LegendGroupCell", owner: self) as! NSTableCellView
            cellView.textField?.stringValue = self.nameForLayerContent(layer)
            return cellView
        }
        else {
            let cellView = outlineView.make(withIdentifier: "LegendCellView", owner: self) as! LegendCellView

            let legendInfo = item as! AGSLegendInfo
            cellView.legendInfo = legendInfo
            
            return cellView
        }
    }
    
    //MARK: - Helper functions
    
    func geometryTypeForSymbol(_ symbol:AGSSymbol) -> AGSGeometryType {
        if symbol is AGSFillSymbol {
            return AGSGeometryType.polygon
        }
        else if symbol is AGSLineSymbol {
            return .polyline
        }
        else {
            return .point
        }
    }
    
    func hashString (_ obj: AnyObject) -> String {
        return String(UInt(bitPattern: ObjectIdentifier(obj)))
    }
    
    func nameForLayerContent(_ layerContent:AGSLayerContent) -> String {
        if let layer = layerContent as? AGSLayer {
            return layer.name
        }
        else {
            return (layerContent as! AGSArcGISSublayer).name
        }
    }
}
