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

import AppKit
import ArcGIS

class DownloadPreplannedMapViewController: NSViewController, AGSAuthenticationManagerDelegate {

    @IBOutlet weak var mapView: AGSMapView!
    
    @IBOutlet weak var popUpButton: NSPopUpButton!
    @IBOutlet weak var removeDownloadsButton: NSButton!
    
    private var offlineMapTask: AGSOfflineMapTask?
    private var downloadPreplannedMapJob: AGSDownloadPreplannedOfflineMapJob?
    private var portalItem: AGSPortalItem?
    private var shouldShowAlert = true
    
    var localAreaURLs: [String: URL] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //prepare the authentication manager for user login (required for downloading the sample's basemap)
        //let config = AGSOAuthConfiguration(portalURL: nil, clientID: "vVHDSfKfdKBs8lkA", redirectURL: nil)
        //AGSAuthenticationManager.shared().oAuthConfigurations.add(config)
        //AGSAuthenticationManager.shared().credentialCache.removeAllCredentials()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        //show the login alert if this is the first time appearing
       /* if shouldShowAlert {
            shouldShowAlert = false
            showLoginQueryAlert()
        }*/
        loadMap()
    }
    
    private func showLoginQueryAlert() {
        let alert = NSAlert()
        alert.messageText = "This sample requires you to login in order to take the map's basemap offline. Would you like to continue?"
        alert.addButton(withTitle: "Login")
        alert.addButton(withTitle: "Cancel")
        alert.beginSheetModal(for: view.window!) {[weak self] (response) in
            if response == .alertFirstButtonReturn {
                self?.loadMap()
            }
        }
    }
    
    private func loadMap() {
        
        //portal for the web map
        let portal = AGSPortal.arcGISOnline(withLoginRequired: false)
        
        //portal item for web map
        let portalItem = AGSPortalItem(portal: portal, itemID: "acc027394bc84c2fb04d1ed317aac674")
        self.portalItem = portalItem
        
        loadMapForPortalItem()
        
        //load the map asynchronously
        mapView.map?.load { [weak self] (error) in
            
            guard let self = self else {
                return
            }
            
            if let error = error {
                //if not user cancelled
                if (error as NSError).code != NSUserCancelledError {
                    //display error as alert
                    NSAlert(error: error).beginSheetModal(for: self.view.window!)
                }
            }
            
        }
        
        //instantiate offline map task
        let offlineMapTask = AGSOfflineMapTask(portalItem: portalItem)
        self.offlineMapTask = offlineMapTask
        offlineMapTask.getPreplannedMapAreas(completion: {[weak self] (preplannedMapAreas, error) in
            guard let self = self else {
                return
            }
            guard error == nil else {
                NSAlert(error: error!).beginSheetModal(for: self.view.window!)
                return
            }
            guard let preplannedMapAreas = preplannedMapAreas else {
                return
            }
            for area in preplannedMapAreas {
                let menuItem = NSMenuItem()
                menuItem.title = area.portalItem!.title
                menuItem.representedObject = area
                menuItem.indentationLevel = 1
                self.popUpButton.menu?.addItem(menuItem)
            }
            self.popUpButton.isEnabled = true
            self.view.layout()
        })
    }
    
    private func loadMapForPortalItem() {
        if let portalItem = portalItem {
            //map from portal item
            let map = AGSMap(item: portalItem)
            //assign map to the map view
            mapView.map = map
        }
    }
    
    // MARK: - Preplanned map download
    
    func downloadPreplannedMapArea(_ preplannedMapArea: AGSPreplannedMapArea) {
        
        guard let offlineMapTask = offlineMapTask else {
            return
        }
        
        let directorURL = preplannedMapLocalURL(for: preplannedMapArea)
        
        guard !FileManager.default.fileExists(atPath: directorURL.path) else {
            loadDownloadedMap(at: directorURL)
            return
        }
        
        let downloadPreplannedMapJob = offlineMapTask.downloadPreplannedOfflineMapJob(with: preplannedMapArea,
                                                                                      downloadDirectory: directorURL)
        self.downloadPreplannedMapJob = downloadPreplannedMapJob
        
        //show the progress sheet
        let progressController = ProgressViewController(progress: downloadPreplannedMapJob.progress, operationLabel: "Downloading Preplanned Map Area")
        presentAsSheet(progressController)
        
        //start the job
        downloadPreplannedMapJob.start(statusHandler: nil) { [weak self] (result: AGSDownloadPreplannedOfflineMapResult?, error: Error?) in
            
            //close the progress sheet since the job is no longer active
            progressController.dismiss(self)
            
            guard let self = self else {
                return
            }
            
            if let error = error {
                //if not user cancelled
                if (error as NSError).code != NSUserCancelledError,
                    let window = self.view.window {
                    //display error as alert
                    NSAlert(error: error).beginSheetModal(for: window)
                }
            } else if let result = result {
                self.preplannedMapDownloadDidSucceed(with: result)
            }
        }
    }
    
    private func loadDownloadedMap(at url: URL) {
        let package = AGSMobileMapPackage(fileURL: url)
        package.load {[weak self] (error) in
            if error == nil,
                let map = package.maps.first {
                self?.mapView.map = map
            }
        }
    }
    
    /// Called when a preplanned map downloads successfully.
    ///
    /// - Parameter result: The result of the download preplanned map job.
    private func preplannedMapDownloadDidSucceed(with result: AGSDownloadPreplannedOfflineMapResult) {
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
        
        removeDownloadsButton.isEnabled = true
    }

    // MARK: - Actions
    
    @IBAction func popUpButtonAction(_ sender: NSPopUpButton) {
        if let selectedItem = sender.selectedItem,
            let preplannedMapArea = selectedItem.representedObject as? AGSPreplannedMapArea {
            downloadPreplannedMapArea(preplannedMapArea)
        } else {
           loadMapForPortalItem()
        }
    }

    @IBAction func removeDownloadsButtonAction(_ sender: NSButton) {
        for url in localAreaURLs.values {
            try? FileManager.default.removeItem(at: url)
        }
        localAreaURLs = [:]
        loadMapForPortalItem()
        popUpButton.selectItem(at: 0)
        sender.isEnabled = false
    }
    
    // MARK: - Helper methods
    
    private func preplannedMapLocalURL(for preplannedMapArea: AGSPreplannedMapArea) -> URL {
        
        let areaID = preplannedMapArea.portalItem!.itemID
        
        if let url = localAreaURLs[areaID] {
            return url
        } else {
            //get a suitable directory to place files
            let directoryURL = FileManager.default.temporaryDirectory
            
            //create a unique name for the geodatabase based on current timestamp
            let formattedDate = ISO8601DateFormatter().string(from: Date())
            let url = directoryURL.appendingPathComponent("preplanned-map-\(formattedDate).geodatabase")
            localAreaURLs[areaID] = url
            return url
        }
    }
    
}
