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

class AddFeaturesViewController: NSViewController, AGSGeoViewTouchDelegate {

    @IBOutlet private var mapView: AGSMapView!
    
    private var featureTable: AGSServiceFeatureTable!
    private var featureLayer: AGSFeatureLayer!
    private var lastQuery: AGSCancelable!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //instantiate map with a basemap
        let map = AGSMap(basemap: .streets())
        //set initial viewpoint
        map.initialViewpoint = AGSViewpoint(center: AGSPoint(x: 544871.19, y: 6806138.66, spatialReference: .webMercator()), scale: 2e6)
        
        //assign the map to the map view
        self.mapView.map = map
        //set touch delegate on map view as self
        self.mapView.touchDelegate = self
        
        //instantiate service feature table using the url to the service
        self.featureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0")!)
        //create a feature layer using the service feature table
        self.featureLayer = AGSFeatureLayer(featureTable: self.featureTable)
        
        //add the feature layer to the operational layers on map
        map.operationalLayers.add(featureLayer)
    }
    
    func addFeature(at point: AGSPoint) {
        //show progress indicator
        NSApp.showProgressIndicator()
        
        //normalize geometry
        let normalizedGeometry = AGSGeometryEngine.normalizeCentralMeridian(of: point)!
        
        //attributes for the new feature
        let featureAttributes = ["typdamage": "Minor", "primcause": "Earthquake"]
        //create a new feature
        let feature = self.featureTable.createFeature(attributes: featureAttributes, geometry: normalizedGeometry)
        
        //add the feature to the feature table
        self.featureTable.add(feature) { [weak self] (error: Error?) -> Void in
            
            //hide progress indicator
            NSApp.hideProgressIndicator()
            
            if let error = error {
                self?.showAlert(messageText: "Error", informativeText: "Error while adding feature :: \(error.localizedDescription)")
            }
            else {
                //applied edits on success
                self?.applyEdits()
            }
        }
    }
    
    func applyEdits() {
        
        //show progress indicator
        NSApp.showProgressIndicator()
        
        self.featureTable.applyEdits { [weak self] (featureEditResults: [AGSFeatureEditResult]?, error: Error?) -> Void in
            //hide progress indicator
            NSApp.hideProgressIndicator()
            
            if let error = error {
                self?.showAlert(messageText: "Error", informativeText: "Error while applying edits :: \(error.localizedDescription)")
            }
            else {
                if let featureEditResults = featureEditResults, featureEditResults.count > 0 && featureEditResults[0].completedWithErrors == false {
                    print("Edits applied successfully")
                }
            }
        }
    }
    
    // MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        
        //add a feature at the tapped location
        self.addFeature(at: mapPoint)
    }
    
    // MARK: - Helper methods
    
    private func showAlert(messageText: String, informativeText: String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.beginSheetModal(for: self.view.window!)
    }
}
