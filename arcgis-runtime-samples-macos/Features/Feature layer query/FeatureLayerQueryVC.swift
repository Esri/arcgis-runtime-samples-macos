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

class FeatureLayerQueryVC: NSViewController {
    
    @IBOutlet private weak var mapView:AGSMapView!
    
    private var featureTable:AGSServiceFeatureTable?
    private var featureLayer:AGSFeatureLayer?
    
    private var selectedFeatures = [AGSFeature]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // initialize map with topographic basemap
        let map = AGSMap(basemap: .topographic())
        // assign map to the map view
        mapView.map = map
        
        /// The url of a map service layer containing sample census data of United States counties.
        let statesFeatureTableURL = URL(string: "https://services.arcgis.com/jIL9msH9OI208GCb/arcgis/rest/services/USA_Daytime_Population_2016/FeatureServer/0")!
        // create feature table using a url
        let featureTable = AGSServiceFeatureTable(url: statesFeatureTableURL)
        self.featureTable = featureTable
        
        // create feature layer using this feature table
        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
        self.featureLayer = featureLayer
        // show the layer at all scales
        featureLayer.minScale = 0
        featureLayer.maxScale = 0
        
        // set a new renderer
        let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: .black, width: 1)
        let fillSymbol = AGSSimpleFillSymbol(style: .solid, color: NSColor.yellow.withAlphaComponent(0.5), outline: lineSymbol)
        featureLayer.renderer = AGSSimpleRenderer(symbol: fillSymbol)
        
        // add feature layer to the map
        map.operationalLayers.add(featureLayer)
        
        // center the layer
        mapView.setViewpointCenter(AGSPoint(x: -11e6, y: 5e6, spatialReference: AGSSpatialReference.webMercator()), scale: 9e7)
    }
    
    private func selectFeaturesForSearchTerm(_ searchTerm:String) {
        
        guard let featureLayer = featureLayer,
            let featureTable = featureTable else {
            return
        }
        
        // deselect all selected features
        if selectedFeatures.count > 0 {
            featureLayer.unselectFeatures(selectedFeatures)
            selectedFeatures.removeAll()
        }
        
        // show progress indicator
        NSApp.showProgressIndicator()
        
        let queryParams = AGSQueryParameters()
        queryParams.whereClause = "upper(STATE_NAME) LIKE '%\(searchTerm.uppercased())%'"
        
        featureTable.queryFeatures(with: queryParams) { [weak self] (result:AGSFeatureQueryResult?, error:Error?) in
            
            // hide progress indicator
            NSApp.hideProgressIndicator()
            
            guard let self = self else {
                return
            }
            
            if let error = error {
                // display the error as an alert
                NSAlert(error: error).beginSheetModal(for: self.view.window!)
            }
            else if let features = result?.featureEnumerator().allObjects {
                if features.count > 0 {
                    // display the selection
                    featureLayer.select(features)
                    
                    // zoom to the selected feature
                    self.mapView.setViewpointGeometry(features[0].geometry!, padding: 200)
                
                } else {
                    if let fullExtent = featureLayer.fullExtent {
                        // no matches, zoom to show everything in the layer
                        self.mapView.setViewpointGeometry(fullExtent, padding: 50)
                    }
                }
                
                // update selected features array
                self.selectedFeatures = features
            }
        }
    }
    
    @IBAction func searchFieldAction(_ sender: NSSearchField) {
        let query = sender.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            selectFeaturesForSearchTerm(query)
        }
    }
}
