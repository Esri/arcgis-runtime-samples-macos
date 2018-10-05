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

class UseGeodatabaseTransactionsViewController: NSViewController {

    @IBOutlet private var mapView:AGSMapView!
    
    @IBOutlet weak var featureTypePopUp: NSPopUpButton!
    @IBOutlet weak var startTransactionButton: NSButton!
    @IBOutlet weak var rollbackTransactionButton: NSButton!
    @IBOutlet weak var syncEditsButton: NSButton!
    @IBOutlet weak var commitTransactionButton: NSButton!
    
    @IBOutlet weak var transactionsRequiredCheckbox: NSButton!
    private var geodatabase: AGSGeodatabase?
    private var geodatabaseSyncTask: AGSGeodatabaseSyncTask?
    private var activeJob: AGSJob?
    
    private var geodatabaseURL: URL = {
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
        
        let center = AGSPoint(x: -95.220, y: 29.115, spatialReference: .wgs84())
        let areaOfInterest = AGSEnvelope(center: center, width: 0.25, height: 0.25)
        let viewpoint = AGSViewpoint(targetExtent: areaOfInterest)
        mapView.setViewpoint(viewpoint)
        
        // set self as the map view's touch delegate
        mapView.touchDelegate = self

        let featureServerURL = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Sync/SaveTheBaySync/FeatureServer")!
        let geodatabaseSyncTask = AGSGeodatabaseSyncTask(url: featureServerURL)
        self.geodatabaseSyncTask = geodatabaseSyncTask
        
        geodatabaseSyncTask.load { [weak self] (error) -> Void in
            guard let self = self else {
                return
            }
            guard error == nil else {
                NSAlert(error: error!).beginSheetModal(for: self.view.window!)
                return
            }
            geodatabaseSyncTask.defaultGenerateGeodatabaseParameters(withExtent: areaOfInterest) {[weak self] (parameters, error) in
                guard let self = self else {
                    return
                }
                guard error == nil else {
                    NSAlert(error: error!).beginSheetModal(for: self.view.window!)
                    return
                }
                guard let parameters = parameters else {
                    return
                }
                // minimze the geodatabase size by excluding attachments
                parameters.returnAttachments = false
                
                let layerIDsToDownload: Set<Int> = [0,1]
                parameters.layerOptions = parameters.layerOptions.filter{ layerIDsToDownload.contains($0.layerID) }
                
                self.startGeodatabaseDownload(parameters: parameters)
            }
        }
        
    }
    
    private func startGeodatabaseDownload(parameters: AGSGenerateGeodatabaseParameters){
        
        guard let geodatabaseSyncTask = geodatabaseSyncTask else {
            return
        }
        
        let generateGeodatabaseJob = geodatabaseSyncTask.generateJob(with: parameters, downloadFileURL: geodatabaseURL)
        self.activeJob = generateGeodatabaseJob
        
        showProgressViewController(progress: generateGeodatabaseJob.progress)
        
        generateGeodatabaseJob.start(statusHandler: { (status) in
            // no need handle the status
        }, completion: {[weak self] (geodatabase, error) in
            guard let self = self else {
                return
            }
            
            self.closeProgressViewController()
            
            guard error == nil else {
                if (error! as NSError).code != NSUserCancelledError {
                    NSAlert(error: error!).beginSheetModal(for: self.view.window!)
                }
                return
            }
            self.geodatabase = geodatabase
            self.loadFeatureLayers()

            self.manageButtonEnabledStates()
        })
    }
    
    private func showProgressViewController(progress: Progress){
        let progressViewController = storyboard!.instantiateController(withIdentifier: "GeodatabaseTransactionsProgressViewController") as! GeodatabaseTransactionsProgressViewController
        progressViewController.progress = progress
        progressViewController.cancelHandler = { (progressViewController) in
            progressViewController.progress?.cancel()
        }
        presentAsSheet(progressViewController)
    }
    private func closeProgressViewController(){
        if let progressController = presentedViewControllers?.first(where: { $0 is GeodatabaseTransactionsProgressViewController }) as? GeodatabaseTransactionsProgressViewController{
            dismiss(progressController)
        }
    }
    
    private struct FeatureMenuItemModel {
        let featureTableID: Int
        let typeFieldName: String
        let typeValue: Any
    }
    
    private func loadFeatureLayers(){
        guard let geodatabase = geodatabase else {
            return
        }
        geodatabase.load {[weak self] (error) in
            guard let self = self else {
                return
            }
            guard error == nil else {
                NSAlert(error: error!).beginSheetModal(for: self.view.window!)
                return
            }
            let featureTables = geodatabase.geodatabaseFeatureTables
            for featureTableID in 0..<featureTables.count {

                let featureTable = featureTables[featureTableID]
                
                //create a feature layer with the feature table
                let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                //add the feature layer to the operational layers on map
                self.mapView.map?.operationalLayers.add(featureLayer)
                
                featureTable.load {[weak self] (error) in
                    
                    guard let self = self else {
                        return
                    }
                    guard error == nil else {
                        NSAlert(error: error!).beginSheetModal(for: self.view.window!)
                        return
                    }
                    
                    let typeFieldName = featureTable.typeIDField
                    if let domain = featureTable.field(forName: typeFieldName)?.domain as? AGSCodedValueDomain {
                        
                        let item = NSMenuItem()
                        item.title = featureTable.displayName
                        item.isEnabled = false
                        self.featureTypePopUp.menu?.addItem(item)
                        
                        for value in domain.codedValues {
                            let model = FeatureMenuItemModel(featureTableID: featureTableID,
                                                             typeFieldName: typeFieldName,
                                                             typeValue: value.code!)
                            let item = NSMenuItem()
                            item.isEnabled = true
                            item.title = value.name
                            item.representedObject = model
                            item.indentationLevel = 1
                            self.featureTypePopUp.menu?.addItem(item)
                        }
                    }
                    
                    if let enabledItem = self.featureTypePopUp.menu?.items.first(where: { $0.isEnabled }){
                        self.featureTypePopUp.select(enabledItem)
                    }
                }
            }
        }
    }

    private func addFeature(at point:AGSPoint, featureTableID: Int, attributes: [String: Any]) {
        
        guard let geodatabase = geodatabase,
            let featureTable = geodatabase.geodatabaseFeatureTable(byServiceLayerID: featureTableID) else {
            return
        }
        
        // normalize the point
        let normalizedPoint = AGSGeometryEngine.normalizeCentralMeridian(of: point)!
        
        //create a new feature
        let feature = featureTable.createFeature(attributes: attributes, geometry: normalizedPoint)
        
        //add the feature to the feature table
        featureTable.add(feature) { [weak self] (error: Error?) -> Void in
            
            guard let self = self else {
                return
            }
            guard error == nil else {
                NSAlert(error: error!).beginSheetModal(for: self.view.window!)
                return
            }
        }
    }
    
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
    
    //MARK: - Actions

    @IBAction func commitTransactionAction(_ sender: Any) {
        guard let geodatabase = geodatabase else {
            return
        }
        if geodatabase.inTransaction {
            do {
                try geodatabase.commitTransaction()
                manageButtonEnabledStates()
            }
            catch {
                NSAlert(error: error).beginSheetModal(for: view.window!)
            }
        }
    }
    @IBAction func rollbackTransactionAction(_ sender: NSButton) {
        guard let geodatabase = geodatabase else {
            return
        }
        if geodatabase.inTransaction {
            do {
                try geodatabase.rollbackTransaction()
                manageButtonEnabledStates()
            }
            catch {
                NSAlert(error: error).beginSheetModal(for: view.window!)
            }
        }
    }
    @IBAction func beginTransactionAction(_ sender: NSButton) {
        guard let geodatabase = geodatabase else {
            return
        }
        if !geodatabase.inTransaction {
            do {
                try geodatabase.beginTransaction()
                manageButtonEnabledStates()
            }
            catch {
                NSAlert(error: error).beginSheetModal(for: view.window!)
            }
        }
    }
    
    @IBAction func syncEditsAction(_ sender: NSButton) {
        guard let geodatabase = geodatabase,
            !geodatabase.inTransaction,
            let geodatabaseSyncTask = geodatabaseSyncTask else {
            return
        }
        geodatabaseSyncTask.defaultSyncGeodatabaseParameters(with: geodatabase, completion: {[weak self] (parameters, error) in
            guard let self = self else {
                return
            }
            guard error == nil else {
                NSAlert(error: error!).beginSheetModal(for: self.view.window!)
                return
            }
            guard let parameters = parameters else {
                return
            }
            self.startGeodatabaseSync(parameters: parameters)
        })
    }
    
    @IBAction func requiredCheckboxAction(_ sender: NSButton) {
        manageButtonEnabledStates()
    }
    
    private func manageButtonEnabledStates() {
        
        featureTypePopUp.isEnabled = isEditingAllowed
        transactionsRequiredCheckbox.isEnabled = geodatabase != nil
        
        let inTransaction = geodatabase?.inTransaction == true
        startTransactionButton.isEnabled = !inTransaction
        syncEditsButton.isEnabled = !inTransaction
        commitTransactionButton.isEnabled = inTransaction
        rollbackTransactionButton.isEnabled = inTransaction
    }
    
    private func startGeodatabaseSync(parameters: AGSSyncGeodatabaseParameters){
        guard let geodatabase = geodatabase,
            !geodatabase.inTransaction,
            let geodatabaseSyncTask = geodatabaseSyncTask else {
                return
        }
        
        let syncGeodatabaseJob = geodatabaseSyncTask.syncJob(with: parameters, geodatabase: geodatabase)
        self.activeJob = syncGeodatabaseJob
        
        showProgressViewController(progress: syncGeodatabaseJob.progress)
        syncGeodatabaseJob.start(statusHandler: { (status) in
            // no need handle the status
        }) {[weak self] (results, error) in
            
            guard let self = self else {
                return
            }
            
            self.closeProgressViewController()
            
            guard error == nil else {
                if (error! as NSError).code != NSUserCancelledError {
                    NSAlert(error: error!).beginSheetModal(for: self.view.window!)
                }
                return
            }
        }
    }
    
}

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
