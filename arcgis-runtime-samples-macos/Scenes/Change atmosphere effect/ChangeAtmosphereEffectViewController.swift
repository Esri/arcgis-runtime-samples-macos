//
// Copyright 2018 Esri.
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

class ChangeAtmosphereEffectViewController: NSViewController {
    @IBOutlet private weak var sceneView: AGSSceneView!
    @IBOutlet private weak var popUpButton: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// The scene for the scene view.
        let scene = AGSScene(basemapType: .imagery)
        // add the scene to the scene view
        sceneView.scene = scene
        
        /// The surface for the scene.
        let surface = AGSSurface()
        
        /// The URL of the remote service serving elevation data.
        let elevationURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
        
        /// The elevation source for the 3D terrain effect.
        let elevationSource = AGSArcGISTiledElevationSource(url: elevationURL)
        
        // add the elevation source to the surface
        surface.elevationSources.append(elevationSource)
        // add the surface to the scene
        scene.baseSurface = surface
        
        /// The initial camera position for the scene view.
        let camera = AGSCamera(
            latitude: 64.416919,
            longitude: -14.483728,
            altitude: 100,
            heading: 318,
            pitch: 105,
            roll: 0
        )
        
        // set the camera for the scene view
        sceneView.setViewpointCamera(camera)
        
        let menuItems: [NSMenuItem] = [
            NSMenuItem(title: "None",
                       representedObject: AGSAtmosphereEffect.none),
            NSMenuItem(title: "Horizon Only",
                       representedObject: AGSAtmosphereEffect.horizonOnly),
            NSMenuItem(title: "Realistic",
                       representedObject: AGSAtmosphereEffect.realistic)
        ]
        
        // load the effect options into the popup button menu
        for menuItem in menuItems {
            popUpButton.menu?.addItem(menuItem)
        }
        
        // set the initial effect
        updateEffectFromPopUp(popUpButton)
    }
    
    @IBAction func updateEffectFromPopUp(_ popUp: NSPopUpButton) {
        // get the effect from the menu item and reload the scene
        if let atmosphereEffect = popUp.selectedItem?.representedObject as? AGSAtmosphereEffect {
            sceneView.atmosphereEffect = atmosphereEffect
        }
    }
}

private extension NSMenuItem {
    convenience init(title: String, representedObject: Any) {
        self.init()
        self.title = title
        self.representedObject = representedObject
    }
}
