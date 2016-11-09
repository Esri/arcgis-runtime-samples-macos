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
                self.toggleDirectionsList(true, animated: true)
            }
            else {
                //hide directionsList
                self.toggleDirectionsList(false, animated: true)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let map = AGSMap(basemap: AGSBasemap.topographicBasemap())
        
        self.mapView.map = map
        self.mapView.touchDelegate = self
        
        //add the graphics overlays to the map view
        self.mapView.graphicsOverlays.addObjectsFromArray([routeGraphicsOverlay, directionsGraphicsOverlay, barrierGraphicsOverlay, stopGraphicsOverlay])
        
        //zoom to viewpoint
        self.mapView.setViewpointCenter(AGSPoint(x: -13042254.715252, y: 3857970.236806, spatialReference: AGSSpatialReference(WKID: 3857)), scale: 1e5, completion: nil)
        
        //initialize route task
        self.routeTask = AGSRouteTask(URL: NSURL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/NetworkAnalysis/SanDiego/NAServer/Route")!)
        
        //get default parameters
        self.getDefaultParameters()
        
        //hide directions list
        self.toggleDirectionsList(false, animated: false)
    }
    
    //MARK: - Route logic
    
    func getDefaultParameters() {
        
        //show progress indicator
        self.view.window?.showProgressIndicator()
        
        self.routeTask.defaultRouteParametersWithCompletion({ [weak self] (params: AGSRouteParameters?, error: NSError?) -> Void in
            
            //hide progress indicator
            self?.view.window?.hideProgressIndicator()
            
            if let error = error {
                self?.showAlert("Error", informativeText: error.localizedDescription)
            }
            else {
                self?.routeParameters = params
                //enable bar button item
                self?.routeParametersButton.enabled = true
            }
        })
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
            stop.name = "\(self.stopGraphicsOverlay.graphics.indexOfObject(graphic)+1)"
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
        
        self.routeTask.solveRouteWithParameters(self.routeParameters) { [weak self] (routeResult:AGSRouteResult?, error:NSError?) -> Void in
            
            //hide progress indicator
            self?.view.window?.hideProgressIndicator()
            
            if let error = error {
                self?.showAlert("Error", informativeText: "\(error.localizedDescription) \(error.localizedFailureReason ?? "")")
            }
            else {
                let route = routeResult!.routes[0]
                let routeGraphic = AGSGraphic(geometry: route.routeGeometry, symbol: self!.routeSymbol(), attributes: nil)
                self?.routeGraphicsOverlay.graphics.addObject(routeGraphic)
                self?.generatedRoute = route
            }
        }
    }
    
    func routeSymbol() -> AGSSimpleLineSymbol {
        let symbol = AGSSimpleLineSymbol(style: .Solid, color: NSColor.yellowColor(), width: 5)
        return symbol
    }
    
    func directionSymbol() -> AGSSimpleLineSymbol {
        let symbol = AGSSimpleLineSymbol(style: .DashDot, color: NSColor.orangeColor(), width: 5)
        return symbol
    }
    
    private func symbolForStopGraphic(index: Int) -> AGSSymbol {
        let markerImage = NSImage(named: "BlueMarker")!
        let markerSymbol = AGSPictureMarkerSymbol(image: markerImage)
        markerSymbol.offsetY = markerImage.size.height/2
        
        let textSymbol = AGSTextSymbol(text: "\(index)", color: NSColor.whiteColor(), size: 20, horizontalAlignment: AGSHorizontalAlignment.Center, verticalAlignment: AGSVerticalAlignment.Middle)
        textSymbol.offsetY = markerSymbol.offsetY
        
        let compositeSymbol = AGSCompositeSymbol(symbols: [markerSymbol, textSymbol])
        
        return compositeSymbol
    }
    
    func barrierSymbol() -> AGSSimpleFillSymbol {
        return AGSSimpleFillSymbol(style: .DiagonalCross, color: NSColor.redColor(), outline: nil)
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        //normalize geometry
        let normalizedPoint = AGSGeometryEngine.normalizeCentralMeridianOfGeometry(mapPoint)!
        
        if segmentedControl.selectedSegment == 0 {
            //create a graphic for stop and add to the graphics overlay
            let graphicsCount = self.stopGraphicsOverlay.graphics.count
            let symbol = self.symbolForStopGraphic(graphicsCount+1)
            let graphic = AGSGraphic(geometry: normalizedPoint, symbol: symbol, attributes: nil)
            self.stopGraphicsOverlay.graphics.addObject(graphic)
            
            //enable route button
            if graphicsCount > 0 {
                self.routeButton.enabled = true
            }
        }
        else {
            let bufferedGeometry = AGSGeometryEngine.bufferGeometry(normalizedPoint, byDistance: 500)
            let symbol = self.barrierSymbol()
            let graphic = AGSGraphic(geometry: bufferedGeometry, symbol: symbol, attributes: nil)
            self.barrierGraphicsOverlay.graphics.addObject(graphic)
        }
    }
    
    //MARK: - Actions
    
    @IBAction func clearAction(_ sender:NSButton) {
        if segmentedControl.selectedSegment == 0 {
            self.stopGraphicsOverlay.graphics.removeAllObjects()
            self.routeButton.enabled = false
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
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "RouteSettingsSegue" {
            let controller = segue.destinationController as! RouteParametersViewController
            controller.routeParameters = self.routeParameters
        }
        else if segue.identifier == "DirectionsListSegue" {
            self.directionsListViewController = segue.destinationController as! DirectionsListViewController
            self.directionsListViewController.delegate = self
        }
    }
    
    //MARK: - DirectionsListVCDelegate
    
    func directionsListViewControllerDidDeleteRoute(directionsListViewController: DirectionsListViewController) {
        self.generatedRoute = nil;
        self.routeGraphicsOverlay.graphics.removeAllObjects()
        self.directionsGraphicsOverlay.graphics.removeAllObjects()
    }
    
    func directionsListViewController(directionsListViewController: DirectionsListViewController, didSelectDirectionManuever directionManeuver: AGSDirectionManeuver) {
        //remove previous directions
        self.directionsGraphicsOverlay.graphics.removeAllObjects()
        
        //show the maneuver geometry on the map view
        let directionGraphic = AGSGraphic(geometry: directionManeuver.geometry!, symbol: self.directionSymbol(), attributes: nil)
        self.directionsGraphicsOverlay.graphics.addObject(directionGraphic)
        
        //zoom to the direction
        self.mapView.setViewpointGeometry(directionManeuver.geometry!.extent, padding: 100, completion: nil)
    }
    
    //MARK: - Helper methods
    
    private func showAlert(messageText:String, informativeText:String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.beginSheetModalForWindow(self.view.window!, completionHandler: nil)
    }
}
