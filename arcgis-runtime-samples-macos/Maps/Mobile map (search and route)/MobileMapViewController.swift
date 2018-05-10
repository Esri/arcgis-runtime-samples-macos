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

class MobileMapViewController: NSViewController, AGSGeoViewTouchDelegate, MapPackagesListVCDelegate {

    @IBOutlet var mapView:AGSMapView!
    
    private var map:AGSMap! {
        didSet {
            //clear all previous data or graphics
            self.resetEverything()
            
            //setup route task
            self.setupRouteTask()
        }
    }
    
    private var locatorTask:AGSLocatorTask?

    private var markerGraphicsOverlay = AGSGraphicsOverlay()
    private var routeGraphicsOverlay = AGSGraphicsOverlay()
    
    private var routeTask:AGSRouteTask!
    private var routeParameters:AGSRouteParameters!
    
    private var reverseGeocodeParameters:AGSReverseGeocodeParameters!
    
    private var locatorTaskCancelable:AGSCancelable!
    private var routeTaskCancelable:AGSCancelable!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize reverse geocode params
        self.reverseGeocodeParameters = AGSReverseGeocodeParameters()
        self.reverseGeocodeParameters.maxResults = 1
        self.reverseGeocodeParameters.resultAttributeNames.append(contentsOf: ["*"])
        
        self.mapView.map = AGSMap(spatialReference: AGSSpatialReference.webMercator())
        
        //touch delegate
        self.mapView.touchDelegate = self
        
        //add graphic overlays
        self.mapView.graphicsOverlays.addObjects(from: [self.routeGraphicsOverlay, self.markerGraphicsOverlay])
    }
    
    private func resetEverything() {
        //clear graphicsOverlays
        self.routeGraphicsOverlay.graphics.removeAllObjects()
        self.markerGraphicsOverlay.graphics.removeAllObjects()
        
        //dismiss callout
        self.mapView.callout.dismiss()
    }
    
    //MARK: - MapPackagesListVCDelegate
    
    func mapPackagesListVC(_ mapPackagesListVC: MapPackagesListVC, wantsToShowMap map: AGSMap, withLocatorTask locatorTask: AGSLocatorTask?) {
        
        self.locatorTask = locatorTask
        self.map = map
        self.mapView.map = map
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let id = segue.identifier, id.rawValue == "EmbedSegue" else {
            return
        }
        let controller = segue.destinationController as! MapPackagesListVC
        controller.delegate = self
    }
    
    private func symbolForStopGraphic(isIndexRequired: Bool, index: Int?) -> AGSSymbol {
        
        let markerImage = NSImage(named: NSImage.Name(rawValue: "BlueMarker"))!
        let markerSymbol = AGSPictureMarkerSymbol(image: markerImage)
        markerSymbol.offsetY = markerImage.size.height/2
        markerSymbol.leaderOffsetY = markerSymbol.offsetY
        
        if isIndexRequired && index != nil {
            let textSymbol = AGSTextSymbol(text: "\(index!)", color: NSColor.white, size: 20, horizontalAlignment: AGSHorizontalAlignment.center, verticalAlignment: AGSVerticalAlignment.middle)
            textSymbol.offsetY = markerSymbol.offsetY
            
            let compositeSymbol = AGSCompositeSymbol(symbols: [markerSymbol, textSymbol])
            return compositeSymbol
        }
        
        return markerSymbol
    }
    
    private func labelSymbolForStop(_ text:String) -> AGSTextSymbol {
        let symbol = AGSTextSymbol(text: text, color: NSColor.white, size: 15, horizontalAlignment: .center, verticalAlignment: .middle)
        symbol.offsetY = 22
        return symbol
    }
    
    private func graphic(for point:AGSPoint, isIndexRequired: Bool, index: Int?) -> AGSGraphic {
        let symbol = self.symbolForStopGraphic(isIndexRequired: isIndexRequired, index: index)
        let graphic = AGSGraphic(geometry: point, symbol: symbol, attributes: nil)
        return graphic
    }
    
    //method returns the symbol for the route graphic
    func routeSymbol() -> AGSSimpleLineSymbol {
        let symbol = AGSSimpleLineSymbol(style: .solid, color: NSColor.blue, width: 5)
        return symbol
    }
    
    //method to show the callout for the provided graphic, with tap location details
    private func showCallout(for graphic:AGSGraphic, at point:AGSPoint, animated:Bool, offset:Bool) {
        
        self.mapView.callout.title = graphic.attributes["Match_addr"] as? String
        
        self.mapView.callout.show(for: graphic, tapLocation: point, animated: animated)
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        if self.routeTask == nil && self.locatorTask == nil {
            return
        }
        else if routeTask == nil {
            //if routing is not possible, then clear previous graphics
            self.markerGraphicsOverlay.graphics.removeAllObjects()
        }
        
        //show progress indicator
        self.view.window?.showProgressIndicator()
        
        //identify to check if a graphic is present
        //if yes, then show callout with geocoding
        //else add a graphic and route if more than one graphic
        self.mapView.identify(self.markerGraphicsOverlay, screenPoint: screenPoint, tolerance: 5, returnPopupsOnly: false) { [weak self] (result:AGSIdentifyGraphicsOverlayResult) in
            
            //hide progress indicator
            self?.view.window?.hideProgressIndicator()
            
            if let error = result.error {
                self?.showAlert(messageText: "Error", informativeText: error.localizedDescription)
            }
            else {
                if result.graphics.count == 0 {
                    //add a graphic
                    var graphic: AGSGraphic
                    
                    if self?.routeTask != nil {
                        let index = self!.markerGraphicsOverlay.graphics.count + 1
                        graphic = self!.graphic(for: mapPoint, isIndexRequired: true, index: index)
                    }
                    else {
                        graphic = self!.graphic(for: mapPoint, isIndexRequired: false, index: nil)
                    }
                    
                    self?.markerGraphicsOverlay.graphics.add(graphic)
                    
                    //reverse geocode
                    self?.reverseGeocode(mapPoint, withGraphic: graphic)
                    
                    //find route
                    self?.route()
                }
                else {
                    //reverse geocode
                    self?.reverseGeocode(mapPoint, withGraphic: result.graphics[0])
                }
            }
        }
    }
    
    //MARK: - Locator
    
    private func reverseGeocode(_ point:AGSPoint, withGraphic graphic:AGSGraphic) {
        if self.locatorTask == nil {
            return
        }
        
        //cancel previous request if any
        if self.locatorTaskCancelable != nil {
            self.locatorTaskCancelable.cancel()
        }
        
        //show progress indicator
        self.view.window?.showProgressIndicator()
        
        self.locatorTaskCancelable = self.locatorTask?.reverseGeocode(withLocation: point, parameters: self.reverseGeocodeParameters) { [weak self](results:[AGSGeocodeResult]?, error:Error?) in
            
            //hide progress indicator
            self?.view.window?.hideProgressIndicator()
            
            if let error = error {
                
                self?.showAlert(messageText: "Error", informativeText: error.localizedDescription)
            }
            else {
                //assign the label property of result as an attributes to the graphic
                //and show the callout
                if let results = results , results.count > 0 {
                    
                    graphic.attributes["Match_addr"] = results.first!.formattedAddressString
                    self?.showCallout(for: graphic, at: point, animated: false, offset: false)
                    return
                }
                else {
                    //no result was found
                    self?.showAlert(messageText: "Error", informativeText: "No address found")
                    
                    //dismiss the callout if already visible
                    self?.mapView.callout.dismiss()
                }
            }
        }
    }
    
    //MARK: - Route
    
    private func setupRouteTask() {
        //clear previous assignments
        self.routeTask = nil
        
        //if map contains network data
        if self.map.transportationNetworks.count > 0 {
            
            self.routeTask = AGSRouteTask(dataset: self.map.transportationNetworks[0])
            
            //get default parameters
            self.getDefaultParameters()
        }
    }
    
    private func getDefaultParameters() {
        
        //show progress indicator
        self.view.window?.showProgressIndicator()
        
        //get the default parameters
        self.routeTask.defaultRouteParameters { [weak self] (params: AGSRouteParameters?, error: Error?) -> Void in
            
            //hide progress indicator
            self?.view.window?.hideProgressIndicator()
            
            if let error = error {
                
                self?.showAlert(messageText: "Error", informativeText: error.localizedDescription)
            }
            else {
                self?.routeParameters = params
            }
        }
    }
    
    private func route() {
        if self.markerGraphicsOverlay.graphics.count <= 1 || self.routeParameters == nil {
            return
        }
        
        //cancel previous request if any
        if self.routeTaskCancelable != nil {
            self.routeTaskCancelable.cancel()
        }
        
        //create stops for last and second last graphic
        let count = self.markerGraphicsOverlay.graphics.count
        let lastGraphic = self.markerGraphicsOverlay.graphics[count-1] as! AGSGraphic
        let secondLastGraphic = self.markerGraphicsOverlay.graphics[count-2] as! AGSGraphic
        let stops = self.stops(for: [secondLastGraphic, lastGraphic])
        
        //add stops to the parameters
        self.routeParameters.clearStops()
        self.routeParameters.setStops(stops)
        
        //show progress indicator
        self.view.window?.showProgressIndicator()
        
        //route
        self.routeTaskCancelable = self.routeTask.solveRoute(with: self.routeParameters) {[weak self] (routeResult:AGSRouteResult?, error:Error?) in
            
            //hide progress indicator
            self?.view.window?.hideProgressIndicator()
            
            if let error = error {
                //show error
                self?.showAlert(messageText: "Error", informativeText: error.localizedDescription)
                
                //remove the last marker
                self?.markerGraphicsOverlay.graphics.removeLastObject()
            }
            else {
                if let route = routeResult?.routes[0] {
                    let routeGraphic = AGSGraphic(geometry: route.routeGeometry, symbol: self?.routeSymbol(), attributes: nil)
                    self?.routeGraphicsOverlay.graphics.add(routeGraphic)
                }
            }
        }
    }
    
    private func stops(for graphics:[AGSGraphic]) -> [AGSStop] {
        var stops = [AGSStop]()
        for graphic in graphics {
            let stop = AGSStop(point: graphic.geometry as! AGSPoint)
            stops.append(stop)
        }
        return stops
    }
    
    //MARK: - actions
    
    @IBAction private func trashAction(_ sender:NSButton) {
        //remove all markers
        self.markerGraphicsOverlay.graphics.removeAllObjects()
        //remove route graphics
        self.routeGraphicsOverlay.graphics.removeAllObjects()
        //dismiss callout
        self.mapView.callout.dismiss()
    }
    
    //MARK: - Helper methods
    
    private func showAlert(messageText:String, informativeText:String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
    }
}


//extension for extracting the right attributes if available
extension AGSGeocodeResult {
    
    public var formattedAddressString : String? {
        
        if !label.isEmpty {
            return label
        }
        
        let addr = attributes?["Address"] as? String
        let street = attributes?["Street"] as? String
        let city = attributes?["City"] as? String
        let region = attributes?["Region"] as? String
        let neighborhood = attributes?["Neighborhood"] as? String
        
        
        if addr != nil && city != nil && region != nil {
            return "\(addr!), \(city!), \(region!)"
        }
        if addr != nil && neighborhood != nil {
            return "\(addr!), \(neighborhood!)"
        }
        if street != nil && city != nil {
            return "\(street!), \(city!)"
        }
        
        return addr
    }
    
    public func attributeValueAs<T>(_ key: String) -> T? {
        return attributes![key] as? T
    }
    
    public func attributeAsStringForKey(_ key: String) -> String? {
        return attributeValueAs(key)
    }
    
    public func attributeAsNonEmptyStringForKey(_ key: String) -> String? {
        if let value = attributeAsStringForKey(key) {
            return value.isEmpty ? nil : value
        }
        return nil
    }
}
