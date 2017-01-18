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

class GenerateGeodatabaseVC: NSViewController {

    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var generateButton:NSButton!
    @IBOutlet var extentView:NSView!
    
    private var map:AGSMap!
    private let FEATURE_SERVICE_URL = NSURL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Sync/WildfireSync/FeatureServer")!
    private var syncTask:AGSGeodatabaseSyncTask!
    private var generateJob:AGSGenerateGeodatabaseJob!
    private var generatedGeodatabase:AGSGeodatabase!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let path = NSBundle.mainBundle().pathForResource("SanFrancisco", ofType: "tpk")!
        let tileCache = AGSTileCache(fileURL: NSURL(fileURLWithPath: path))
        let localTiledLayer = AGSArcGISTiledLayer(tileCache: tileCache)
        
        
        self.map = AGSMap(basemap: AGSBasemap(baseLayer: localTiledLayer))
        
        self.syncTask = AGSGeodatabaseSyncTask(URL: self.FEATURE_SERVICE_URL)
        
        self.addFeatureLayers()
        
        //setup extent view
        self.extentView.layer?.borderColor = NSColor.redColor().CGColor
        self.extentView.layer?.borderWidth = 3
        
        self.mapView.map = self.map
    }
    
    func addFeatureLayers() {
        
        self.syncTask.loadWithCompletion { [weak self] (error) -> Void in
            if let error = error {
                self?.showAlert("Error", informativeText: "Could not load feature service \(error.localizedDescription)")
            } else {
                guard let weakSelf = self else {
                    return
                }
                
                for (index, layerInfo) in weakSelf.syncTask.featureServiceInfo!.layerInfos.enumerate().reverse() {
                    
                    //For each layer in the serice, add a layer to the map
                    let layerURL = weakSelf.FEATURE_SERVICE_URL.URLByAppendingPathComponent(String(index))
                    let featureTable = AGSServiceFeatureTable(URL:layerURL!)
                    let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                    featureLayer.name = layerInfo.name
                    featureLayer.opacity = 0.65
                    weakSelf.map.operationalLayers.addObject(featureLayer)
                }
                
                //enable download
                weakSelf.generateButton.enabled = true
            }
        }
    }
    
    func frameToExtent() -> AGSEnvelope {
        let frame = self.mapView.convertRect(self.extentView.frame, fromView: self.view)
        
        let minPoint = self.mapView.screenToLocation(frame.origin)
        let maxPoint = self.mapView.screenToLocation(CGPoint(x: frame.origin.x+frame.width, y: frame.origin.y+frame.height))
        let extent = AGSEnvelope(min: minPoint, max: maxPoint)
        return extent
    }
    
    //MARK: - Actions
    
    @IBAction func generateAction(_ sender:NSButton) {
        
        //disable button
        self.generateButton.enabled = false
        
        //show progress indicator
        self.view.window?.showProgressIndicator()
        
        //generate default param to contain all layers in the service
        self.syncTask.defaultGenerateGeodatabaseParametersWithExtent(self.frameToExtent()) { [weak self] (params: AGSGenerateGeodatabaseParameters?, error: NSError?) in
            if let params = params, weakSelf = self {
                
                //hide progress indicator
                self?.view.window?.hideProgressIndicator()
                
                //don't include attachments to minimze the geodatabae size
                params.returnAttachments = false
                
                //create a unique name for the geodatabase based on current timestamp
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                
                let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
                let fullPath = "\(path)/\(dateFormatter.stringFromDate(NSDate())).geodatabase"
                
                //request a job to generate the geodatabase
                weakSelf.generateJob = weakSelf.syncTask.generateJobWithParameters(params, downloadFileURL: NSURL(string: fullPath)!)
                
                //show progress indicator
                self?.view.window?.showProgressIndicator()
                
                //kick off the job
                weakSelf.generateJob.startWithStatusHandler({ (status: AGSJobStatus) -> Void in
                    print(status.rawValue)
                }) { [weak self] (object: AnyObject?, error: NSError?) -> Void in
                    
                    //hide progress indicator
                    self?.view.window?.hideProgressIndicator()
                    
                    if let error = error {
                        self?.showAlert("Error", informativeText: error.localizedDescription)
                    }
                    else {
                        self?.generatedGeodatabase = object as! AGSGeodatabase
                        self?.displayLayersFromGeodatabase()
                    }
                }
            }
            else{
                self?.showAlert("Error", informativeText: "Could not generate default parameters : \(error!)")
            }
        }
    }
    
    func displayLayersFromGeodatabase() {
        self.generatedGeodatabase.loadWithCompletion({ [weak self] (error:NSError?) -> Void in
            
            if let error = error {
                self?.showAlert("Error", informativeText: error.localizedDescription)
            }
            else {
                self?.map.operationalLayers.removeAllObjects()
                
                AGSLoadObjects(self!.generatedGeodatabase.geodatabaseFeatureTables, { (success: Bool) in
                    if success {
                        for featureTable in self!.generatedGeodatabase.geodatabaseFeatureTables.reverse() {
                            //check if featureTable has geometry
                            if featureTable.hasGeometry {
                                let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                                self?.map.operationalLayers.addObject(featureLayer)
                            }
                        }
                        self?.showAlert("Info", informativeText: "Now showing data from geodatabase")
                    }
                })
                
                //unregister geodatabase as the sample wont be editing or syncing features
                self?.unregisterGeodatabase()
                
                //hide the extent view
                self?.extentView.hidden = true
            }
        })
    }
    
    func unregisterGeodatabase() {
        if self.generatedGeodatabase != nil {
            self.syncTask.unregisterGeodatabase(self.generatedGeodatabase) { [weak self] (error: NSError?) -> Void in
                
                if let error = error {
                    print(error.localizedDescription)
                }
                else {
                    //TODO: Show alert
                    self?.showAlert("Info", informativeText: "Geodatabase unregistered since we wont be editing it in this sample")
                }
            }
        }
    }
    
    //MARK: - Helper methods
    
    private func showAlert(messageText:String, informativeText:String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.beginSheetModalForWindow(self.view.window!, completionHandler: nil)
    }
}
