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

class GenerateOfflineMapViewController: NSViewController, AGSAuthenticationManagerDelegate {

    @IBOutlet var mapView:AGSMapView!
    @IBOutlet var extentView:NSView!
    @IBOutlet var generateButton:NSButton!
    @IBOutlet var generateButtonParentView: NSView!
    @IBOutlet var progressView:NSProgressIndicator!
    @IBOutlet var progressLabel:NSTextField!
    @IBOutlet var progressParentView:NSView!
    @IBOutlet var cancelButton:NSButton!
    
    private var portalItem:AGSPortalItem!
    private var parameters:AGSGenerateOfflineMapParameters!
    private var offlineMapTask:AGSOfflineMapTask!
    private var generateOfflineMapJob:AGSGenerateOfflineMapJob!
    private var shouldShowAlert = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //prepare the authentication manager for user login (required for taking the sample's basemap offline)
        let config = AGSOAuthConfiguration(portalURL: nil, clientID: "vVHDSfKfdKBs8lkA", redirectURL: nil)
        AGSAuthenticationManager.shared().oAuthConfigurations.add(config)
        AGSAuthenticationManager.shared().credentialCache.removeAllCredentials()
        
        //hide the progress UI initially
        progressParentView.isHidden = true
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        //show the login alert if this is the first time appearing
        if shouldShowAlert {
            shouldShowAlert = false
            showAlert()
        }
    }
    
    private func addMap() {
        
        //portal for the web map
        let portal = AGSPortal.arcGISOnline(withLoginRequired: true)
        
        //portal item for web map
        portalItem = AGSPortalItem(portal: portal, itemID: "acc027394bc84c2fb04d1ed317aac674")
        
        //map from portal item
        let map = AGSMap(item: portalItem)
        
        //assign map to the map view
        mapView.map = map
        
        //disable the bar button item until the map loads
        mapView.map?.load { [weak self] (error) in
            
            guard let strongSelf = self else{
                return
            }
            
            guard error == nil else {
                
                //show error
                if let window = strongSelf.view.window{
                    let alert = NSAlert(error: error!)
                    alert.beginSheetModal(for: window)
                }
                return
            }
            
            strongSelf.title = strongSelf.mapView.map?.item?.title
            strongSelf.generateButton.isEnabled = true
        }
        
        //instantiate offline map task
        offlineMapTask = AGSOfflineMapTask(portalItem: portalItem)
        
        //setup extent view
        extentView.layer?.borderColor = NSColor.red.cgColor
        extentView.layer?.borderWidth = 3
    }
    
    private func defaultParameters() {
        
        //default parameters for offline map task
        offlineMapTask?.defaultGenerateOfflineMapParameters(withAreaOfInterest: frameToExtent()) { [weak self] (parameters: AGSGenerateOfflineMapParameters?, error: Error?) in
            
            guard error == nil else {
                
                //show error
                if let window = self?.view.window{
                    let alert = NSAlert(error: error!)
                    alert.beginSheetModal(for: window)
                }
                return
            }
            
            guard let parameters = parameters else {
                return
            }
            
            //will need the parameters for creating the job later
            self?.parameters = parameters
            
            //take map offline
            self?.takeMapOffline()
        }
    }
    
    private func takeMapOffline() {
        
        //create a unique name for the geodatabase based on current timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let fullPath = "\(path)/\(dateFormatter.string(from: Date())).geodatabase"
        
        generateOfflineMapJob = offlineMapTask.generateOfflineMapJob(with: parameters, downloadDirectory: URL(string: fullPath)!)
        
        //add observer for progress
        generateOfflineMapJob.progress.addObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted), options: .new, context: nil)
        
        //unhide the progress parent view
        progressParentView.isHidden = false
        generateButtonParentView.isHidden = true
        
        //start the job
        generateOfflineMapJob.start(statusHandler: nil) { [weak self] (result:AGSGenerateOfflineMapResult?, error:Error?) in
            
            guard let strongSelf = self else {
                return
            }
            
            //remove KVO observer
            strongSelf.generateOfflineMapJob.progress.removeObserver(strongSelf, forKeyPath: #keyPath(Progress.fractionCompleted))
            
            if let error = error {
                //if not user cancelled
                if (error as NSError).code != NSUserCancelledError {
                    let alert = NSAlert(error: error)
                    alert.beginSheetModal(for: strongSelf.view.window!)
                }
            } else if let result = result {
                strongSelf.offlineMapGenerationDidSucceed(with: result)
            }
        }
    }
    
    /// Called when the generate offline map job finishes successfully.
    ///
    /// - Parameter result: The result of the generate offline map job.
    func offlineMapGenerationDidSucceed(with result: AGSGenerateOfflineMapResult) {
        // Show any layer or table errors to the user.
        if let layerErrors = result.layerErrors as? [AGSLayer: Error],
            let tableLayers = result.tableErrors as? [AGSFeatureTable: Error],
            !(layerErrors.isEmpty && tableLayers.isEmpty) {
            
            let errorMessages = layerErrors.map { "\($0.key.name): \($0.value.localizedDescription)" } +
                tableLayers.map { "\($0.key.displayName): \($0.value.localizedDescription)" }
            let alert = NSAlert()
            alert.messageText = "Offline Map Generated with Errors"
            alert.informativeText = "The following error(s) occurred while generating the offline map:\n\n\(errorMessages.joined(separator: "\n"))"
            alert.beginSheetModal(for: view.window!)
        }
        
        //disable cancel button
        cancelButton.isEnabled = false
        
        //assign offline map to map view
        mapView.map = result.offlineMap
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        DispatchQueue.main.async { [weak self] in
            
            guard let strongSelf = self else {
                return
            }
            
            if keyPath == "fractionCompleted" {
                
                let progress = strongSelf.generateOfflineMapJob.progress
                
                //update progress label
                strongSelf.progressLabel.stringValue = progress.localizedDescription
                
                //update progress view
                strongSelf.progressView.doubleValue = progress.fractionCompleted
            }
        }
    }
    
    //MARK: - Actions
    
    @IBAction func action(_ button:NSButton) {
        defaultParameters()
        
        //disable bar button item
        generateButton.isEnabled = false
        
        //hide the extent view
        extentView.isHidden = true
    }
    
    @IBAction func cancelAction(_ button:NSButton) {
        
        //cancel generate offline map job
        generateOfflineMapJob.progress.cancel()
        
        //reset and hide the progress UI
        progressParentView.isHidden = true
        progressView.doubleValue = 0
        progressLabel.stringValue = ""
        
        //unhide and enable the offline map button
        generateButtonParentView.isHidden = false
        generateButton.isEnabled = true
        
        //unhide the extent view
        extentView.isHidden = false
    }
    
    //MARK: - Helper methods
    
    private func showAlert() {
        let alert = NSAlert()
        alert.messageText = "This sample requires you to login in order to take the map's basemap offline. Would like to continue?"
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.beginSheetModal(for: view.window!) {[weak self] (response) in
            if response == .alertFirstButtonReturn{
                 self?.addMap()
            }
        }
    }
    
    func frameToExtent() -> AGSEnvelope {
        let frame = mapView.convert(extentView.frame, from: view)
        
        let minPoint = mapView.screen(toLocation: frame.origin)
        let maxPoint = mapView.screen(toLocation: CGPoint(x: frame.origin.x+frame.width, y: frame.origin.y+frame.height))
        let extent = AGSEnvelope(min: minPoint, max: maxPoint)
        return extent
    }
    
    deinit {
        
        guard let progress = generateOfflineMapJob?.progress else {
            return
        }
        
        let isCompleted = (progress.totalUnitCount == progress.completedUnitCount)
        let isCancelled = progress.isCancelled
        
        if !isCancelled && !isCompleted {
            //remove observer
            generateOfflineMapJob?.progress.removeObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted))
        }
    }
}
