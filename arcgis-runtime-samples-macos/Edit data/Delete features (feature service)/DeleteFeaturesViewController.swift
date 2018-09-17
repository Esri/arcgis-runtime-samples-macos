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

class DeleteFeaturesViewController: NSViewController, AGSGeoViewTouchDelegate, AGSCalloutDelegate {

    @IBOutlet private var mapView:AGSMapView!
    @IBOutlet private var deleteButton:NSButton!
    
    private var featureTable:AGSServiceFeatureTable!
    private var featureLayer:AGSFeatureLayer!
    private var lastQuery:AGSCancelable!
    private var selectedFeature:AGSFeature! {
        didSet {
            self.deleteButton.isEnabled = (selectedFeature != nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //instantiate map with a basemap
        let map = AGSMap(basemap: .streets())
        //set initial viewpoint
        map.initialViewpoint = AGSViewpoint(center: AGSPoint(x: 544871.19, y: 6806138.66, spatialReference: AGSSpatialReference.webMercator()), scale: 2e6)
        
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
    
    func deleteFeature(_ feature:AGSFeature) {
        //show progress indicator
        self.view.window?.showProgressIndicator()
        
        self.featureTable.delete(feature) { [weak self] (error: Error?) -> Void in
            //hide progress indicator
            self?.view.window?.hideProgressIndicator()
            
            if let error = error {
                self?.showAlert(messageText: "Error", informativeText: "Error while deleting feature : \(error.localizedDescription)")
            }
            else {
                self?.selectedFeature = nil
                self?.applyEdits()
            }
        }
    }
    
    func applyEdits() {
        //show progress indicator
        self.view.window?.showProgressIndicator()
        
        self.featureTable.applyEdits { [weak self] (featureEditResults: [AGSFeatureEditResult]?, error: Error?) -> Void in
            
            //hide progress indicator
            self?.view.window?.hideProgressIndicator()
            
            if let error = error {
                self?.showAlert(messageText: "Error", informativeText: "Error while applying edits :: \(error.localizedDescription)")
            }
            else {
                if let featureEditResults = featureEditResults , featureEditResults.count > 0 && featureEditResults[0].completedWithErrors == false {
                    print("Edits applied successfully")
                }
            }
        }
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        if let lastQuery = self.lastQuery{
            lastQuery.cancel()
        }
        
        //hide the callout
        self.mapView.callout.dismiss()
        
        //show progress indicator
        self.view.window?.showProgressIndicator()
        
        self.lastQuery = self.mapView.identifyLayer(self.featureLayer, screenPoint: screenPoint, tolerance: 5, returnPopupsOnly: false, maximumResults: 1) { [weak self] (identifyLayerResult: AGSIdentifyLayerResult) -> Void in
            
            //hide progress indicator
            self?.view.window?.hideProgressIndicator()
            
            if let error = identifyLayerResult.error {
                self?.showAlert(messageText: "Error", informativeText: error.localizedDescription)
            }
            else if let features = identifyLayerResult.geoElements as? [AGSFeature] {
                
                //clear selection
                self?.featureLayer.clearSelection()
                self?.selectedFeature = nil
                
                if features.count > 0 {
                    self?.featureLayer.select(features[0])
                    //update selected feature
                    self?.selectedFeature = features[0]
                }
            }
        }
    }
    
    //MARK: - Actions
    
    @IBAction func deleteAction(_ button: AnyObject) {
        //confirmation
        self.showConfirmationAlert()
    }
    
    //MARK: - Helper methods
    
    private func showAlert(messageText:String, informativeText:String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.beginSheetModal(for: self.view.window!)
    }
    
    private func showConfirmationAlert() {
        let alert = NSAlert()
        alert.informativeText = "Are you sure you want to delete?"
        alert.addButton(withTitle: "No")
        alert.addButton(withTitle: "Yes")
        alert.beginSheetModal(for: self.view.window!) { [weak self] (response: NSApplication.ModalResponse) in
            if response == NSApplication.ModalResponse.alertSecondButtonReturn {
                self?.deleteFeature(self!.selectedFeature)
            }
        }
    }
}
