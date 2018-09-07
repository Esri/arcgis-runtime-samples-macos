//
// Copyright 2018 Esri.
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

    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var extentView: NSView!
    @IBOutlet var generateButton: NSButton!
    @IBOutlet var generateButtonParentView: NSView!
    @IBOutlet var progressView: NSProgressIndicator!
    @IBOutlet var progressLabel: NSTextField!
    @IBOutlet var progressParentView: NSView!
    @IBOutlet var cancelButton: NSButton!
    
    private var portalItem: AGSPortalItem?
    private var parameters: AGSGenerateOfflineMapParameters?
    private var offlineMapTask: AGSOfflineMapTask?
    private var generateOfflineMapJob: AGSGenerateOfflineMapJob?
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
            showLoginQueryAlert()
        }
    }
    
    private func addMap() {
        
        //portal for the web map
        let portal = AGSPortal.arcGISOnline(withLoginRequired: true)
        
        //portal item for web map
        let portalItem = AGSPortalItem(portal: portal, itemID: "acc027394bc84c2fb04d1ed317aac674")
        self.portalItem = portalItem
        
        //map from portal item
        let map = AGSMap(item: portalItem)
        
        //assign map to the map view
        mapView.map = map
        
        //load the map asynchronously
        mapView.map?.load { [weak self] (error) in
            
            guard let strongSelf = self else{
                return
            }
            
            if let error = error{
                //if not user cancelled
                if (error as NSError).code != NSUserCancelledError,
                    let window = strongSelf.view.window{
                    let alert = NSAlert(error: error)
                    //display error as alert
                    alert.beginSheetModal(for: window)
                }
            }
            else{
                strongSelf.title = strongSelf.mapView.map?.item?.title
                strongSelf.generateButton.isEnabled = true
            }
        }
        
        //instantiate offline map task
        offlineMapTask = AGSOfflineMapTask(portalItem: portalItem)
        
        //setup extent view
        extentView.layer?.borderColor = NSColor.red.cgColor
        extentView.layer?.borderWidth = 3
    }
    
    private func takeMapOffline() {
        
        guard let offlineMapTask = offlineMapTask,
            let parameters = parameters else{
                return
        }

        let downloadDirectory = getNewOfflineGeodatabaseURL()
        let generateOfflineMapJob = offlineMapTask.generateOfflineMapJob(with: parameters,
                                                                         downloadDirectory: downloadDirectory)
        self.generateOfflineMapJob = generateOfflineMapJob
        
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
            strongSelf.generateOfflineMapJob?.progress.removeObserver(strongSelf, forKeyPath: #keyPath(Progress.fractionCompleted))
            
            if let error = error {
                //if not user cancelled
                if (error as NSError).code != NSUserCancelledError,
                    let window = strongSelf.view.window{
                    let alert = NSAlert(error: error)
                    //display error as alert
                    alert.beginSheetModal(for: window)
                }
            }
            else if let result = result {
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
            let tableErrors = result.tableErrors as? [AGSFeatureTable: Error],
            !(layerErrors.isEmpty && tableErrors.isEmpty) {
            
            let errorMessages = layerErrors.map { "\($0.key.name): \($0.value.localizedDescription)" } +
                tableErrors.map { "\($0.key.displayName): \($0.value.localizedDescription)" }
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
        
        if keyPath == #keyPath(Progress.fractionCompleted) {
            
            //run UI updates on the main thread
            DispatchQueue.main.async { [weak self] in
                    
                guard let strongSelf = self,
                     let progress = strongSelf.generateOfflineMapJob?.progress else {
                    return
                }
                
                //update progress label
                strongSelf.progressLabel.stringValue = progress.localizedDescription
                
                //update progress view
                strongSelf.progressView.doubleValue = progress.fractionCompleted
            }
        }
    }
    
    //MARK: - Actions
    
    @IBAction func generateOfflineMapAction(_ button:NSButton) {
        
        //disable the offline map button
        generateButton.isEnabled = false
        
        //hide the extent view
        extentView.isHidden = true
        
        //get the area outlined by the extent view
        let areaOfInterest = extentViewFrameToEnvelope()
        
        //build the default parameters for the offline map task
        offlineMapTask?.defaultGenerateOfflineMapParameters(withAreaOfInterest: areaOfInterest) { [weak self] (parameters: AGSGenerateOfflineMapParameters?, error: Error?) in
            
            guard let strongSelf = self else{
                return
            }
            
            if let error = error {
                
                if let window = strongSelf.view.window{
                    let alert = NSAlert(error: error)
                    //display error as alert
                    alert.beginSheetModal(for: window)
                }
            }
            else{
                //save the parameters to use later
                strongSelf.parameters = parameters
                
                //take map offline now that we have the parameters
                strongSelf.takeMapOffline()
            }
        }
    }
    
    @IBAction func cancelAction(_ button:NSButton) {
        
        //cancel generate offline map job
        generateOfflineMapJob?.progress.cancel()
        
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
    
    private func showLoginQueryAlert() {
        let alert = NSAlert()
        alert.messageText = "This sample requires you to login in order to take the map's basemap offline. Would you like to continue?"
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.beginSheetModal(for: view.window!) {[weak self] (response) in
            if response == .alertFirstButtonReturn{
                 self?.addMap()
            }
        }
    }
    
    private func extentViewFrameToEnvelope() -> AGSEnvelope {
        
        let frame = mapView.convert(extentView.frame, from: view)
        
        //the lower-left corner
        let minPoint = mapView.screen(toLocation: frame.origin)
        
        //the upper-right corner
        let maxPoint = mapView.screen(toLocation: CGPoint(x: frame.maxX, y: frame.maxY))
        
        //return the envenlope covering the entire extent frame
        return AGSEnvelope(min: minPoint, max: maxPoint)
    }
    
    private func getNewOfflineGeodatabaseURL()->URL{
       
        //get a suitable directory to place files
        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        //create a unique name for the geodatabase based on current timestamp
        let formattedDate = ISO8601DateFormatter().string(from: Date())
        
        return documentDirectoryURL.appendingPathComponent("\(formattedDate).geodatabase")
    }
    
    deinit {
        
        guard let progress = generateOfflineMapJob?.progress else {
            return
        }
        
        let isCompleted = (progress.totalUnitCount == progress.completedUnitCount)
        let isCancelled = progress.isCancelled
        
        if !isCancelled && !isCompleted {
            //remove observer
            progress.removeObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted))
        }
    }
}
