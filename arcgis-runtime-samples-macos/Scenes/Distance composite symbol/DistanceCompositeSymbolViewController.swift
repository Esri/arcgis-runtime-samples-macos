//
// Copyright © 2018 Esri.
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

class DistanceCompositeSymbolViewController: NSViewController {
    /// The scene displayed in the scene view.
    let scene = AGSScene(basemap: .imagery())
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        // Add base surface for elevation data
        let surface = AGSSurface()
        let elevationSource = AGSArcGISTiledElevationSource(url: .worldElevationService)
        surface.elevationSources.append(elevationSource)
        scene.baseSurface = surface
    }
    
    /// The scene view managed by the view controller.
    @IBOutlet var sceneView: AGSSceneView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.scene = scene
        
        // Set up the different symbols.
        let modelSymbol = AGSModelSceneSymbol(name: "Bristol", extension: "dae", scale: 100)
        let circleSymbol = AGSSimpleMarkerSymbol(style: .circle, color: .red, size: 10)
        let coneSymbol = AGSSimpleMarkerSceneSymbol.cone(with: .red, diameter: 200, height: 600)
        coneSymbol.pitch = -90.0
        
        // Set up the distance composite symbol.
        let compositeSymbol = AGSDistanceCompositeSceneSymbol()
        compositeSymbol.ranges = [
            AGSDistanceSymbolRange(symbol: modelSymbol, minDistance: 0, maxDistance: 10000),
            AGSDistanceSymbolRange(symbol: coneSymbol, minDistance: 10001, maxDistance: 30000),
            AGSDistanceSymbolRange(symbol: circleSymbol, minDistance: 30001, maxDistance: 0)
        ]
        
        // Create the graphic.
        let aircraftPosition = AGSPoint(x: -2.708471, y: 56.096575, z: 5000, spatialReference: .wgs84())
        let aircraftGraphic = AGSGraphic(geometry: aircraftPosition, symbol: compositeSymbol)
        
        // Create the graphics overlay and add it to the scene view.
        let graphicsOverlay = AGSGraphicsOverlay()
        graphicsOverlay.sceneProperties?.surfacePlacement = .relative
        graphicsOverlay.graphics.add(aircraftGraphic)
        sceneView.graphicsOverlays.add(graphicsOverlay)
        
        // add an orbit camera controller to lock the camera to the graphic
        let cameraController = AGSOrbitGeoElementCameraController(targetGeoElement: aircraftGraphic, distance: 4000)
        cameraController.cameraPitchOffset = 80
        cameraController.cameraHeadingOffset = -30
        sceneView.cameraController = cameraController
    }
}
