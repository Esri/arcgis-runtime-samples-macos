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

protocol OfflineMapProgressViewControllerDelegate: AnyObject {
    
    func progressViewControllerDidCancel(_ progressViewController:OfflineMapProgressViewController)
}

class GenerateOfflineMapViewController: NSViewController, AGSAuthenticationManagerDelegate {

    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var extentView: NSView!
    @IBOutlet var generateButton: NSButton!
    @IBOutlet var generateButtonParentView: NSView!
    
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
        
        //show the progress sheet
        showProgressSheet(for: generateOfflineMapJob.progress)
        
        //start the job
        generateOfflineMapJob.start(statusHandler: nil) { [weak self] (result:AGSGenerateOfflineMapResult?, error:Error?) in
            
            guard let strongSelf = self else {
                return
            }
            
            //close the progress sheet since the job is no longer active
            strongSelf.closeProgressSheet()
            
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
    
    private func showProgressSheet(for progress: Progress){
        
        //locate and instantiate the view controller
        let storyboard = NSStoryboard(name: NSStoryboard.Name("GenerateOfflineMap"), bundle: nil)
        let id = NSStoryboard.SceneIdentifier("OfflineMapProgressViewController")
        let viewController = storyboard.instantiateController(withIdentifier: id) as! OfflineMapProgressViewController
        
        //setup the progress view controller
        viewController.progress = progress
        viewController.delegate = self
        
        //display the progress sheet
        presentViewControllerAsSheet(viewController)
    }
    
    private func closeProgressSheet(){
        
        //find and dismiss the view controller
        if let progressViewController = presentedViewControllers?.first(where: { (controller) -> Bool in
            return controller is OfflineMapProgressViewController
        }){
            dismissViewController(progressViewController)
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
        
        //assign offline map to map view
        mapView.map = result.offlineMap
    }
    
    //MARK: - Actions
    
    @IBAction func generateOfflineMapAction(_ button:NSButton) {
        
        //hide and disable the offline map button
        generateButton.isEnabled = false
        generateButtonParentView.isHidden = true
        
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
    
}

extension GenerateOfflineMapViewController: OfflineMapProgressViewControllerDelegate {
    
    func progressViewControllerDidCancel(_ progressViewController: OfflineMapProgressViewController) {
        
        //cancel generate offline map job
        generateOfflineMapJob?.progress.cancel()
        
        //unhide and enable the offline map button
        generateButtonParentView.isHidden = false
        generateButton.isEnabled = true
        
        //unhide the extent view
        extentView.isHidden = false
    }
}
