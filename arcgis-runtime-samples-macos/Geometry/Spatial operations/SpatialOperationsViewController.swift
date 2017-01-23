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

class SpatialOperationsViewController: NSViewController {

    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var visualEffectView:NSVisualEffectView!
    
    private var graphicsOverlay = AGSGraphicsOverlay()
    private var polygon1, polygon2: AGSPolygonBuilder!
    private var resultGraphic: AGSGraphic!
    
    let lineSymbol = AGSSimpleLineSymbol(style: .Solid, color: NSColor.blackColor(), width: 1)
    
    let operations = ["None", "Union", "Difference", "Symmetric Difference", "Intersection"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize map with basemap
        let map = AGSMap(basemap: AGSBasemap.topographicBasemap())
        
        //assign map to map view
        self.mapView.map = map
        
        //add graphics overlay to map view
        self.mapView.graphicsOverlays.addObject(self.graphicsOverlay)
        
        //initial viewpoint
        let center = AGSPoint(x: -13453, y: 6710127, spatialReference: AGSSpatialReference.webMercator())
        self.mapView.setViewpointCenter(center, scale: 30000, completion: nil)
        
        //add two polygons to be used in the operations
        self.addPolygons()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        //add border to visual effect view
        self.visualEffectView.layer?.borderColor = NSColor.grayColor().CGColor
        self.visualEffectView.layer?.borderWidth = 1
    }
    
    private func addPolygons() {
        
        //polygon 1
        self.polygon1 = AGSPolygonBuilder(spatialReference: AGSSpatialReference.webMercator())
        polygon1.addPointWithX(-13960, y: 6709400)
        polygon1.addPointWithX(-14660, y: 6710000)
        polygon1.addPointWithX(-13760, y: 6710730)
        polygon1.addPointWithX(-13300, y: 6710500)
        polygon1.addPointWithX(-13160, y: 6710100)
        
        //symbol
        let fillSymbol1 = AGSSimpleFillSymbol(style: .Solid, color: NSColor.blueColor(), outline: lineSymbol)
        
        //graphic
        let polygon1Graphic = AGSGraphic(geometry: polygon1.toGeometry(), symbol: fillSymbol1, attributes: nil)
        
        // create green polygon
        // outer ring
        let outerRing = AGSMutablePart(spatialReference: AGSSpatialReference.webMercator())
        outerRing.addPointWithX(-13060, y: 6711030)
        outerRing.addPointWithX(-12160, y: 6710730)
        outerRing.addPointWithX(-13160, y: 6709700)
        outerRing.addPointWithX(-14560, y: 6710730)
        outerRing.addPointWithX(-13060, y: 6711030)
        
        // inner ring
        let innerRing = AGSMutablePart(spatialReference: AGSSpatialReference.webMercator())
        innerRing.addPointWithX(-13060, y: 6710910)
        innerRing.addPointWithX(-14160, y: 6710630)
        innerRing.addPointWithX(-13160, y: 6709900)
        innerRing.addPointWithX(-12450, y: 6710660)
        innerRing.addPointWithX(-13060, y: 6710910)
        
        self.polygon2 = AGSPolygonBuilder(spatialReference: AGSSpatialReference.webMercator())
        polygon2.parts.addPart(outerRing)
        polygon2.parts.addPart(innerRing)
        
        //symbol
        let fillSymbol2 = AGSSimpleFillSymbol(style: .Solid, color: NSColor.greenColor(), outline: lineSymbol)
        
        //graphic
        let polygon2Graphic = AGSGraphic(geometry: polygon2.toGeometry(), symbol: fillSymbol2, attributes: nil)
        
        //add graphics to graphics overlay
        self.graphicsOverlay.graphics.addObjectsFromArray([polygon1Graphic, polygon2Graphic])
    }
    
    private func performOperation(index: Int) {
        var resultGeometry: AGSGeometry
        
        switch index {
            
        case 1: //Union
            resultGeometry = AGSGeometryEngine.unionOfGeometry1(self.polygon1.toGeometry(), geometry2: self.polygon2.toGeometry())!
            
        case 2: //Difference
            resultGeometry = AGSGeometryEngine.differenceOfGeometry1(self.polygon2.toGeometry(), geometry2: self.polygon1.toGeometry())!
            
        case 3: //Symmetric difference
            resultGeometry = AGSGeometryEngine.symmetricDifferenceOfGeometry1(self.polygon2.toGeometry(), geometry2: self.polygon1.toGeometry())!
            
        default: //Intersection
            resultGeometry = AGSGeometryEngine.intersectionOfGeometry1(self.polygon1.toGeometry(), geometry2: self.polygon2.toGeometry())!
        }
        
        //using red fill symbol for result with black border
        let symbol = AGSSimpleFillSymbol(style: .Solid, color: NSColor.redColor(), outline: lineSymbol)
        
        //create result graphic if not present
        if self.resultGraphic == nil {
            self.resultGraphic = AGSGraphic(geometry: resultGeometry, symbol: symbol, attributes: nil)
            self.graphicsOverlay.graphics.addObject(self.resultGraphic)
        }
        //update the geometry if already present
        else {
            self.resultGraphic.geometry = resultGeometry
        }
    }
    
    //MARK: - Actions
    
    @IBAction func radioButtonAction(_ sender:NSButton) {
        //In case of None, remove the result graphic if present
        if sender.tag == 0 {
            if self.resultGraphic != nil {
                self.graphicsOverlay.graphics.removeObject(self.resultGraphic)
                self.resultGraphic = nil
            }
        }
        //perform operation
        else {
            self.performOperation(sender.tag)
        }
    }

}
