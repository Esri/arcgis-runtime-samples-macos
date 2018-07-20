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

class SceneSymbolsViewController: NSViewController {

    @IBOutlet var sceneView:AGSSceneView!
    
    private var graphicsOverlay = AGSGraphicsOverlay()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scene = AGSScene(basemap: .nationalGeographic())
        self.sceneView.scene = scene
        
        //set the camera
        let camera = AGSCamera(latitude: 48.97, longitude: 4.935, altitude: 2082, heading: 60, pitch: 75, roll: 0)
        self.sceneView.setViewpointCamera(camera)
        
        // add base surface for elevation data
        let surface = AGSSurface()
        let elevationSource = AGSArcGISTiledElevationSource(url: .worldElevationService)
        surface.elevationSources.append(elevationSource)
        scene.baseSurface = surface
        
        //add graphics overlay to the scene view
        self.graphicsOverlay.sceneProperties?.surfacePlacement = .absolute
        self.sceneView.graphicsOverlays.add(graphicsOverlay)
        
        //add graphics
        self.addGraphics()
    }
    
    private func addGraphics() {
        //coordinates for the first symbol
        let x = 4.975
        let y = 49.0
        let z = 500.0
        
        //create symbols for all the available 3D symbols
        var symbols = [AGSSimpleMarkerSceneSymbol]()
        
        //cone symbol
        let coneSymbol = AGSSimpleMarkerSceneSymbol(style: .cone, color: self.randColor(), height: 200, width: 200, depth: 200, anchorPosition: .center)
        
        //cube symbol
        let cubeSymbol = AGSSimpleMarkerSceneSymbol(style: .cube, color: self.randColor(), height: 200, width: 200, depth: 200, anchorPosition: .center)
        
        //cylinder symbo
        let cylinderSymbol = AGSSimpleMarkerSceneSymbol(style: .cylinder, color: self.randColor(), height: 200, width: 200, depth: 200, anchorPosition: .center)
        
        //diamond symbol
        let diamondSymbol = AGSSimpleMarkerSceneSymbol(style: .diamond, color: self.randColor(), height: 200, width: 200, depth: 200, anchorPosition: .center)
        
        //sphere symbol
        let sphereSymbol = AGSSimpleMarkerSceneSymbol(style: .sphere, color: self.randColor(), height: 200, width: 200, depth: 200, anchorPosition: .center)
        
        //tetrahedron symbol
        let tetrahedronSymbol = AGSSimpleMarkerSceneSymbol(style: .tetrahedron, color: self.randColor(), height: 200, width: 200, depth: 200, anchorPosition: .center)
        
        //add symbols to an array
        symbols.append(contentsOf: [coneSymbol, cubeSymbol, cylinderSymbol, diamondSymbol, sphereSymbol, tetrahedronSymbol])
        
        //create graphics for each symbol
        var graphics = [AGSGraphic]()
        
        var i = 0
        for symbol in symbols {
            let point = AGSPoint(x: x + 0.01*Double(i), y: y, z: z, spatialReference: AGSSpatialReference.wgs84())
            let graphic = AGSGraphic(geometry: point, symbol: symbol, attributes: nil)
            graphics.append(graphic)
            i = i+1
        }
        
        //add the graphics to the overlay
        self.graphicsOverlay.graphics.addObjects(from: graphics)
    }
    
    //returns a random color
    private func randColor() -> NSColor {
        return NSColor(red: self.randFloat(), green: self.randFloat(), blue: self.randFloat(), alpha: 1.0)
    }
    
    //returns a CGFloat between 0 and 1
    private func randFloat() -> CGFloat {
        return CGFloat(arc4random()%256)/256
    }
}
