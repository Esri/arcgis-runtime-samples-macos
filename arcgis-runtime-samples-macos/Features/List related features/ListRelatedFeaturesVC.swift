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

class ListRelatedFeaturesVC: NSViewController, AGSGeoViewTouchDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate {

    @IBOutlet private var mapView:AGSMapView!
    @IBOutlet private var outlineView:NSOutlineView!
    @IBOutlet private var visualEffectViewTrailingConstraint:NSLayoutConstraint!
    @IBOutlet private var visualEffectViewWidthConstraint:NSLayoutConstraint!
    @IBOutlet private var visualEffectView:NSVisualEffectView!
    @IBOutlet private var featureTextField:NSTextField!
    
    private var parksFeatureLayer:AGSFeatureLayer!
    private var parksFeatureTable:AGSServiceFeatureTable!
    private var preservesFeatureTable:AGSServiceFeatureTable!
    private var speciesFeatureTable:AGSServiceFeatureTable!
    private var identifyCancelable:AGSCancelable!
    private var selectedPark:AGSArcGISFeature!
    
    private var results:[AGSRelatedFeatureQueryResult]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize map with a basemap
        let map = AGSMap(basemap: .streets())
        
        //initial viewpoint
        let point = AGSPoint(x: -16507762.575543, y: 9058828.127243, spatialReference: AGSSpatialReference(wkid: 3857))
        
        //set initial viewpoint on map
        map.initialViewpoint = AGSViewpoint(center: point, scale: 36764077)
        
        //add self as the touch delegate for map view
        //we will need to be notified when the user taps with the map
        self.mapView.touchDelegate = self
        
        //create feature table for the parks layer, the origin layer in the relationship
        self.parksFeatureTable = AGSServiceFeatureTable(url: URL(string: "https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/arcgis/rest/services/AlaskaNationalParksPreservesSpecies_List/FeatureServer/1")!)
        
        //feature layer for parks
        self.parksFeatureLayer = AGSFeatureLayer(featureTable: self.parksFeatureTable)
        
        //change selection width for feature layer
        self.parksFeatureLayer.selectionWidth = 4
        self.parksFeatureLayer.selectionColor = .yellow
        
        //add parks feature layer to the map
        map.operationalLayers.add(self.parksFeatureLayer)
        
        //Feature table for related Preserves layer
        self.preservesFeatureTable = AGSServiceFeatureTable(url: URL(string: "https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/arcgis/rest/services/AlaskaNationalParksPreservesSpecies_List/FeatureServer/0")!)
        
        //Feature table for related Species layer
        self.speciesFeatureTable = AGSServiceFeatureTable(url: URL(string: "https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/arcgis/rest/services/AlaskaNationalParksPreservesSpecies_List/FeatureServer/2")!)
        
        //add these to the tables on the map
        //to query related features in a layer, the layer must either be added as a feature
        //layer in operational layers or as a feature table in tables on map
        map.tables.addObjects(from: [preservesFeatureTable, speciesFeatureTable])
        
        //assign map to the map view
        self.mapView.map = map
        
        //add constraint for visual effect view wrt the attribution label on map view
        self.visualEffectView.bottomAnchor.constraint(equalTo: self.mapView.attributionTopAnchor, constant: -20).isActive = true
        
        //hide visual effect view at start
        self.toggleVisualEffectView(on: false, animated: false)
    }
    
    private func queryRelatedFeatures() {
        
        //show progress indicator
        self.view.window?.showProgressIndicator()
        
        //reset table view till new query returns results
        self.results = nil
        self.outlineView.reloadData()
        self.featureTextField.stringValue = ""
        
        //query for related features
        self.parksFeatureTable.queryRelatedFeatures(for: self.selectedPark) { [weak self] (results:[AGSRelatedFeatureQueryResult]?, error:Error?) in
            
            //hide progress indicator
            self?.view.window?.hideProgressIndicator()
            
            if let error = error {
                
                //show error
                self?.showAlert(messageText: "Error", informativeText: error.localizedDescription)
            }
            else {
                if let results = results, results.count > 0 {
                    
                    //store results to show in the outline view
                    self?.results = results
                    
                    //toggle results on
                    self?.toggleVisualEffectView(on: true, animated: true)
                    
                    self?.featureTextField.stringValue = self?.selectedPark.attributes["UNIT_NAME"] as? String ?? "Origin Feature"
                    
                    //reload outline view data
                    self?.outlineView.reloadData()
                    
                    //expand all items by default
                    self?.outlineView.expandItem(nil, expandChildren: true)
                }
            }
        }
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        
        //cancel previous identify
        self.identifyCancelable?.cancel()
        
        //show progress indicator
        self.view.window?.showProgressIndicator()
        
        //identify feature at tapped location
        self.identifyCancelable = self.mapView.identifyLayer(self.parksFeatureLayer, screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false) { [weak self] (result: AGSIdentifyLayerResult) in
            
            //hide progress indicator
            self?.view.window?.hideProgressIndicator()
            
            if let error = result.error {
                
                //show error
                self?.showAlert(messageText: "Error", informativeText: error.localizedDescription)
            }
            else {
                
                //unselect previously selected park
                if let previousSelection = self?.selectedPark {
                    self?.parksFeatureLayer.unselectFeature(previousSelection)
                    self?.selectedPark = nil
                }
                
                if result.geoElements.count > 0 {
                    
                    //Will pick the first feature
                    let feature = result.geoElements[0] as! AGSArcGISFeature
                    
                    //will need the selected park for related features query and highlighting
                    self?.selectedPark = feature
                    
                    //select new park
                    self?.parksFeatureLayer.select(feature)
                    
                    //query for related features
                    self?.queryRelatedFeatures()
                }
                else {
                    
                    //hide outline view
                    self?.toggleVisualEffectView(on: false, animated: true)
                }
            }
        }
    }
    
    //MARK: - NSOutlineViewDataSource
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        
        if let result = item as? AGSRelatedFeatureQueryResult {
            return result.featureEnumerator().allObjects.count
        }
        else {
            return self.results?.count ?? 0
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let result = item as? AGSRelatedFeatureQueryResult {
            return result.featureEnumerator().allObjects[index]
        }
        else {
            return self.results[index]
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let result = item as? AGSRelatedFeatureQueryResult {
            return result.featureEnumerator().allObjects.count > 0
        }
        else {
            return false
        }
    }
    
    //MARK: - NSOutlineViewDelegate
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        
        let cellView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ListCell"), owner: self) as! NSTableCellView
        cellView.wantsLayer = true
        
        if let result = item as? AGSRelatedFeatureQueryResult {
            
            cellView.textField?.stringValue = result.relatedTable!.tableName
        }
        else {
            let relatedFeature = item as! AGSArcGISFeature
            let result = outlineView.parent(forItem: item) as! AGSRelatedFeatureQueryResult
            
            if let displayField = result.relatedTable?.layerInfo?.displayFieldName {
                cellView.textField?.stringValue = relatedFeature.attributes[displayField] as? String ?? "Related feature"
            }
            else {
                cellView.textField?.stringValue = "Related feature"
            }
        }
        
        return cellView
    }
    
    //MARK: - Show/hide table view
    
    private func toggleVisualEffectView(on:Bool, animated:Bool) {
        
        if animated {
         
            self.visualEffectViewTrailingConstraint.animator().constant = on ? 20 : -self.visualEffectViewWidthConstraint.constant - 20
        }
        else {
            
            self.visualEffectViewTrailingConstraint.constant = on ? 20 : -self.visualEffectViewWidthConstraint.constant - 20
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
