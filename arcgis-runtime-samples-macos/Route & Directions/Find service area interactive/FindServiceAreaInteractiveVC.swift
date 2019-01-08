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

class FindServiceAreaInteractiveVC: NSViewController, AGSGeoViewTouchDelegate {
    @IBOutlet private var mapView: AGSMapView!
    @IBOutlet private var segmentedControl: NSSegmentedControl!
    @IBOutlet private var serviceAreaButton: NSButton!
    @IBOutlet private var firstTimeBreakSlider: NSSlider!
    @IBOutlet private var secondTimeBreakSlider: NSSlider!
    @IBOutlet private var firstTimeBreakLabel: NSTextField!
    @IBOutlet private var secondTimeBreakLabel: NSTextField!
    
    private var facilitiesGraphicsOverlay = AGSGraphicsOverlay()
    private var barriersGraphicsOverlay = AGSGraphicsOverlay()
    private var serviceAreaGraphicsOverlay = AGSGraphicsOverlay()
    private var barrierGraphic: AGSGraphic!
    private var serviceAreaTask: AGSServiceAreaTask!
    private var serviceAreaParameters: AGSServiceAreaParameters!
    
    var firstTimeBreak: Int = 3
    var secondTimeBreak: Int = 8
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize map with basemap
        let map = AGSMap(basemap: .terrainWithLabels())
        
        //center for initial viewpoint
        let center = AGSPoint(x: -13041154, y: 3858170, spatialReference: .webMercator())
        
        //initial viewpoint
        map.initialViewpoint = AGSViewpoint(center: center, scale: 1e5)
        
        //assign map to map view
        self.mapView.map = map
        
        //assign touch delegate as self to know when use interacted with the map view
        //Will be adding facilities and barriers on interaction
        self.mapView.touchDelegate = self
        
        //initialize service area task
        self.serviceAreaTask = AGSServiceAreaTask(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/NetworkAnalysis/SanDiego/NAServer/ServiceArea")!)
        
        //get default parameters for the task
        self.getDefaultParameters()
        
        //facility picture marker symbol
        let facilitySymbol = AGSPictureMarkerSymbol(image: #imageLiteral(resourceName: "Facility"))
        
        //offset symbol in Y to align image properly
        facilitySymbol.offsetY = 21
        
        //assign renderer on facilities graphics overlay using the picture marker symbol
        self.facilitiesGraphicsOverlay.renderer = AGSSimpleRenderer(symbol: facilitySymbol)
        
        //barrier symbol
        let barrierSymbol = AGSSimpleFillSymbol(style: .diagonalCross, color: .red, outline: nil)
        
        //set symbol on barrier graphics overlay using renderer
        self.barriersGraphicsOverlay.renderer = AGSSimpleRenderer(symbol: barrierSymbol)
        
        //add graphicOverlays to the map. One for facilities, barriers and service areas
        self.mapView.graphicsOverlays.addObjects(from: [self.serviceAreaGraphicsOverlay, self.barriersGraphicsOverlay, self.facilitiesGraphicsOverlay])
    }
    
    private func getDefaultParameters() {
        //get default parameters
        self.serviceAreaTask.defaultServiceAreaParameters { [weak self] (parameters: AGSServiceAreaParameters?, error: Error?) in
            guard error == nil else {
                self?.showAlert(messageText: "Error getting default parameters", informativeText: error!.localizedDescription)
                return
            }
            
            //keep a reference to the default parameters to be used later
            self?.serviceAreaParameters = parameters
            
            //enable service area bar button item
            self?.serviceAreaButton.isEnabled = true
        }
    }
    
    private func serviceAreaSymbol(for index: Int) -> AGSSymbol {
        //fill symbol for service area
        var fillSymbol: AGSSimpleFillSymbol
        
        if index == 0 {
            let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: NSColor(red: 0.4, green: 0.4, blue: 0, alpha: 0.3), width: 2)
            fillSymbol = AGSSimpleFillSymbol(style: .solid, color: NSColor(red: 0.8, green: 0.8, blue: 0, alpha: 0.3), outline: lineSymbol)
        } else {
            let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: NSColor(red: 0, green: 0.4, blue: 0, alpha: 0.3), width: 2)
            fillSymbol = AGSSimpleFillSymbol(style: .solid, color: NSColor(red: 0, green: 0.8, blue: 0, alpha: 0.3), outline: lineSymbol)
        }
        
        return fillSymbol
    }
    
    // MARK: - Actions
    
    @IBAction private func serviceArea(_ sender: NSButton) {
        //remove previously added service areas
        self.serviceAreaGraphicsOverlay.graphics.removeAllObjects()
        
        let facilitiesGraphics = facilitiesGraphicsOverlay.graphics as! [AGSGraphic]
        
        //check if at least a single facility is added
        guard !facilitiesGraphics.isEmpty else {
            showAlert(messageText: "Error", informativeText: "At least one facility is required")
            return
        }
        
        //add facilities
        var facilities = [AGSServiceAreaFacility]()
        
        //for each graphic in facilities graphicsOverlay add a facility to the parameters
        for graphic in facilitiesGraphics {
            let point = graphic.geometry as! AGSPoint
            let facility = AGSServiceAreaFacility(point: point)
            facilities.append(facility)
        }
        self.serviceAreaParameters.setFacilities(facilities)
        
        //add barriers
        var barriers = [AGSPolygonBarrier]()
        
        //for each graphic in barrier graphicsOverlay add a barrier to the parameters
        for graphic in self.barriersGraphicsOverlay.graphics as! [AGSGraphic] {
            let polygon = graphic.geometry as! AGSPolygon
            let barrier = AGSPolygonBarrier(polygon: polygon)
            barriers.append(barrier)
        }
        self.serviceAreaParameters.setPolygonBarriers(barriers)
        
        //set time breaks
        self.serviceAreaParameters.defaultImpedanceCutoffs = [NSNumber(value: self.firstTimeBreak), NSNumber(value: self.secondTimeBreak)]
        
        self.serviceAreaParameters.geometryAtOverlap = .dissolve
        
        //solve for service area
        self.serviceAreaTask.solveServiceArea(with: self.serviceAreaParameters) { [weak self] (result: AGSServiceAreaResult?, error: Error?) in
            guard let weakSelf = self else {
                return
            }
            
            guard error == nil else {
                self?.showAlert(messageText: "Error solving service area", informativeText: error!.localizedDescription)
                return
            }
            
            //add resulting polygons as graphics to the overlay
            //since we are using `geometryAtOVerlap` as `dissolve` and the cutoff values
            //are the same across facilities, we only need to draw the resultPolygons at
            //facility index 0. It will contain either merged or multipart polygons
            if let polygons = result?.resultPolygons(atFacilityIndex: 0) {
                for (index, polygon) in polygons.enumerated() {
                    let fillSymbol = weakSelf.serviceAreaSymbol(for: index)
                    let graphic = AGSGraphic(geometry: polygon.geometry, symbol: fillSymbol, attributes: nil)
                    weakSelf.serviceAreaGraphicsOverlay.graphics.add(graphic)
                }
            }
        }
    }
    
    @IBAction private func clearAction(_ sender: NSButton) {
        //remove all existing graphics in service area and facilities graphics overlays
        self.serviceAreaGraphicsOverlay.graphics.removeAllObjects()
        self.facilitiesGraphicsOverlay.graphics.removeAllObjects()
        self.barriersGraphicsOverlay.graphics.removeAllObjects()
    }
    
    @IBAction private func sliderValueChanged(_ sender: NSSlider) {
        if sender == self.firstTimeBreakSlider {
            self.firstTimeBreakLabel.stringValue = "\(sender.integerValue)"
            self.firstTimeBreak = sender.integerValue
        } else {
            self.secondTimeBreakLabel.stringValue = "\(sender.integerValue)"
            self.secondTimeBreak = sender.integerValue
        }
    }
    
    // MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        if segmentedControl.selectedSegment == 0 {
            //facilities selected
            let graphic = AGSGraphic(geometry: mapPoint, symbol: nil, attributes: nil)
            self.facilitiesGraphicsOverlay.graphics.add(graphic)
        } else {
            //barriers selected
            let bufferedGeometry = AGSGeometryEngine.bufferGeometry(mapPoint, byDistance: 500)
            let graphic = AGSGraphic(geometry: bufferedGeometry, symbol: nil, attributes: nil)
            self.barriersGraphicsOverlay.graphics.add(graphic)
        }
    }
    
    // MARK: - Helper methods
    
    private func showAlert(messageText: String, informativeText: String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.beginSheetModal(for: self.view.window!)
    }
}
