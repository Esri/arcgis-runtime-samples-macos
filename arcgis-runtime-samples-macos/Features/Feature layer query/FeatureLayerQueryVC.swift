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

class FeatureLayerQueryVC: NSViewController, NSTextFieldDelegate {
    
    @IBOutlet private weak var mapView:AGSMapView!
    
    private var map:AGSMap!
    private var featureTable:AGSServiceFeatureTable!
    private var featureLayer:AGSFeatureLayer!
    
    private var selectedFeatures = [AGSFeature]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize map with topographic basemap
        self.map = AGSMap(basemap: .topographic())
        //assign map to the map view
        self.mapView.map = self.map
        
        /// The url of a map service layer containing sample census data of United States counties.
        let censusMapServiceCountiesLayerURL = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Census/MapServer/2")!
        //create feature table using a url
        self.featureTable = AGSServiceFeatureTable(url: censusMapServiceCountiesLayerURL)
        //create feature layer using this feature table
        self.featureLayer = AGSFeatureLayer(featureTable: self.featureTable)
        
        //set a new renderer
        let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: .black, width: 1)
        let fillSymbol = AGSSimpleFillSymbol(style: .solid, color: NSColor.yellow.withAlphaComponent(0.5), outline: lineSymbol)
        self.featureLayer.renderer = AGSSimpleRenderer(symbol: fillSymbol)
        
        //add feature layer to the map
        self.map.operationalLayers.add(self.featureLayer)
        //zoom to a custom viewpoint
        self.mapView.setViewpointCenter(AGSPoint(x: -11e6, y: 5e6, spatialReference: AGSSpatialReference.webMercator()), scale: 9e7, completion: nil)
    }
    
    func queryForState(_ state:String) {
        //un select if any features already selected
        if self.selectedFeatures.count > 0 {
            self.featureLayer.unselectFeatures(self.selectedFeatures)
            self.selectedFeatures.removeAll()
        }
        
        //show progress indicator
        NSApp.showProgressIndicator()
        
        let queryParams = AGSQueryParameters()
        queryParams.whereClause = "upper(STATE_NAME) LIKE '%\(state.uppercased())%'"
        
        self.featureTable.queryFeatures(with: queryParams) { [weak self] (result:AGSFeatureQueryResult?, error:Error?) -> Void in
            
            //hide progress indicator
            NSApp.hideProgressIndicator()
            
            if let error = error {
                //show error
                self?.showAlert(messageText: "Error", informativeText: error.localizedDescription)
            }
            else if let features = result?.featureEnumerator().allObjects {
                if features.count > 0 {
                    self?.featureLayer.select(features)
                    //zoom to the selected feature
                    self?.mapView.setViewpointGeometry(features[0].geometry!, padding: 200, completion: nil)
                }
                else {
                    self?.showAlert(messageText: "Alert", informativeText: "No state by that name")
                }
                
                //update selected features array
                self?.selectedFeatures = features
            }
        }
    }
    
    //MARK: - NSTextFieldDelegate
    
    func controlTextDidEndEditing(_ obj: Notification) {
        if let searchField = obj.object as? NSSearchField {
            
            //if field has some value then query
            //else do nothing
            if !searchField.stringValue.isEmpty {
                self.queryForState(searchField.stringValue)
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
