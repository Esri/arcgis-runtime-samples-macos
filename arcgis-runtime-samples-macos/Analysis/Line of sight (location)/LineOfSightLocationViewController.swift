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

import Cocoa
import ArcGIS

class LineOfSightLocationViewController: NSViewController, AGSGeoViewTouchDelegate {

    @IBOutlet weak var sceneView: AGSSceneView!
    @IBOutlet weak var observerInstructionLabel: NSTextField!
    @IBOutlet weak var targetInstructionLabel: NSTextField!

    private var lineOfSight: AGSLocationLineOfSight? {
        willSet {
            sceneView.analysisOverlays.removeAllObjects()
        }
        didSet {
            guard let lineOfSight = lineOfSight else {
                targetInstructionLabel.isHidden = true
                return
            }

            targetInstructionLabel.isHidden = false

            // create an analysis overlay using a single Line of Sight and add it to the scene view
            let analysisOverlay = AGSAnalysisOverlay()
            analysisOverlay.analyses.add(lineOfSight)
            sceneView.analysisOverlays.add(analysisOverlay)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // prepare the UI for first use
        targetInstructionLabel.isHidden = true
        
        // initialize the scene with an imagery basemap
        let scene = AGSScene(basemap: .imagery())

        // assign the scene to the scene view
        sceneView.scene = scene

        // initialize the elevation source with the service URL and add it to the base surface of the scene
        let elevationSrc = AGSArcGISTiledElevationSource(url: .worldElevationService)
        scene.baseSurface?.elevationSources.append(elevationSrc)

        // set the viewpoint specified by the camera position
        let camera = AGSCamera(location: AGSPoint(x: -73.0815, y: -49.3272, z: 4059, spatialReference: AGSSpatialReference.wgs84()), heading: 11, pitch: 62, roll: 0)
        sceneView.setViewpointCamera(camera)

        // set touch delegate on scene view as self
        sceneView.touchDelegate = self

        // set the line width (default 1.0). This setting is applied to all line of sight analysis in the view
        AGSLineOfSight.setLineWidth(2.0)
    }
    
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // user tapped to place Line of Sight observer. Create Line of Sight analysis if need be
        if (lineOfSight == nil) {
            // set initial Line of Sight analysis with tapped point
            lineOfSight = AGSLocationLineOfSight(observerLocation: mapPoint, targetLocation: mapPoint)
        } else {
            // update the observer location
            lineOfSight?.observerLocation = mapPoint
        }
        sceneView.trackCursorMovement = true
    }

    func geoView(_ geoView: AGSGeoView, didMoveCursorToScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // update the target location
        lineOfSight?.targetLocation = mapPoint
    }
}
