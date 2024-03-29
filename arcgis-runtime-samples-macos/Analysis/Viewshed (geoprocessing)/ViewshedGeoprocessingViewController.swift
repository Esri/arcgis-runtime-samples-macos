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

class ViewshedGeoprocessingViewController: NSViewController, AGSGeoViewTouchDelegate {
    @IBOutlet var mapView: AGSMapView!
    
    private var geoprocessingTask: AGSGeoprocessingTask!
    private var geoprocessingJob: AGSGeoprocessingJob!
    
    private var inputGraphicsOverlay = AGSGraphicsOverlay()
    private var resultGraphicsOverlay = AGSGraphicsOverlay()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let map = AGSMap(basemapType: .topographic, latitude: 45.3790902612337, longitude: 6.84905317262762, levelOfDetail: 12)
        
        self.mapView.map = map
        
        self.mapView.touchDelegate = self
        
        //renderer for graphics overlays
        let pointSymbol = AGSSimpleMarkerSymbol(style: .circle, color: .red, size: 10)
        let renderer = AGSSimpleRenderer(symbol: pointSymbol)
        self.inputGraphicsOverlay.renderer = renderer
        
        let fillColor = NSColor(red: 226 / 255.0, green: 119 / 255.0, blue: 40 / 255.0, alpha: 120 / 255.0)
        let fillSymbol = AGSSimpleFillSymbol(style: .solid, color: fillColor, outline: nil)
        self.resultGraphicsOverlay.renderer = AGSSimpleRenderer(symbol: fillSymbol)
        
        //add graphics overlays to the map view
        self.mapView.graphicsOverlays.addObjects(from: [self.resultGraphicsOverlay, self.inputGraphicsOverlay])
        
        let viewshedURL = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Elevation/ESRI_Elevation_World/GPServer/Viewshed")!
        geoprocessingTask = AGSGeoprocessingTask(url: viewshedURL)
    }
    
    private func addGraphicForPoint(_ point: AGSPoint) {
        //remove existing graphics
        self.inputGraphicsOverlay.graphics.removeAllObjects()
        
        //new graphic
        let graphic = AGSGraphic(geometry: point, symbol: nil, attributes: nil)
        
        //add new graphic to the graphics overlay
        self.inputGraphicsOverlay.graphics.add(graphic)
    }
    
    private func calculateViewshed(at point: AGSPoint) {
        //remove previous graphics
        self.resultGraphicsOverlay.graphics.removeAllObjects()
        
        //Cancel previous job
        self.geoprocessingJob?.progress.cancel()
        
        //the service requires input of rest data type GPFeatureRecordSetLayer
        //which is AGSGeoprocessingFeatures in runtime
        //in order to create an object of AGSGeoprocessingFeatures we need a featureSet
        //for which we will create a featureCollectionTable (since feature collection table
        //is a feature set) and add the geometry as a feature to that table.
        
        //create feature collection table for point geometry
        let featureCollectionTable = AGSFeatureCollectionTable(fields: [AGSField](), geometryType: .point, spatialReference: point.spatialReference)
        
        //create a new feature and assign the geometry
        let newFeature = featureCollectionTable.createFeature()
        newFeature.geometry = point
        
        //show progress indicator
        NSApp.showProgressIndicator()
        
        //add the new feature to the feature collection table
        featureCollectionTable.add(newFeature) { [weak self] (error: Error?) in
            //hide progress indicator
            NSApp.hideProgressIndicator()
            
            if let error = error {
                self?.showAlert(messageText: "Error", informativeText: error.localizedDescription)
            } else {
                self?.performGeoprocessing(using: featureCollectionTable)
            }
        }
    }
    
    private func performGeoprocessing(using featureCollectionTable: AGSFeatureCollectionTable) {
        //geoprocessing parameters
        let params = AGSGeoprocessingParameters(executionType: .synchronousExecute)
        params.processSpatialReference = featureCollectionTable.spatialReference
        params.outputSpatialReference = featureCollectionTable.spatialReference
        
        //use the feature collection table to create the required AGSGeoprocessingFeatures input
        params.inputs["Input_Observation_Point"] = AGSGeoprocessingFeatures(featureSet: featureCollectionTable)
        
        //initialize job from geoprocessing task
        self.geoprocessingJob = self.geoprocessingTask.geoprocessingJob(with: params)
        
        //show progress indicator
        NSApp.showProgressIndicator()
        
        //start the job
        self.geoprocessingJob.start(statusHandler: { (status: AGSJobStatus) in
            print(status.rawValue)
        }, completion: { [weak self] (result: AGSGeoprocessingResult?, error: Error?) in
            //hide progress indicator
            NSApp.hideProgressIndicator()
            
            guard error == nil else {
                if (error! as NSError).code != NSUserCancelledError {
                    self?.showAlert(messageText: "Error", informativeText: error!.localizedDescription)
                }
                return
            }
            //The service returns result in form of AGSGeoprocessingFeatures
            //Cast the results and add the features from featureSet to graphics overlay
            //in form of graphics
            if let resultFeatures = result?.outputs["Viewshed_Result"] as? AGSGeoprocessingFeatures, let featureSet = resultFeatures.features {
                for feature in featureSet.featureEnumerator().allObjects {
                    let graphic = AGSGraphic(geometry: feature.geometry, symbol: nil, attributes: nil)
                    self?.resultGraphicsOverlay.graphics.add(graphic)
                }
            }
        })
    }
    
    // MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        //add a graphic in graphics overlay for the tapped point
        self.addGraphicForPoint(mapPoint)
        
        //calculate viewshed
        self.calculateViewshed(at: mapPoint)
    }
    
    // MARK: - Helper methods
    
    private func showAlert(messageText: String, informativeText: String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.beginSheetModal(for: self.view.window!)
    }
}
