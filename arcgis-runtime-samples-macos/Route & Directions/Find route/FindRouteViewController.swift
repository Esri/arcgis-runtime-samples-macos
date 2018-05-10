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

import Cocoa
import ArcGIS

class FindRouteViewController: NSViewController {

    @IBOutlet var mapView:AGSMapView!
    @IBOutlet var routeButton:NSButton!
    @IBOutlet var directionsButton:NSButton!
    
    //initialize route task
    var routeTask = AGSRouteTask(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/NetworkAnalysis/SanDiego/NAServer/Route")!)
    var routeParameters:AGSRouteParameters?
    
    var stopGraphicsOverlay = AGSGraphicsOverlay()
    var routeGraphicsOverlay = AGSGraphicsOverlay()
    
    var stop1Geometry:AGSPoint {
        return AGSPoint(x: -13041171.537945, y: 3860988.271378, spatialReference: AGSSpatialReference(wkid: 3857))
    }
    var stop2Geometry:AGSPoint {
        return AGSPoint(x: -13041693.562570, y: 3856006.859684, spatialReference: AGSSpatialReference(wkid: 3857))
    }
    
    var generatedRoute:AGSRoute? {
        didSet {
            let flag = generatedRoute != nil
            self.directionsButton.isEnabled = flag
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize map with topographic basemap
        let map = AGSMap(basemap: AGSBasemap.navigationVector())
        self.mapView.map = map
        
        //add graphicsOverlays to the map view
        self.mapView.graphicsOverlays.addObjects(from: [routeGraphicsOverlay, stopGraphicsOverlay])
        
        //zoom to viewpoint
        self.mapView.setViewpointCenter(AGSPoint(x: -13041154.715252, y: 3858170.236806, spatialReference: AGSSpatialReference(wkid: 3857)), scale: 9e4, completion: nil)
        
        //get default parameters
        self.getDefaultParameters()
    }
    
    //add hard coded stops to the map view
    func addStops() {
        
        //start symbol
        let startSymbol = AGSPictureMarkerSymbol(image: NSImage(named: NSImage.Name(rawValue: "StopA"))!)
        startSymbol.offsetY = 22
        
        //start stop graphic
        let startStopGraphic = AGSGraphic(geometry: self.stop1Geometry, symbol: startSymbol, attributes: nil)
        
        //end symbol
        let endSymbol = AGSPictureMarkerSymbol(image: NSImage(named: NSImage.Name(rawValue: "StopB"))!)
        endSymbol.offsetY = 22
        
        //end stop graphic
        let endStopGraphic = AGSGraphic(geometry: self.stop2Geometry, symbol: endSymbol, attributes: nil)
        
        //add graphics to the overlay
        self.stopGraphicsOverlay.graphics.addObjects(from: [startStopGraphic, endStopGraphic])
    }
    
    //method provides a line symbol for the route graphic
    func routeSymbol() -> AGSSymbol {
        
        let outerSymbol = AGSSimpleLineSymbol(style: .solid, color: NSColor.secondaryBlue(), width: 5)
        let innerSymbol = AGSSimpleLineSymbol(style: .solid, color: NSColor.primaryBlue(), width: 2)
        let compositeSymbol = AGSCompositeSymbol(symbols: [outerSymbol, innerSymbol])
        return compositeSymbol
    }
    
    //MARK: - Route logic
    
    //method to get the default parameters for the route task
    func getDefaultParameters() {
        
        //show progress indicator
        self.view.window?.showProgressIndicator()
        
        self.routeTask.defaultRouteParameters { [weak self] (parameters, error) -> Void in
            
            //hide progress indicator
            self?.view.window?.hideProgressIndicator()
            
            guard error == nil else {
                self?.showAlert(messageText: "Error", informativeText: error!.localizedDescription)
                return
            }
            
            //on completion store the parameters
            self?.routeParameters = parameters
            
            //add stops
            self?.addStops()
            
            //enable bar button item
            self?.routeButton.isEnabled = true
            
        }
    }
    
    @IBAction func route(_ sender:NSButton) {
        
        //route only if default parameters are fetched successfully
        guard let routeParameters = self.routeParameters else {
            
            self.showAlert(messageText: "Error", informativeText: "Default route parameters not loaded")
            return
        }
        
        //show progress indicator
        self.view.window?.showProgressIndicator()
        
        //set parameters to return directions
        routeParameters.returnDirections = true
        
        //clear previous routes
        routeGraphicsOverlay.graphics.removeAllObjects()
        
        //clear previous stops
        routeParameters.clearStops()
        
        //set the stops
        let stop1 = AGSStop(point: self.stop1Geometry)
        stop1.name = "A"
        let stop2 = AGSStop(point: self.stop2Geometry)
        stop2.name = "B"
        routeParameters.setStops([stop1, stop2])
        
        self.routeTask.solveRoute(with: routeParameters) { [weak self] (routeResult, error) -> Void in
            
            //hide progress indicator
            self?.view.window?.hideProgressIndicator()
            
            guard let strongSelf = self else {
                return
            }
            
            guard error == nil else {
                self?.showAlert(messageText: "Error", informativeText: error!.localizedDescription)
                return
            }
            
            guard let generatedRoute = routeResult?.routes[0] else {
                self?.showAlert(messageText: "Error", informativeText: "No route found")
                return
            }
            
            //show the resulting route on the map
            //also save a reference to the route object
            //in order to access directions
            self?.generatedRoute = generatedRoute
            
            let routeGraphic = AGSGraphic(geometry: generatedRoute.routeGeometry, symbol: strongSelf.routeSymbol(), attributes: nil)
            strongSelf.routeGraphicsOverlay.graphics.add(routeGraphic)
            
        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let id = segue.identifier, id.rawValue == "DirectionsSegue" else {
            return
        }
        let controller = segue.destinationController as! DirectionsViewController
        controller.route = self.generatedRoute
        controller.preferredContentSize = CGSize(width: 300, height: 300)
    }
    
    //MARK: - Helper methods
    
    private func showAlert(messageText:String, informativeText:String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
    }
}
