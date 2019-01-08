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

class UpdateAttributesViewController: NSViewController {
    @IBOutlet private var mapView: AGSMapView!
    
    /// The feature table representing the feature data from the remote service.
    private let featureTable: AGSServiceFeatureTable
    /// The layer that displays the features from the table in the map.
    private let featureLayer: AGSFeatureLayer
    
    /// The key to use in the `attributes` dictionary of `AGSFeature` objects to get and set the damage type.
    private let damageTypeAttributeKey = "typdamage"
    /// The string options for the damage type feature attribute.
    private let damageTypes = ["Destroyed", "Major", "Minor", "Affected", "Inaccessible"]
    
    /// The feature indicated by the currently shown callout.
    private weak var featureForCallout: AGSFeature?
    
    /// An object retained to enable cancellation of the last `identifyLayer` query.
    private var lastQuery: AGSCancelable?
    
    required init?(coder: NSCoder) {
        /// The URL of the feature service serving the data.
        let featureServiceURL = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0")!
        
        // create a feature table for the service URL
        featureTable = AGSServiceFeatureTable(url: featureServiceURL)
        
        // create a feature layer from the the table
        featureLayer = AGSFeatureLayer(featureTable: featureTable)
        
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a map with a basemap
        let map = AGSMap(basemap: .oceans())
        // set initial viewpoint
        map.initialViewpoint = AGSViewpoint(
            center: AGSPoint(x: 0, y: 0, spatialReference: .webMercator()),
            scale: 100000000
        )
        // add the feature layer to the map
        map.operationalLayers.add(featureLayer)
        // add the map to the map view
        mapView.map = map
        
        // set self for the delegates in order to receive callbacks
        mapView.touchDelegate = self
        mapView.callout.delegate = self
    }
    
    private func damageType(for feature: AGSFeature) -> String? {
        // get the value from the attributes dictionary using the correct key
        return feature.attributes[damageTypeAttributeKey] as? String
    }
    
    private func showCallout(for feature: AGSFeature, tapLocation: AGSPoint?) {
        // close the exisiting callout if there is one
        mapView.callout.dismiss()
        
        // use the damage type for the main text of the callout
        mapView.callout.title = damageType(for: feature)
        // also indicate that the user can tap the callout to open the editor
        mapView.callout.detail = "Click to edit"
        // display the callout for the feature at the tap point
        mapView.callout.show(for: feature, tapLocation: tapLocation, animated: true)
    
        // keep track of what feature the callout is for
        featureForCallout = feature
    }
    
    private func showEditor(for feature: AGSFeature) {
        // use a pop-up button for the damage type selection UI
        let popUp = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 200, height: 32))
        // use the damage types as the menu options
        popUp.addItems(withTitles: damageTypes)
        
        if let damageType = damageType(for: feature) {
            // set the initially selected option as the exisiting damage type for this feature, if possible
            popUp.selectItem(withTitle: damageType)
        }
        
        // the editor is simple so just use an alert
        let alert = NSAlert()
        alert.messageText = "Update the Selected Feature"
        alert.informativeText = "Set the damage level."
        // embed the pop-up button in the alert
        alert.accessoryView = popUp
        // override the default OK button
        alert.addButton(withTitle: "Apply")
        // allow cancellation without changing the data
        alert.addButton(withTitle: "Cancel")
        // show the alert
        alert.beginSheetModal(for: view.window!) { (response) in
            // only update if the user clicked "Apply"
            if response == .alertFirstButtonReturn,
                // get the selected type
                let damageType = popUp.selectedItem?.title {
                // update the feature with the selected damage type
                self.update(feature: feature, damageType: damageType)
            }
        }
    }
    
    private func update(feature: AGSFeature, damageType: String) {
        NSApp.showProgressIndicator()
        
        // update the damage type for the feature
        feature.attributes[damageTypeAttributeKey] = damageType
        // update the callout with the new damage type
        mapView.callout.title = damageType
        
        // update the values in the feature table with those we set in the feature attributes
        featureTable.update(feature) { [weak self] (error: Error?) in
            NSApp.hideProgressIndicator()
            
            guard let self = self else {
                return
            }
            
            if let error = error {
                self.showAlert(messageText: "Error", informativeText: error.localizedDescription)
            } else {
                self.applyEdits()
            }
        }
    }
    
    private func applyEdits() {
        NSApp.showProgressIndicator()
        
        // sync the local edits back to the remote feature service
        featureTable.applyEdits(completion: { [weak self] (result: [AGSFeatureEditResult]?, error: Error?) in
            NSApp.hideProgressIndicator()
            
            guard let self = self else {
                return
            }
            
            // if an overall error occurred, show it
            if let error = error {
                self.showAlert(messageText: "Error", informativeText: error.localizedDescription)
            
            // if an error occurred with the individual edit, show it
            } else if let error = result?.first?.error {
                self.showAlert(messageText: "Error", informativeText: error.localizedDescription)
            } else {
                self.showAlert(messageText: "Edits Applied Successfully", informativeText: "Your changes have been uploaded to the feature service.")
            }
        })
    }
    
    // MARK: - Helper methods
    
    private func showAlert(messageText: String, informativeText: String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.beginSheetModal(for: view.window!)
    }
}

extension UpdateAttributesViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // stop any existing query
        lastQuery?.cancel()
        
        // determine what layer and feature the user tapped, if any
        lastQuery = mapView.identifyLayer(featureLayer, screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false, maximumResults: 1) { [weak self] (identifyLayerResult: AGSIdentifyLayerResult) in
            guard let self = self else {
                return
            }
            
            if let error = identifyLayerResult.error {
                print(error)
            } else if let feature = identifyLayerResult.geoElements.first as? AGSFeature {
                // show a callout for the tapped feature
                self.showCallout(for: feature, tapLocation: mapPoint)
            }
        }
    }
}

extension UpdateAttributesViewController: AGSCalloutDelegate {
    func didTap(_ callout: AGSCallout) {
        if let featureForCallout = featureForCallout {
            // display the editing interface for the chosen feature
            showEditor(for: featureForCallout)
        }
    }
}
