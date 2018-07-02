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

import Cocoa
import ArcGIS

/// A view controller that manages the interface of the Scene Layer Selection
/// sample.
class SceneLayerSelectionViewController: NSViewController {
    /// The scene displayed in the scene view.
    let scene: AGSScene
    let buildingsLayer: AGSArcGISSceneLayer
    
    required init?(coder: NSCoder) {
        scene = AGSScene(basemap: .imagery())
        
        // Create a surface set it as the base surface of the scene.
        let surface = AGSSurface()
        surface.elevationSources = [AGSArcGISTiledElevationSource(url: .worldElevationService)]
        scene.baseSurface = surface
        
        buildingsLayer = AGSArcGISSceneLayer(url: .brestBuildingsService)
        scene.operationalLayers.add(buildingsLayer)
        
        super.init(coder: coder)
        
        buildingsLayer.load { [weak self] (error) in
            if let error = error {
                self?.layerDidFailToLoad(with: error)
            } else {
                self?.layerDidLoad()
            }
        }
    }
    
    /// The scene view managed by the view controller.
    @IBOutlet weak var sceneView: AGSSceneView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Assign the scene to the scene view.
        sceneView.scene = scene
        
        let camera = AGSCamera(latitude: 48.378, longitude: -4.494, altitude: 200, heading: 345, pitch: 65, roll: 0)
        sceneView.setViewpointCamera(camera)
    }
    
    /// Called in response to the layer loading successfully.
    func layerDidLoad() {
        sceneView.touchDelegate = self
    }
    
    /// Called in response to the layer failing to load. Presents an alert
    /// announcing the failure.
    ///
    /// - Parameter error: The error that caused loading to fail.
    func layerDidFailToLoad(with error: Error) {
        guard let window = view.window else { return }
        let alert = NSAlert()
        alert.messageText = "Failed to load the layer."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: window)
    }
}

extension SceneLayerSelectionViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        buildingsLayer.clearSelection()
        sceneView.identifyLayer(buildingsLayer, screenPoint: screenPoint, tolerance: 10, returnPopupsOnly: false) { [weak self] (result) in
            if let error = result.error {
                print("\(result.layerContent.name) identify failed: \(error)")
            } else {
                guard let feature = result.geoElements.first as? AGSFeature else { return }
                self?.buildingsLayer.select(feature)
            }
        }
    }
}
