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

class TerrainExaggerationViewController: NSViewController {

    @IBOutlet weak var exaggerationValue: NSTextField!
    @IBOutlet weak var exaggerationSlider: NSSlider!
    @IBOutlet weak var sceneView: AGSSceneView!
    
    // initialize the scene with the streets basemap
    let scene = AGSScene(basemapType: .streets)
    
    // initialize the surface
    let surface = AGSSurface()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup the surface with an elevation source and add the surface to the scene
        let elevation = AGSArcGISTiledElevationSource(url: .worldElevationService)
        surface.elevationSources.append(elevation)
        scene.baseSurface = surface
        
        // assign the scene to the scene view
        self.sceneView.scene = scene
        
        // set the initial viewpoint and camera
        let initialLocation = AGSPoint(x: -119.94891542688772, y: 46.75792111605992, spatialReference: sceneView.spatialReference)
        let camera = AGSCamera(lookAt: initialLocation, distance: 15000.0, heading: 40.0, pitch: 60.0, roll: 0.0)
        sceneView.setViewpointCamera(camera)
    }
    
    @IBAction func sliderAction(_ sender: NSSlider) {
        // assign the slider value to the elevation exaggeration
        surface.elevationExaggeration = sender.floatValue
        
        // format and display the exaggeration value
        exaggerationValue.stringValue = String(format: "%.1fx", sender.floatValue)
    }
}
