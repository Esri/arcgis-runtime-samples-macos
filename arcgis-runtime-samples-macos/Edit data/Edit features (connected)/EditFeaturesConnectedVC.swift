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

class EditFeaturesConnectedVC: NSViewController, AGSGeoViewTouchDelegate, AGSPopupsViewControllerDelegate, FeatureTemplatePickerVCDelegate {
    
    @IBOutlet private var mapView:AGSMapView!
    @IBOutlet private var containerView:NSView!
    @IBOutlet private var containerViewLeadingConstraint:NSLayoutConstraint!
    @IBOutlet private var addFeatureButton:NSButton!
    
    private var map:AGSMap!
    private var sketchEditor:AGSSketchEditor!
    private var featureLayer:AGSFeatureLayer!
    private var popupsVC:AGSPopupsViewController!
    private var isAddingNewFeature = false {
        didSet {
            self.addFeatureButton?.isEnabled = !isAddingNewFeature
        }
    }
    
    private var lastQuery:AGSCancelable!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.map = AGSMap(basemap: AGSBasemap.topographic())
        //set initial viewpoint
        self.map.initialViewpoint = AGSViewpoint(center: AGSPoint(x: -9184518.55, y: 3240636.90, spatialReference: AGSSpatialReference.webMercator()), scale: 7e5)
        self.mapView.map = self.map
        self.mapView.touchDelegate = self
        
        let featureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0")!)
        self.featureLayer = AGSFeatureLayer(featureTable: featureTable)
        self.map.operationalLayers.add(featureLayer)
        
        //feature layer selection settings
        self.featureLayer.selectionWidth = 4
        
        //initialize sketch editor and assign to map view
        self.sketchEditor = AGSSketchEditor()
        self.mapView.sketchEditor = self.sketchEditor
        
        //hide popups view controller initially
        self.hidePopupsViewController(animated: false)
    }
    
    func applyEdits() {
        //show progress indicator
        self.view.window?.showProgressIndicator()
        
        (self.featureLayer.featureTable as! AGSServiceFeatureTable).applyEdits { [weak self] (result:[AGSFeatureEditResult]?, error:Error?) -> Void in
            
            //hide progress indicator
            self?.view.window?.hideProgressIndicator()
            
            if let error = error {
                self?.showAlert(messageText: "Error", informativeText: "Error while applying edits :: \(error.localizedDescription)")
            }
            else {
                print("Edits applied successfully")
            }
        }
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        if let lastQuery = self.lastQuery{
            lastQuery.cancel()
        }
        
        //show progress indicator
        self.view.window?.showProgressIndicator()
        
        self.lastQuery = self.mapView.identifyLayer(self.featureLayer, screenPoint: screenPoint, tolerance: 5, returnPopupsOnly: false, maximumResults: 10) { [weak self] (identifyLayerResult: AGSIdentifyLayerResult) -> Void in
            
            //hide progress indicator
            self?.view.window?.hideProgressIndicator()
            
            if let error = identifyLayerResult.error {
                self?.showAlert(messageText: "Error", informativeText: "Error while identifying features :: \(error.localizedDescription)")
            }
            else {
                var popups = [AGSPopup]()
                let geoElements = identifyLayerResult.geoElements
                
                //create a popup for each geoElement identified
                for geoElement in geoElements {
                    let popup = AGSPopup(geoElement: geoElement)
                    popups.append(popup)
                }
                
                if popups.count > 0 {
                    //show popups view controller
                    self?.showPopupsViewController(with: popups)
                }
                else {
                    //hide popups view controller
                    self?.hidePopupsViewController(animated: true)
                }
            }
        }
    }
    
    //MARK: - Show/hide popups view controller
    
    private func showPopupsViewController(with popups: [AGSPopup]) {
        
        //hide popups view controller if it exists
        if self.popupsVC != nil {
            self.popupsVC.view.removeFromSuperview()
            self.popupsVC = nil
        }
        
        //initialize popups view controller with popups
        self.popupsVC = AGSPopupsViewController(popups: popups)
        
        //set the delegate
        self.popupsVC.delegate = self
        
        //sizing
        self.popupsVC.view.frame = self.containerView.bounds
        self.popupsVC.view.autoresizingMask = [NSView.AutoresizingMask.width, NSView.AutoresizingMask.height]
        self.containerView.addSubview(self.popupsVC.view)
        
        //animate the popups view controller from left
        self.containerViewLeadingConstraint.animator().constant = 0
    }
    
    private func hidePopupsViewController(animated: Bool) {
        
        //hide popups view controller to the left with or without animation
        if animated {
            self.containerViewLeadingConstraint.animator().constant = -200
        }
        else {
            self.containerViewLeadingConstraint.constant = -200
        }
        
        //clear selection
        self.featureLayer.clearSelection()
        
        //remove the popups view controller view from super view
        self.popupsVC?.view.removeFromSuperview()
        self.popupsVC = nil
    }
    
    //MARK: -  AGSPopupsViewContollerDelegate methods
    
    func popupsViewController(_ popupsViewController: AGSPopupsViewController, sketchEditorFor popup: AGSPopup) -> AGSSketchEditor? {
        
        //start sketch editing and
        //zoom to the existing feature's geometry
        if let geometry = popup.geoElement.geometry {
            sketchEditor?.start(with: geometry)
            self.mapView.setViewpointGeometry(geometry.extent, padding: 10, completion: nil)
        }
        
        return self.sketchEditor
    }
    
    func popupsViewController(_ popupsViewController: AGSPopupsViewController, didChangeToCurrentPopup popup: AGSPopup) {
        //clear previous selection
        self.featureLayer.clearSelection()
        
        //highlight the selected feature
        self.featureLayer.select(popup.geoElement as! AGSFeature)
    }
    
    //called when the user clicks on Finish button
    func popupsViewController(_ popupsViewController: AGSPopupsViewController, didFinishEditingFor popup: AGSPopup) {
        
        if self.isAddingNewFeature {
            //done adding new feature
            self.isAddingNewFeature = false
        }
        
        //disable sketch editor
        self.disableSketchEditor()
        
        let feature = popup.geoElement as! AGSFeature
        
        // simplify the geometry, this will take care of self intersecting polygons and
        feature.geometry = AGSGeometryEngine.simplifyGeometry(feature.geometry!)
        
        //normalize the geometry, this will take care of geometries that extend beyone the dateline
        //(ifwraparound was enabled on the map)
        feature.geometry = AGSGeometryEngine.normalizeCentralMeridian(of: feature.geometry!)
        
        //apply edits to the service
        self.applyEdits()
    }
    
    //called when the user clicks Cancel button
    func popupsViewController(_ popupsViewController: AGSPopupsViewController, didCancelEditingFor popup: AGSPopup) {
        
        if self.isAddingNewFeature {
            //canceled adding a new feature
            self.isAddingNewFeature = false
            
            //hide the popupsViewController
            self.hidePopupsViewController(animated: true)
        }
        //disable sketch editor
        self.disableSketchEditor()
    }
    
    //called when the only popup in the popups view controller is deleted
    func popupsViewControllerDidFinishViewingPopups(_ popupsViewController: AGSPopupsViewController) {
        
        //slide the popups view controller to the left
        self.hidePopupsViewController(animated: true)
    }

    private func disableSketchEditor() {
        
        //stop the sketchEditor
        self.mapView.sketchEditor?.stop()
        
        //clear any geometry present
        self.mapView.sketchEditor?.clearGeometry()
    }
    
    //MARK: - FeatureTemplatePickerVCDelegate
    
    func featureTemplatePickerVC(_ featureTemplatePickerVC: FeatureTemplatePickerVC, didSelectFeatureTemplate template: AGSFeatureTemplate, forFeatureLayer featureLayer: AGSFeatureLayer) {
        
        let featureTable = self.featureLayer.featureTable as! AGSArcGISFeatureTable
        //create a new feature based on the template
        let newFeature = featureTable.createFeature(with: template)!
        
        //set the geometry as the center of the screen
        if let visibleArea = self.mapView.visibleArea {
            newFeature.geometry = visibleArea.extent.center
        }
        else {
            newFeature.geometry = AGSPoint(x: 0, y: 0, spatialReference: self.map.spatialReference)
        }
        
        //initialize a popup definition using the feature layer
        let popupDefinition = AGSPopupDefinition(popupSource: self.featureLayer)
        //create a popup
        let popup = AGSPopup(geoElement: newFeature, popupDefinition: popupDefinition)
        
        self.showPopupsViewController(with: [popup])
        self.popupsVC.startEditingCurrentPopup()
    }
    
    func featureTemplatePickerVCDidCancel(_ featureTemplatePickerVC: FeatureTemplatePickerVC) {
        //cancel adding a new feature
        self.isAddingNewFeature = false
        
        //hide sheet
        self.dismissViewController(featureTemplatePickerVC)
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let id = segue.identifier, id.rawValue == "FeatureTemplateSegue" else {
            return
        }
        let controller = segue.destinationController as! FeatureTemplatePickerVC
        controller.featureLayer = self.featureLayer
        controller.delegate = self
        
        //will start adding new feature
        self.isAddingNewFeature = true
    }
    
    //MARK: - Helper methods
    
    private func showAlert(messageText:String, informativeText:String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.beginSheetModal(for: self.view.window!)
    }
}
