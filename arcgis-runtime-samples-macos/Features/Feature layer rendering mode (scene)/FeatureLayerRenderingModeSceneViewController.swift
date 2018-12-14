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

class FeatureLayerRenderingModeSceneViewController: NSViewController {

    /// The scene view that displays the static feature layers.
    @IBOutlet weak var staticSceneView: AGSSceneView!
    /// The scene view that displays the dynamic feature layers.
    @IBOutlet weak var dynamicSceneView: AGSSceneView!
    
    private let zoomedOutCamera = AGSCamera(lookAt: AGSPoint(x: -118.37, y: 34.46, spatialReference: .wgs84()), distance: 42000, heading: 0, pitch: 0, roll: 0)
    private let zoomedInCamera = AGSCamera(lookAt: AGSPoint(x: -118.45, y: 34.395, spatialReference: .wgs84()), distance: 2500, heading: 90, pitch: 75, roll: 0)
    
    /// The length of one animation, zooming in or out.
    private let animationDuration: TimeInterval = 5
    
    /// The flag indicating the zoom state of the views.
    private var zoomedIn = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set the initial viewpoint cameras with the zoomed out camera
        staticSceneView.setViewpointCamera(zoomedOutCamera)
        dynamicSceneView.setViewpointCamera(zoomedOutCamera)
           
        // register to receive touch events
        staticSceneView.touchDelegate = self
        dynamicSceneView.touchDelegate = self
        
        // load identical scenes for each view, differing the layer rendering mode
        staticSceneView.scene = makeScene(renderingMode: .static)
        dynamicSceneView.scene = makeScene(renderingMode: .dynamic)
    }
    
    private func makeScene(renderingMode: AGSFeatureRenderingMode) -> AGSScene {
        
        let scene = AGSScene()
        
        // create service feature tables using point, polygon, and polyline services
        let pointTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Energy/Geology/FeatureServer/0")!)
        let polylineTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Energy/Geology/FeatureServer/8")!)
        let polygonTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Energy/Geology/FeatureServer/9")!)
        
        // loop through all the tables in the order we want to add them, bottom to top
        for featureTable in [polygonTable, polylineTable, pointTable] {
            
            // create a feature layer for the table
            let featureLayer = AGSFeatureLayer(featureTable: featureTable)
            
            // set the rendering mode for the layer
            featureLayer.renderingMode = renderingMode
            
            // add the layer to the scene
            scene.operationalLayers.add(featureLayer)
        }
        
        return scene
    }
    
    @IBAction func animateZoomAction(_ sender: NSButton) {
        
        // disable the button during the animation
        sender.isEnabled = false
        
        /// The title for the bar button following the animation.
        let targetTitle = zoomedIn ? "Zoom In" : "Zoom Out"
        
        // toggle between the zoomed in and zoomed out cameras
        let targetCamera = zoomedIn ? zoomedOutCamera : zoomedInCamera
        
        // start the animation to the opposite viewpoint in both scenes
        dynamicSceneView.setViewpointCamera(targetCamera, duration: animationDuration)
        staticSceneView.setViewpointCamera(targetCamera, duration: animationDuration) { [weak self] _ in
            // we only need to run the completion handler for one view
            
            // update the title for the new state
            sender.title = targetTitle
            // re-enable the button
            sender.isEnabled = true
            // update the model
            self?.zoomedIn.toggle()
        }
    }

}

extension FeatureLayerRenderingModeSceneViewController: AGSGeoViewTouchDelegate {
    
    // In order to prevent the views from getting out of sync via user navigation,
    // we implement these two delegate methods and return true in their completion handlers.
    // This disables default interactions.
    
    func geoView(_ geoView: AGSGeoView, didTouchDownAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint, completion: @escaping (Bool) -> Void) {
        completion(true)
    }
    
    func geoView(_ geoView: AGSGeoView, didDoubleTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint, completion: @escaping (Bool) -> Void) {
        completion(true)
    }
    
}
