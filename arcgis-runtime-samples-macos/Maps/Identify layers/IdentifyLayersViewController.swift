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

class IdentifyLayersViewController: NSViewController, AGSGeoViewTouchDelegate {
    
    @IBOutlet var mapView: AGSMapView!
    
    private var map:AGSMap!
    
    private var featureLayer:AGSFeatureLayer!
    private var mapImageLayer:AGSArcGISMapImageLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //create an instance of a map
        self.map = AGSMap(basemap: .topographic())
        
        //map image layer
        self.mapImageLayer = AGSArcGISMapImageLayer(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/SampleWorldCities/MapServer")!)
        
        //hide Continent and World layers
        self.mapImageLayer.load { [weak self] (error: Error?) in
            if error == nil {
                self?.mapImageLayer.subLayerContents[1].isVisible = false
                self?.mapImageLayer.subLayerContents[2].isVisible = false
            }
        }
        self.map.operationalLayers.add(self.mapImageLayer)
        
        //feature table
        let featureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0")!)
        
        //feature layer
        self.featureLayer = AGSFeatureLayer(featureTable: featureTable)
        
        
        //add feature layer add to the operational layers
        self.map.operationalLayers.add(self.featureLayer)
        
        //set initial viewpoint to a specific region
        self.map.initialViewpoint = AGSViewpoint(center: AGSPoint(x: -10977012.785807, y: 4514257.550369, spatialReference: AGSSpatialReference(wkid: 3857)), scale: 68015210)
        
        //assign map to the map view
        self.mapView.map = self.map
        
        //add self as the touch delegate for the map view
        self.mapView.touchDelegate = self
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        //get the geoElements for all layers present at the tapped point
        self.identifyLayers(at: screenPoint)
    }
    
    //MARK: - Identify layers
    
    private func identifyLayers(at screenPoint: CGPoint) {
        //show progress indicator
        self.view.window?.showProgressIndicator()
        
        self.mapView.identifyLayers(atScreenPoint: screenPoint, tolerance: 22, returnPopupsOnly: false, maximumResultsPerLayer: 10) { [weak self] (results: [AGSIdentifyLayerResult]?, error: Error?) in
            
            //hide progress indicator
            self?.view.window?.hideProgressIndicator()
            
            if let error = error {
                self?.showAlert(messageText: "Error", informativeText: error.localizedDescription)
            }
            else {
                self?.handleIdentifyResults(results!)
            }
        }
    }
    
    //MARK: - Helper methods
    
    private func handleIdentifyResults(_ results: [AGSIdentifyLayerResult]) {
        
        var messageString = ""
        var totalCount = 0
        for identifyLayerResult in results {
            let count = self.geoElementsCountFromResult(identifyLayerResult)
            let layerName = identifyLayerResult.layerContent.name
            messageString.append("\(layerName) :: \(count)")
            
            //add new line character if not the final element in array
            if identifyLayerResult != results.last! {
                messageString.append("\n")
            }
            
            //update total count
            totalCount += count
        }
        
        //if any elements were found show the results
        //else notify user that no elements were found
        if totalCount > 0 {
            self.showAlert(messageText: "Number of geoElements found", informativeText: messageString)
        }
        else {
            self.showAlert(messageText: "Error", informativeText: "No geoElement found")
        }
    }
    
    private func geoElementsCountFromResult(_ result: AGSIdentifyLayerResult) -> Int {
        //create temp array
        var tempResults = [result]
        
        //using Depth First Search approach to handle recursion
        var count = 0
        var index = 0
        
        while index < tempResults.count {
            //get the result object from the array
            let identifyResult = tempResults[index]
            
            //update count with geoElements from the result
            count += identifyResult.geoElements.count
            
            //check if the result has any sublayer results
            //if yes then add those result objects in the tempResults
            //array after the current result
            if identifyResult.sublayerResults.count > 0 {
                tempResults.insert(contentsOf: identifyResult.sublayerResults, at: index + 1)
            }
            
            //update the count and repeat
            index += 1
        }
        
        return count
    }
    
    //helper method to show results to the user
    private func showAlert(messageText:String, informativeText:String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.beginSheetModal(for: self.view.window!)
    }
}
