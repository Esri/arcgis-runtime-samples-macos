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

class RouteAroundBarriersVC: NSViewController, AGSGeoViewTouchDelegate, DirectionsListVCDelegate {

    @IBOutlet var mapView:AGSMapView!
    @IBOutlet var segmentedControl:NSSegmentedControl!
    @IBOutlet var routeParametersButton:NSButton!
    @IBOutlet var routeButton:NSButton!
    @IBOutlet var directionsLeadingConstraint:NSLayoutConstraint!
    
    private var stopGraphicsOverlay = AGSGraphicsOverlay()
    private var barrierGraphicsOverlay = AGSGraphicsOverlay()
    private var routeGraphicsOverlay = AGSGraphicsOverlay()
    private var directionsGraphicsOverlay = AGSGraphicsOverlay()
    
    private var routeTask:AGSRouteTask!
    private var routeParameters:AGSRouteParameters!
    //private var isDirectionsListVisible = false
    private var directionsListViewController:DirectionsListViewController!
    
    var generatedRoute:AGSRoute! {
        didSet {
            if generatedRoute != nil {
                self.directionsListViewController?.route = generatedRoute
                //show directionsList
                self.toggleDirectionsList(on: true, animated: true)
            }
            else {
                //hide directionsList
                self.toggleDirectionsList(on: false, animated: true)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let map = AGSMap(basemap: .topographic())
        
        self.mapView.map = map
        self.mapView.touchDelegate = self
        
        //add the graphics overlays to the map view
        self.mapView.graphicsOverlays.addObjects(from: [routeGraphicsOverlay, directionsGraphicsOverlay, barrierGraphicsOverlay, stopGraphicsOverlay])
        
        //zoom to viewpoint
        self.mapView.setViewpointCenter(AGSPoint(x: -13042254.715252, y: 3857970.236806, spatialReference: AGSSpatialReference(wkid: 3857)), scale: 1e5, completion: nil)
        
        //initialize route task
        self.routeTask = AGSRouteTask(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/NetworkAnalysis/SanDiego/NAServer/Route")!)
        
        //get default parameters
        self.getDefaultParameters()
        
        //hide directions list
        self.toggleDirectionsList(on: false, animated: false)
    }
    
    //MARK: - Route logic
    
    func getDefaultParameters() {
        
        //show progress indicator
        self.view.window?.showProgressIndicator()
        
        self.routeTask.defaultRouteParameters { [weak self] (params: AGSRouteParameters?, error: Error?) -> Void in
            
            //hide progress indicator
            self?.view.window?.hideProgressIndicator()
            
            if let error = error {
                self?.showAlert(messageText: "Error", informativeText: error.localizedDescription)
            }
            else {
                self?.routeParameters = params
                //enable bar button item
                self?.routeParametersButton.isEnabled = true
            }
        }
    }
    
    @IBAction func route(_ sender:NSButton) {
        //add check
        if self.routeParameters == nil || self.stopGraphicsOverlay.graphics.count < 2 {
            //SVProgressHUD.showErrorWithStatus("Either parameters not loaded or not sufficient stops")
            return
        }
        
        //clear routes
        self.routeGraphicsOverlay.graphics.removeAllObjects()
        
        self.routeParameters.returnStops = true
        self.routeParameters.returnDirections = true
        
        //add stops
        var stops = [AGSStop]()
        for graphic in self.stopGraphicsOverlay.graphics as AnyObject as! [AGSGraphic] {
            let stop = AGSStop(point: graphic.geometry as! AGSPoint)
            stop.name = "\(self.stopGraphicsOverlay.graphics.index(of: graphic)+1)"
            stops.append(stop)
        }
        self.routeParameters.clearStops()
        self.routeParameters.setStops(stops)
        
        //add barriers
        var barriers = [AGSPolygonBarrier]()
        for graphic in self.barrierGraphicsOverlay.graphics as AnyObject as! [AGSGraphic] {
            let polygon = graphic.geometry as! AGSPolygon
            let barrier = AGSPolygonBarrier(polygon: polygon)
            barriers.append(barrier)
        }
        self.routeParameters.clearPolygonBarriers()
        self.routeParameters.setPolygonBarriers(barriers)
        
        //show progress indicator
        self.view.window?.showProgressIndicator()
        
        self.routeTask.solveRoute(with: self.routeParameters) { [weak self] (routeResult:AGSRouteResult?, error:Error?) -> Void in
            
            //hide progress indicator
            self?.view.window?.hideProgressIndicator()
            
            if let error = error {
                self?.showAlert(messageText: "Error", informativeText: "\(error.localizedDescription) \((error as NSError).localizedFailureReason ?? "")")
            }
            else {
                let route = routeResult!.routes[0]
                let routeGraphic = AGSGraphic(geometry: route.routeGeometry, symbol: self!.routeSymbol(), attributes: nil)
                self?.routeGraphicsOverlay.graphics.add(routeGraphic)
                self?.generatedRoute = route
            }
        }
    }
    
    func routeSymbol() -> AGSSimpleLineSymbol {
        let symbol = AGSSimpleLineSymbol(style: .solid, color: .yellow, width: 5)
        return symbol
    }
    
    func directionSymbol() -> AGSSimpleLineSymbol {
        let symbol = AGSSimpleLineSymbol(style: .dashDot, color: .orange, width: 5)
        return symbol
    }
    
    private func symbolForStopGraphic(withIndex index: Int) -> AGSSymbol {
        let markerImage = NSImage(named: NSImage.Name(rawValue: "BlueMarker"))!
        let markerSymbol = AGSPictureMarkerSymbol(image: markerImage)
        markerSymbol.offsetY = markerImage.size.height/2
        
        let textSymbol = AGSTextSymbol(text: "\(index)", color: .white, size: 20, horizontalAlignment: .center, verticalAlignment: .middle)
        textSymbol.offsetY = markerSymbol.offsetY
        
        let compositeSymbol = AGSCompositeSymbol(symbols: [markerSymbol, textSymbol])
        
        return compositeSymbol
    }
    
    func barrierSymbol() -> AGSSimpleFillSymbol {
        return AGSSimpleFillSymbol(style: .diagonalCross, color: .red, outline: nil)
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        //normalize geometry
        let normalizedPoint = AGSGeometryEngine.normalizeCentralMeridian(of: mapPoint)!
        
        if segmentedControl.selectedSegment == 0 {
            //create a graphic for stop and add to the graphics overlay
            let graphicsCount = self.stopGraphicsOverlay.graphics.count
            let symbol = self.symbolForStopGraphic(withIndex: graphicsCount+1)
            let graphic = AGSGraphic(geometry: normalizedPoint, symbol: symbol, attributes: nil)
            self.stopGraphicsOverlay.graphics.add(graphic)
            
            //enable route button
            if graphicsCount > 0 {
                self.routeButton.isEnabled = true
            }
        }
        else {
            let bufferedGeometry = AGSGeometryEngine.bufferGeometry(normalizedPoint, byDistance: 500)
            let symbol = self.barrierSymbol()
            let graphic = AGSGraphic(geometry: bufferedGeometry, symbol: symbol, attributes: nil)
            self.barrierGraphicsOverlay.graphics.add(graphic)
        }
    }
    
    //MARK: - Actions
    
    @IBAction func clearAction(_ sender:NSButton) {
        if segmentedControl.selectedSegment == 0 {
            self.stopGraphicsOverlay.graphics.removeAllObjects()
            self.routeButton.isEnabled = false
        }
        else {
            self.barrierGraphicsOverlay.graphics.removeAllObjects()
        }
    }
    
    func toggleDirectionsList(on:Bool, animated:Bool) {
        if animated {
            self.directionsLeadingConstraint.animator().constant = on ? 0 : -200
        }
        else {
            self.directionsLeadingConstraint.constant = on ? 0 : -200
        }
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let id = segue.identifier else {
            return
        }
        if id.rawValue == "RouteSettingsSegue" {
            let controller = segue.destinationController as! RouteParametersViewController
            controller.routeParameters = self.routeParameters
        }
        else if id.rawValue == "DirectionsListSegue" {
            self.directionsListViewController = segue.destinationController as! DirectionsListViewController
            self.directionsListViewController.delegate = self
        }
    }
    
    //MARK: - DirectionsListVCDelegate
    
    func directionsListViewControllerDidDeleteRoute(_ directionsListViewController: DirectionsListViewController) {
        self.generatedRoute = nil;
        self.routeGraphicsOverlay.graphics.removeAllObjects()
        self.directionsGraphicsOverlay.graphics.removeAllObjects()
    }
    
    func directionsListViewController(_ directionsListViewController: DirectionsListViewController, didSelectDirectionManuever directionManeuver: AGSDirectionManeuver) {
        //remove previous directions
        self.directionsGraphicsOverlay.graphics.removeAllObjects()
        
        //show the maneuver geometry on the map view
        let directionGraphic = AGSGraphic(geometry: directionManeuver.geometry!, symbol: self.directionSymbol(), attributes: nil)
        self.directionsGraphicsOverlay.graphics.add(directionGraphic)
        
        //zoom to the direction
        self.mapView.setViewpointGeometry(directionManeuver.geometry!.extent, padding: 100, completion: nil)
    }
    
    //MARK: - Helper methods
    
    private func showAlert(messageText:String, informativeText:String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.beginSheetModal(for: self.view.window!)
    }
}
