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

class FindAddressViewController: NSViewController, AGSGeoViewTouchDelegate, NSTextFieldDelegate {
    
    @IBOutlet private var mapView:AGSMapView!
    @IBOutlet private var button:NSButton!
    @IBOutlet private var searchField:NSSearchField!
    
    private var locatorTask:AGSLocatorTask!
    private var geocodeParameters:AGSGeocodeParameters!
    private var graphicsOverlay:AGSGraphicsOverlay!
    
    private let locatorURL = "https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //instantiate a map with an imagery with labels basemap
        let map = AGSMap(basemap: AGSBasemap.imageryWithLabels())
        self.mapView.map = map
        self.mapView.touchDelegate = self
        
        //initialize the graphics overlay and add to the map view
        self.graphicsOverlay = AGSGraphicsOverlay()
        self.mapView.graphicsOverlays.add(self.graphicsOverlay)
        
        //initialize locator task
        self.locatorTask = AGSLocatorTask(url: URL(string: self.locatorURL)!)
        
        //initialize geocode parameters
        self.geocodeParameters = AGSGeocodeParameters()
        self.geocodeParameters.resultAttributeNames.append(contentsOf: ["*"])
        self.geocodeParameters.minScore = 75
        
    }
    
    /// Creates a graphic with the specified point and attributes.
    ///
    /// - Parameters:
    ///   - point: A point for the geometry of the graphic.
    ///   - attributes: A dictionary of attributes for the graphic.
    /// - Returns: A new `AGSGraphic` object.
    private func makeGraphic(point: AGSPoint, attributes: [String: Any]?) -> AGSGraphic {
        let markerImage = #imageLiteral(resourceName: "RedMarker")
        let symbol = AGSPictureMarkerSymbol(image: markerImage)
        symbol.leaderOffsetY = markerImage.size.height / 2
        symbol.offsetY = markerImage.size.height / 2
        return AGSGraphic(geometry: point, symbol: symbol, attributes: attributes)
    }
    
    private func geocodeSearchText(_ text:String) {
        //clear already existing graphics
        self.graphicsOverlay.graphics.removeAllObjects()
        
        //dismiss the callout if already visible
        self.mapView.callout.dismiss()
        
        //show progress indicator
        self.view.window?.showProgressIndicator()
        
        //perform geocode with input text
        locatorTask.geocode(withSearchText: text, parameters: geocodeParameters) { [weak self] (results: [AGSGeocodeResult]?, error: Error?) -> Void in
            guard let strongSelf = self else { return }
            
            //hide progress indicator
            strongSelf.view.window?.hideProgressIndicator()
            
            if let error = error {
                strongSelf.showAlert("Error", informativeText: error.localizedDescription)
            } else {
                if let result = results?.first {
                    //create a graphic for the first result and add to the graphics overlay
                    let graphic = strongSelf.makeGraphic(point: result.displayLocation!, attributes: result.attributes)
                    strongSelf.graphicsOverlay.graphics.add(graphic)
                    //zoom to the extent of the result
                    if let extent = result.extent {
                        strongSelf.mapView.setViewpointGeometry(extent)
                    }
                } else {
                    //provide feedback in case of failure
                    strongSelf.showAlert("Error", informativeText: "No results found")
                }
            }
        }
    }
    
    //MARK: - Callout
    
    //method shows the callout for the specified graphic,
    //populates the title and detail of the callout with specific attributes
    //hides the accessory button
    private func showCallout(for graphic:AGSGraphic, at point:AGSPoint) {
        let addressType = graphic.attributes["Addr_type"] as! String
        self.mapView.callout.title = graphic.attributes["Match_addr"] as? String ?? ""
        
        if addressType == "POI" {
            self.mapView.callout.detail = graphic.attributes["Place_addr"] as? String ?? ""
        }
        else {
            self.mapView.callout.detail = nil
        }
        
        self.mapView.callout.show(for: graphic, tapLocation: point, animated: true)
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        //dismiss the callout
        self.mapView.callout.dismiss()
        
        //show progress indicator
        self.view.window?.showProgressIndicator()
        
        //identify graphics at the tapped location
        self.mapView.identify(self.graphicsOverlay, screenPoint: screenPoint, tolerance: 5, returnPopupsOnly: false, maximumResults: 1) { [weak self] (result: AGSIdentifyGraphicsOverlayResult) -> Void in
            
            //hide progress indicator
            self?.view.window?.hideProgressIndicator()
            
            if let error = result.error {
                
                self?.showAlert("Error", informativeText: error.localizedDescription)
            }
            else if result.graphics.count > 0 {
                //show callout for the graphic
                self?.showCallout(for: result.graphics[0], at: mapPoint)
            }
        }
    }
    
    //MARK: - Actions
    
    @IBAction func searchAction(_ sender:NSSearchField) {
        //geocode if field not empty
        if !sender.stringValue.isEmpty {
            self.geocodeSearchText(sender.stringValue)
        }
        else {
            //clear already existing graphics
            self.graphicsOverlay.graphics.removeAllObjects()
            
            //dismiss the callout if already visible
            self.mapView.callout.dismiss()
        }
    }
    
    @IBAction func searchTemplateAction(_ sender:NSMenuItem) {
        let searchString = sender.title
        
        //set the search string on searchField
        self.searchField.stringValue = searchString
        
        //geocode
        self.geocodeSearchText(searchString)
    }
    
    //MARK: - Helper methods
    
    private func showAlert(_ messageText:String, informativeText:String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.beginSheetModal(for: self.view.window!)
    }
}
