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

class UseSceneLayerViewController: NSViewController {

    @IBOutlet var sceneView:AGSSceneView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize scene with topographic basemap
        let scene = AGSScene(basemap: AGSBasemap.imagery())
        
        //assign scene to the scene view
        self.sceneView.scene = scene
        
        //set the viewpoint camera
        let camera = AGSCamera(latitude: 53.534, longitude: 10, altitude: 500, heading: 0, pitch: 70, roll: 0)
        self.sceneView.setViewpointCamera(camera)
        
        // add base surface for elevation data
        let surface = AGSSurface()
        let elevationSource = AGSArcGISTiledElevationSource(url: URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!)
        surface.elevationSources.append(elevationSource)
        scene.baseSurface = surface
        
        //scene layer
        let sceneLayer = AGSArcGISSceneLayer(url: URL(string: "https://scene.arcgis.com/arcgis/rest/services/Hosted/Building_Hamburg/SceneServer/layers/0")!)
        self.sceneView.scene?.operationalLayers.add(sceneLayer)
    }
    
}
