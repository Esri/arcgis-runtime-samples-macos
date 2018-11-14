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

class GenerateGeodatabaseVC: NSViewController {

    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var generateButton: NSButton!
    @IBOutlet var extentView: NSView!
    
    private var syncTask: AGSGeodatabaseSyncTask = {
        let featureServiceURL = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Sync/WildfireSync/FeatureServer")!
        return AGSGeodatabaseSyncTask(url: featureServiceURL)
    }()
    private var generatedGeodatabase: AGSGeodatabase?
    // must keep a strong reference to jobs while they run
    private var activeJob: AGSJob?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tpkURL = Bundle.main.url(forResource: "SanFrancisco", withExtension: "tpk")!
        let tileCache = AGSTileCache(fileURL: tpkURL)
        let localTiledLayer = AGSArcGISTiledLayer(tileCache: tileCache)
        
        let map = AGSMap(basemap: AGSBasemap(baseLayer: localTiledLayer))
        mapView.map = map
        addFeatureLayers()
        
        //setup extent view
        extentView.wantsLayer = true
        extentView.layer?.borderColor = NSColor.red.cgColor
        extentView.layer?.borderWidth = 3
    }
    
    private func addFeatureLayers() {
        syncTask.load { [weak self] (error) -> Void in
            if let error = error {
                self?.showAlert(messageText: "Error", informativeText: "Could not load feature service \(error.localizedDescription)")
            } else {
                guard let self = self else {
                    return
                }
                
                for (index, layerInfo) in self.syncTask.featureServiceInfo!.layerInfos.enumerated().reversed() {
                   
                    //For each layer in the serice, add a layer to the map
                    let layerURL = self.syncTask.url!.appendingPathComponent(String(index))
                    let featureTable = AGSServiceFeatureTable(url: layerURL)
                    let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                    featureLayer.name = layerInfo.name
                    featureLayer.opacity = 0.65
                    self.mapView.map?.operationalLayers.add(featureLayer)
                }
                
                //enable download
                self.generateButton.isEnabled = true
            }
        }
    }
    
    private func frameToExtent() -> AGSEnvelope {
        let frame = mapView.convert(extentView.frame, from: view)
        let minPoint = mapView.screen(toLocation: frame.origin)
        let maxPoint = mapView.screen(toLocation: CGPoint(x: frame.maxX, y: frame.maxY))
        let extent = AGSEnvelope(min: minPoint, max: maxPoint)
        return extent
    }
    
    // MARK: - Actions
    
    @IBAction func generateAction(_ sender: NSButton) {
        
        //show progress indicator
        NSApp.showProgressIndicator()
        
        //generate default param to contain all layers in the service
        syncTask.defaultGenerateGeodatabaseParameters(withExtent: self.frameToExtent()) { [weak self] (params: AGSGenerateGeodatabaseParameters?, error: Error?) in
            if let params = params,
                let self = self {
                
                //hide progress indicator
                NSApp.hideProgressIndicator()
                
                //don't include attachments to minimze the geodatabae size
                params.returnAttachments = false
                
                //create a unique name for the geodatabase based on current timestamp
                let dateFormatter = ISO8601DateFormatter()
                
                let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let downloadFileURL = documentDirectoryURL
                    .appendingPathComponent(dateFormatter.string(from: Date()))
                    .appendingPathExtension("geodatabase")
                
                //request a job to generate the geodatabase
                let generateJob = self.syncTask.generateJob(with: params, downloadFileURL: downloadFileURL)
                self.activeJob = generateJob
                
                //show progress bar
                let progressController = ProgressViewController(progress: generateJob.progress, operationLabel: "Generating Geodatabase")
                self.presentAsSheet(progressController)
                
                //kick off the job
                generateJob.start(statusHandler: nil) { [weak self] (object: AnyObject?, error: Error?) -> Void in
                    
                    //hide progress bar
                    progressController.dismiss(self)
                    
                    guard let self = self else {
                        return
                    }
                    
                    self.activeJob = nil
                    
                    if let error = error {
                        if (error as NSError).code != NSUserCancelledError {
                            self.showAlert(messageText: "Error", informativeText: error.localizedDescription)
                        }
                    }
                    else if let geodatabase = object as? AGSGeodatabase {
                        self.generatedGeodatabase = geodatabase
                        self.displayLayersFromGeodatabase()
                    }
                }
            }
            else {
                self?.showAlert(messageText: "Error", informativeText: "Could not generate default parameters: \(error!)")
            }
        }
    }
    
    func displayLayersFromGeodatabase() {
        guard let generatedGeodatabase = generatedGeodatabase else {
            return
        }
        generatedGeodatabase.load(completion: { [weak self] (error: Error?) -> Void in
            
            guard let self = self else {
                return
            }
            
            if let error = error {
                self.showAlert(messageText: "Error", informativeText: error.localizedDescription)
            }
            else {
                self.mapView.map?.operationalLayers.removeAllObjects()
                
                AGSLoadObjects(generatedGeodatabase.geodatabaseFeatureTables) { (success: Bool) in
                    if success {
                        for featureTable in generatedGeodatabase.geodatabaseFeatureTables.reversed() {
                            //check if featureTable has geometry
                            if featureTable.hasGeometry {
                                let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                                self.mapView.map?.operationalLayers.add(featureLayer)
                            }
                        }
                        //disable button
                        self.generateButton.isEnabled = false
                        //hide the extent view
                        self.extentView.isHidden = true
                        
                        self.showAlert(messageText: "Info", informativeText: "Now showing data from geodatabase.")
                    }
                    
                    //unregister geodatabase as the sample wont be editing or syncing features
                    self.syncTask.unregisterGeodatabase(generatedGeodatabase)
                }
            }
        })
    }
    
    // MARK: - Helper methods
    
    private func showAlert(messageText: String, informativeText: String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.beginSheetModal(for: self.view.window!)
    }
    
}
