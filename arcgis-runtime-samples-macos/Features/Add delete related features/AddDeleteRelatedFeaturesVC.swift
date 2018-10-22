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

class AddDeleteRelatedFeaturesVC: NSViewController, AGSGeoViewTouchDelegate, AGSCalloutDelegate, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet private var mapView:AGSMapView!
    @IBOutlet private var tableView:NSTableView!
    @IBOutlet private var visualEffectViewTrailingConstraint:NSLayoutConstraint!
    @IBOutlet private var visualEffectViewWidthConstraint:NSLayoutConstraint!
    @IBOutlet private var visualEffectView:NSVisualEffectView!
    @IBOutlet private var featureTextField:NSTextField!
    
    private var parksFeatureTable:AGSServiceFeatureTable!
    private var speciesFeatureTable:AGSServiceFeatureTable!
    private var parksFeatureLayer:AGSFeatureLayer!
    private var relatedFeatures:[AGSFeature]!
    private var relationshipInfo:AGSRelationshipInfo!
    private var selectedPark:AGSArcGISFeature!
    private var identifyCancelable:AGSCancelable!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize map with basemap
        let map = AGSMap(basemap: .terrainWithLabels())
        
        //initial viewpoint
        let point = AGSPoint(x: -16507762.575543, y: 9058828.127243, spatialReference: AGSSpatialReference(wkid: 3857))
        
        //set initial viewpoint on map
        map.initialViewpoint = AGSViewpoint(center: point, scale: 20064077)
        
        //parks feature table
        self.parksFeatureTable = AGSServiceFeatureTable(url: URL(string: "https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/ArcGIS/rest/services/AlaskaNationalParksSpecies_Add_Delete/FeatureServer/0")!)
        
        //parks feature layer (origin feature layer)
        self.parksFeatureLayer = AGSFeatureLayer(featureTable: self.parksFeatureTable)
        
        //add feature layer to the map
        map.operationalLayers.add(self.parksFeatureLayer)
        
        //species feature table (destination feature table)
        //related to the parks feature layer in a 1..M relationship
        self.speciesFeatureTable = AGSServiceFeatureTable(url: URL(string: "https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/ArcGIS/rest/services/AlaskaNationalParksSpecies_Add_Delete/FeatureServer/1")!)
        
        //add table to the map
        //for the related query to work, the related table should be present in the map
        map.tables.addObjects(from: [speciesFeatureTable])
        
        //add constraint for visual effect view wrt the attribution label on map view
        self.visualEffectView.bottomAnchor.constraint(equalTo: self.mapView.attributionTopAnchor, constant: -20).isActive = true
        
        //assign map to map view
        self.mapView.map = map
        
        //change selection color
        mapView.selectionProperties.color = .yellow
        
        //set touch delegate
        self.mapView.touchDelegate = self
        
        //hide side container view initially
        self.toggleVisualEffectView(on: false, animated: false)
    }
    
    private func queryRelatedFeatures() {
        
        //get relationship info
        //feature table's layer info has an array of relationshipInfos, one for each relationship
        //in this case there is only one describing the 1..M relationship between parks and species
        guard let relationshipInfo = self.parksFeatureTable.layerInfo?.relationshipInfos[0] else {
            
            self.showAlert(messageText: "Error", informativeText: "Relationship info not found")
            return
        }
        
        //show progress indicator
        NSApp.showProgressIndicator()
        
        //keep for later use
        self.relationshipInfo = relationshipInfo
        
        //initialize related query parameters with relationshipInfo
        let parameters = AGSRelatedQueryParameters(relationshipInfo: relationshipInfo)
        
        //order results by OBJECTID field
        parameters.orderByFields = [AGSOrderBy(fieldName: "OBJECTID", sortOrder: .descending)]
        
        //query for species related to the selected park
        self.parksFeatureTable.queryRelatedFeatures(for: self.selectedPark, parameters: parameters) { [weak self] (results:[AGSRelatedFeatureQueryResult]?, error:Error?) in
            
            //hide progress indicator
            NSApp.hideProgressIndicator()
            
            guard error == nil else {
                
                //show error
                self?.showAlert(messageText: "Error", informativeText: error!.localizedDescription)
                return
            }
            
            if let results = results, results.count > 0 {
                
                //Displaying information on selected park using the field UNIT_NAME, name of the park
                self?.featureTextField.stringValue = self?.selectedPark.attributes["UNIT_NAME"] as? String ?? "Origin Feature"
                
                //save the related features to display in the table view
                self?.relatedFeatures = results[0].featureEnumerator().allObjects
                
                //reload table view to reflect changes
                self?.tableView.reloadData()
                
                //show container view
                self?.toggleVisualEffectView(on: true, animated: true)
            }
        }
    }
    
    private func addRelatedFeature() {
        
        //show progress indicator
        NSApp.showProgressIndicator()
        
        //get related table using relationshipInfo
        let relatedTable = self.parksFeatureTable.relatedTables(with: self.relationshipInfo)![0] as! AGSServiceFeatureTable
        
        //new related feature (specie)
        let feature = relatedTable.createFeature(attributes: ["Scientific_name" : "New specie"], geometry: nil) as! AGSArcGISFeature
        
        //relate new feature to origin feature
        feature.relate(to: self.selectedPark)
        
        //add new feature to related table
        relatedTable.add(feature) { [weak self] (error) in
            
            //hide progress indicator
            NSApp.hideProgressIndicator()
            
            guard error == nil else {
                
                //show error
                self?.showAlert(messageText: "Error", informativeText: error!.localizedDescription)
                return
            }
            
            //apply edits
            self?.applyEdits()
        }
    }
    
    private func deleteRelatedFeature(_ feature: AGSFeature) {
        
        //show progress indicator
        NSApp.showProgressIndicator()
        
        //get related table using relationshipInfo
        let relatedTable = self.parksFeatureTable.relatedTables(with: self.relationshipInfo)![0] as! AGSServiceFeatureTable
        
        //delete feature from related table
        relatedTable.delete(feature) { [weak self] (error) in
            
            //hide progress indicator
            NSApp.hideProgressIndicator()
            
            guard error == nil else {
                
                //show error
                self?.showAlert(messageText: "Error", informativeText: error!.localizedDescription)
                return
            }
            
            //apply edits
            self?.applyEdits()
        }
    }
    
    private func applyEdits() {
        
        //show progress indicator
        NSApp.showProgressIndicator()
        
        //get the related table using the relationshipInfo
        let relatedTable = self.parksFeatureTable.relatedTables(with: self.relationshipInfo)![0] as! AGSServiceFeatureTable
        
        relatedTable.applyEdits { [weak self] (results:[AGSFeatureEditResult]?, error:Error?) in
            
            //hide progress indicator
            NSApp.hideProgressIndicator()
            
            guard error == nil else {
                //show error
                self?.showAlert(messageText: "Error", informativeText: error!.localizedDescription)
                return
            }
            
            print("Apply edits succeeded")
            self?.queryRelatedFeatures()
        }
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        
        //cancel previous requests
        self.identifyCancelable?.cancel()
        
        //unselect previously selected park
        if let previousSelection = self.selectedPark {
            self.parksFeatureLayer.unselectFeature(previousSelection)
            self.selectedPark = nil
        }
        
        //reset table view till new query returns results
        self.relatedFeatures = nil
        self.tableView.reloadData()
        self.featureTextField.stringValue = ""
        
        //show progress indicator
        NSApp.showProgressIndicator()
        
        //identify feature at tapped location
        self.identifyCancelable = self.mapView.identifyLayer(self.parksFeatureLayer, screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false) { [weak self] (result: AGSIdentifyLayerResult) in
            
            //hide progress indicator
            NSApp.hideProgressIndicator()
            
            guard result.error == nil else {
                
                //show error
                self?.showAlert(messageText: "Error", informativeText: result.error!.localizedDescription)
                return
            }
            
            if result.geoElements.count > 0 {
                
                //will use the first feature
                let feature = result.geoElements[0] as! AGSArcGISFeature
                self?.selectedPark = feature
                
                //select feature on layer
                self?.parksFeatureLayer.select(feature)
                
                //query for related features
                self?.queryRelatedFeatures()
            }
            else {
                //hide side container view
                self?.toggleVisualEffectView(on: false, animated: true)
            }
        }
    }
    
    //MARK: - NSTableViewDataSource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.relatedFeatures?.count ?? 0
    }
    
    //MARK: - NSTableViewDelegate
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        //related feature for row
        let feature = self.relatedFeatures[row]
        
        //cell view
        let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RelatedFeatureCellView"), owner: self) as! NSTableCellView
        
        //use the field Scientific_Name for specie's info
        cellView.textField?.stringValue = feature.attributes["Scientific_Name"] as! String
        
        return cellView
    }
    
    //MARK: - Show/hide table view
    
    private func toggleVisualEffectView(on: Bool, animated: Bool) {
        
        if animated {
            
            self.visualEffectViewTrailingConstraint.animator().constant = on ? 20 : -self.visualEffectViewWidthConstraint.constant - 20
        }
        else {
            
            self.visualEffectViewTrailingConstraint.constant = on ? 20 : -self.visualEffectViewWidthConstraint.constant - 20
        }
    }
    
    //MARK: - Actions
    
    @IBAction private func addAction(sender:NSButton) {
        
        self.addRelatedFeature()
    }
    
    override func keyDown(with event: NSEvent) {
        
        guard let window = self.view.window else {
            return
        }
        
        if event.keyCode == 51 { //delete key is pressed
            
            if window.firstResponder == self.tableView && self.tableView.selectedRow != -1 {
                
                let feature = self.relatedFeatures[self.tableView.selectedRow]
                self.deleteRelatedFeature(feature)
            }
        }
    }
    
    //MARK: - Helper methods
    
    private func showAlert(messageText:String, informativeText:String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.beginSheetModal(for: self.view.window!)
    }
}
