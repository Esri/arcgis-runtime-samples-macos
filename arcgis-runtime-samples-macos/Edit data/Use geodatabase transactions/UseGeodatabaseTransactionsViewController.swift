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

class UseGeodatabaseTransactionsViewController: NSViewController {

    @IBOutlet private var mapView:AGSMapView!
    
    @IBOutlet weak var featureTypePopUp: NSPopUpButton!
    @IBOutlet weak var startTransactionButton: NSButton!
    @IBOutlet weak var rollbackTransactionButton: NSButton!
    @IBOutlet weak var synchronizeButton: NSButton!
    @IBOutlet weak var commitTransactionButton: NSButton!
    @IBOutlet weak var transactionsRequiredCheckbox: NSButton!
    
    /// The sync task used to download and upload the geodatabase data.
    private var geodatabaseSyncTask: AGSGeodatabaseSyncTask?
    /// The local geodatabase created using the sync task.
    private var geodatabase: AGSGeodatabase?
    /// A strong reference to the download or upload job to keep it from going out of scope.
    private var activeJob: AGSJob?
    /// The local URL to where we can save the geodatabase.
    private let localGeodatabaseURL: URL = {
        //get a suitable directory to place files
        let directoryURL = FileManager.default.temporaryDirectory
        //create a unique name for the geodatabase based on current timestamp
        let formattedDate = ISO8601DateFormatter().string(from: Date())
        return directoryURL.appendingPathComponent("use-transactions-\(formattedDate).geodatabase")
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // instantiate map with a basemap
        let map = AGSMap(basemap: .streetsVector())
        // assign the map to the map view
        mapView.map = map
        
        /// The area covering the data we want to show.
        let areaOfInterest = AGSEnvelope(center: AGSPoint(x: -95.220, y: 29.115, spatialReference: .wgs84()),
                                         width: 0.25,
                                         height: 0.25)
        let viewpoint = AGSViewpoint(targetExtent: areaOfInterest)
        // set the map's viewpoint so that it will show the data
        mapView.setViewpoint(viewpoint)

        /// The URL of a feature service that supports geodatabase syncing.
        let featureServerURL = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Sync/SaveTheBaySync/FeatureServer")!
        /// The IDs of the layers we want included in the download.
        let layerIDsToDownload: Set<Int> = [0,1]
        
        /// The sync task used to download the geodatabase now and upload it later.
        let geodatabaseSyncTask = AGSGeodatabaseSyncTask(url: featureServerURL)
        self.geodatabaseSyncTask = geodatabaseSyncTask
        
        geodatabaseSyncTask.defaultGenerateGeodatabaseParameters(withExtent: areaOfInterest) {[weak self] (parameters, error) in
            guard let self = self else {
                return
            }
            if let error = error {
                NSAlert(error: error).beginSheetModal(for: self.view.window!)
            }
            else if let parameters = parameters {
                // minimze the geodatabase size by excluding attachments
                parameters.returnAttachments = false
               
                // remove the `AGSGenerateLayerOption` objects for layers we don't want downloaded
                parameters.layerOptions = parameters.layerOptions.filter{ layerIDsToDownload.contains($0.layerID) }
                
                self.startGeodatabaseDownload(parameters: parameters)
            }
        }
        
    }
    
    //MARK: - Geodatabase
    
    private func startGeodatabaseDownload(parameters: AGSGenerateGeodatabaseParameters){
        
        guard let geodatabaseSyncTask = geodatabaseSyncTask else {
            return
        }
        
        /// The job used to download the data.
        let generateGeodatabaseJob = geodatabaseSyncTask.generateJob(with: parameters, downloadFileURL: localGeodatabaseURL)
        // retain a strong reference
        self.activeJob = generateGeodatabaseJob
        
        // open the progress sheet
        let progressViewController = ProgressViewController(progress: generateGeodatabaseJob.progress, operationLabel:  "Downloading Geodatabase")
        presentAsSheet(progressViewController)
        
        // start the download
        generateGeodatabaseJob.start(statusHandler: { (status) in
            // no need handle the status
        }, completion: {[weak self] (geodatabase, error) in
            guard let self = self else {
                return
            }
            
            // close the progress sheet
            self.dismiss(progressViewController)
            self.activeJob = nil
            
            if let error = error {
                // don't show an alert if the user clicked Cancel
                if (error as NSError).code != NSUserCancelledError {
                    NSAlert(error: error).beginSheetModal(for: self.view.window!)
                }
            }
            else if let geodatabase = geodatabase {
                self.geodatabase = geodatabase
                
                // enable the controls now that we have a geodatabase
                self.manageControlEnabledStates()
                
                // load the geodatabase to ensure the feature tables are available
                geodatabase.load {[weak self] (error) in
                    guard let self = self else {
                        return
                    }
                    if let error = error {
                        NSAlert(error: error).beginSheetModal(for: self.view.window!)
                    }
                    else {
                        self.loadFeatureTables()
                    }
                    
                }
            }
        })
    }
    
    private func loadFeatureTables(){
        guard let geodatabase = geodatabase else {
            return
        }

        for featureTable in geodatabase.geodatabaseFeatureTables {
            
            //create a feature layer with the feature table
            let featureLayer = AGSFeatureLayer(featureTable: featureTable)
            //add the feature layer to the operational layers on map
            mapView.map?.operationalLayers.add(featureLayer)
            
            // load the table to ensure the fields are available
            featureTable.load {[weak self] (error) in
                
                guard let self = self else {
                    return
                }
                if let error = error {
                    NSAlert(error: error).beginSheetModal(for: self.view.window!)
                }
                else {
                    self.loadPopUpMenuItems(for: featureTable)
                }
            }
        }
    }
    
    /// Creates a feature with the given parameters in the local geodatabase.
    private func addFeature(at point:AGSPoint, featureTableID: Int, attributes: [String: Any]) {
        
        guard let geodatabase = geodatabase,
            let featureTable = geodatabase.geodatabaseFeatureTable(byServiceLayerID: featureTableID) else {
                return
        }
        
        // normalize the point
        let normalizedPoint = AGSGeometryEngine.normalizeCentralMeridian(of: point)!
        
        // create a new feature
        let feature = featureTable.createFeature(attributes: attributes, geometry: normalizedPoint)
        
        // add the feature to the feature table
        featureTable.add(feature) { [weak self] (error: Error?) -> Void in
            
            guard let self = self else {
                return
            }
            if let error = error {
                NSAlert(error: error).beginSheetModal(for: self.view.window!)
            }
        }
    }
    
    /// Starts synchronizing changes with the online feature service, uploading any changes made by the user.
    private func startGeodatabaseSync(parameters: AGSSyncGeodatabaseParameters){
        
        guard let geodatabase = geodatabase,
            !geodatabase.inTransaction,
            let geodatabaseSyncTask = geodatabaseSyncTask else {
                return
        }
        
        /// The job used to synchronize the data.
        let syncGeodatabaseJob = geodatabaseSyncTask.syncJob(with: parameters, geodatabase: geodatabase)
        // retain a strong reference
        self.activeJob = syncGeodatabaseJob
        
        // open the progress sheet
        let progressViewController = ProgressViewController(progress: syncGeodatabaseJob.progress, operationLabel:  "Syncing Geodatabase")
        presentAsSheet(progressViewController)
        
        // start the upload
        syncGeodatabaseJob.start(statusHandler: { (status) in
            // no need handle the status
        }) {[weak self] (results, error) in
            
            guard let self = self else {
                return
            }
            
            // close the progress sheet
            self.dismiss(progressViewController)
            self.activeJob = nil
            
            if let error = error,
                // don't show an alert if the user clicked Cancel
                (error as NSError).code != NSUserCancelledError {
                NSAlert(error: error).beginSheetModal(for: self.view.window!)
            }
        }
    }
    
    //MARK: - Popup menu
    
    /// A model for the represented object of the popup menu items.
    private struct FeatureMenuItemModel {
        let featureTableID: Int
        let typeFieldName: String
        let typeValue: Any
    }
    
    /// Adds items to the popup menu for the feature types in the given table.
    private func loadPopUpMenuItems(for featureTable: AGSGeodatabaseFeatureTable){

        let typeFieldName = featureTable.typeIDField
        guard let domain = featureTable.field(forName: typeFieldName)?.domain as? AGSCodedValueDomain else {
            return
        }

        let item = NSMenuItem()
        item.title = domain.name
        item.isEnabled = false
        featureTypePopUp.menu?.addItem(item)
        
        for value in domain.codedValues {
            let model = FeatureMenuItemModel(featureTableID: featureTable.serviceLayerID,
                                             typeFieldName: typeFieldName,
                                             typeValue: value.code!)
            let item = NSMenuItem()
            item.title = value.name
            item.representedObject = model
            item.indentationLevel = 1
            featureTypePopUp.menu?.addItem(item)
        }
        
        // only run this once
        if featureTable.serviceLayerID == 0,
            let enabledItem = featureTypePopUp.menu?.items.first(where: { $0.isEnabled }){
            // the default selection is a disabled field name so we need to set it to an actual feature type
            featureTypePopUp.select(enabledItem)
        }
    }

    //MARK: - Actions

    @IBAction func beginTransactionAction(_ sender: NSButton) {
        guard let geodatabase = geodatabase,
            // do not allow starting a transaction if one exists
            !geodatabase.inTransaction else {
            return
        }
        do {
            // enter a new transaction that must be matched with `rollbackTransaction()` or `commitTransaction()`
            try geodatabase.beginTransaction()
            manageControlEnabledStates()
        }
        catch {
            NSAlert(error: error).beginSheetModal(for: view.window!)
        }
    }
    
    @IBAction func rollbackTransactionAction(_ sender: NSButton) {
        guard let geodatabase = geodatabase,
            // cannot end a transaction if there isn't one
            geodatabase.inTransaction else {
            return
        }
        do {
            // revert all the changes made since `beginTransaction()` and leave the transaction
            try geodatabase.rollbackTransaction()
            manageControlEnabledStates()
        }
        catch {
            NSAlert(error: error).beginSheetModal(for: view.window!)
        }
    }
    
    @IBAction func commitTransactionAction(_ sender: Any) {
        guard let geodatabase = geodatabase,
            // cannot end a transaction if there isn't one
            geodatabase.inTransaction else {
            return
        }
        do {
            // save all the changes made since `beginTransaction()` and leave the transaction
            try geodatabase.commitTransaction()
            manageControlEnabledStates()
        }
        catch {
            NSAlert(error: error).beginSheetModal(for: view.window!)
        }
    }
    
    @IBAction func synchronizeAction(_ sender: NSButton) {
        guard let geodatabase = geodatabase,
            // do not allow syncing in the middle of a transaction
            !geodatabase.inTransaction,
            // get the same sync task used to download the geodatabase
            let geodatabaseSyncTask = geodatabaseSyncTask else {
            return
        }
        // get the parameters needed to sync the database
        geodatabaseSyncTask.defaultSyncGeodatabaseParameters(with: geodatabase, completion: {[weak self] (parameters, error) in
            guard let self = self else {
                return
            }
            if let error = error {
                NSAlert(error: error).beginSheetModal(for: self.view.window!)
            }
            else if let parameters = parameters {
            
                // you can alter the parameters here if you need change the sync settings
            
                self.startGeodatabaseSync(parameters: parameters)
            }
        })
    }
    
    @IBAction func requiredCheckboxAction(_ sender: NSButton) {
        manageControlEnabledStates()
    }
    
    //MARK: - UI Helpers
    
    /// Enables or disables the UI controls based on the state of the workflow.
    private func manageControlEnabledStates() {
        
        featureTypePopUp.isEnabled = isEditingAllowed
        transactionsRequiredCheckbox.isEnabled = geodatabase != nil
        
        let inTransaction = geodatabase?.inTransaction == true
        startTransactionButton.isEnabled = !inTransaction
        synchronizeButton.isEnabled = !inTransaction
        commitTransactionButton.isEnabled = inTransaction
        rollbackTransactionButton.isEnabled = inTransaction
    }
    
    /// Returns true if the current settings allow the user to add new features.
    private var isEditingAllowed: Bool {
        guard let geodatabase = geodatabase else {
            return false
        }
        
        let requiresTransaction = transactionsRequiredCheckbox.state == .on
        
        // if editing is allowed outside a transaction
        return !requiresTransaction ||
            // or a transaction is ongoing
            geodatabase.inTransaction
    }
    
}

// the view controller is set as the touchDelegate of the map view in the storyboard
extension UseGeodatabaseTransactionsViewController: AGSGeoViewTouchDelegate {
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        
        if isEditingAllowed,
            let model = featureTypePopUp.selectedItem?.representedObject as? FeatureMenuItemModel {
            
            //attributes for the new feature
            let attributes: [String: Any] = [model.typeFieldName: model.typeValue]
            
            //add a feature at the tapped location
            addFeature(at: mapPoint, featureTableID: model.featureTableID, attributes: attributes)
        }
    }
    
}
