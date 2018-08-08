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

/// A view controller that manages the interface of the Distance Measurement
/// Analysis sample.
class DistanceMeasurementAnalysisViewController: NSViewController, AGSGeoViewTouchDelegate {
    /// The scene displayed in the scene view.
    let scene: AGSScene
    /// The location distance measurement analysis.
    let locationDistanceMeasurement: AGSLocationDistanceMeasurement
    
    /// The scene view managed by the view controller.
    @IBOutlet weak var sceneView: AGSSceneView!
    
    required init?(coder: NSCoder) {
        // Create the scene.
        scene = AGSScene(basemap: .imagery())
        
        // Create the surface and set it as the base surface of the scene.
        let elevationSources = [
            AGSArcGISTiledElevationSource(url: .worldElevationService),
            AGSArcGISTiledElevationSource(url: .brestElevationService)
        ]
        let surface = AGSSurface()
        surface.elevationSources.append(contentsOf: elevationSources)
        scene.baseSurface = surface
        
        // Create the building layer and add it to the scene.
        let buildingsLayer = AGSArcGISSceneLayer(url: .brestBuildingsService)
        scene.operationalLayers.add(buildingsLayer)
        
        // Create the location distance measurement.
        let startPoint = AGSPoint(x: -4.494677, y: 48.384472, z: 24.772694, spatialReference: .wgs84())
        let endPoint = AGSPoint(x: -4.495646, y: 48.384377, z: 58.501115, spatialReference: .wgs84())
        locationDistanceMeasurement = AGSLocationDistanceMeasurement(startLocation: startPoint, endLocation: endPoint)
        
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the scene view.
        sceneView.scene = scene
        sceneView.touchDelegate = self
        let lookAtPoint = AGSEnvelope(min: locationDistanceMeasurement.startLocation, max: locationDistanceMeasurement.endLocation).center
        let camera = AGSCamera(lookAt: lookAtPoint, distance: 200, heading: 0, pitch: 45, roll: 0)
        sceneView.setViewpointCamera(camera)
        
        // Create the analysis overlay with the location distance measurement
        // analysis and add it to the scene view.
        let analysisOverlay = AGSAnalysisOverlay()
        analysisOverlay.analyses.add(locationDistanceMeasurement)
        sceneView.analysisOverlays.add(analysisOverlay)
    }
    
    // MARK: AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTouchDownAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint, completion: @escaping (Bool) -> Void) {
        sceneView.screen(toLocation: screenPoint) { [weak self] mapLocation in
            guard let `self` = self else { return }
            let isTrackingCursorMovement = self.sceneView.trackCursorMovement
            if !isTrackingCursorMovement {
                self.locationDistanceMeasurement.startLocation = mapLocation
            }
            self.locationDistanceMeasurement.endLocation = mapLocation
            self.sceneView.trackCursorMovement = !isTrackingCursorMovement
        }
    }
    
    func geoView(_ geoView: AGSGeoView, didMoveCursorToScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        sceneView.screen(toLocation: screenPoint) { [weak self] mapLocation in
            guard let `self` = self, self.sceneView.trackCursorMovement else { return }
            self.locationDistanceMeasurement.endLocation = mapLocation
        }
    }
    
    // MARK: NSViewController
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibName:bundle:) has not been implemented")
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        performSegue(withIdentifier: .init("showDistancePanel"), sender: self)
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        if let windowController = distanceWindowController {
            windowController.close()
            distanceWindowController = nil
        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let windowController = segue.destinationController as? NSWindowController,
            let distanceViewController = windowController.contentViewController as? DistanceViewController else {
                preconditionFailure()
        }
        distanceViewController.locationDistanceMeasurement = locationDistanceMeasurement
        distanceWindowController = windowController
    }
    
    /// The controller of the distance panel.
    var distanceWindowController: NSWindowController?
}
