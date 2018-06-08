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

private let defaultStartPoint = AGSPoint(x: -4.494677, y: 48.384472, z: 24.772694, spatialReference: .wgs84())
private let defaultEndPoint = AGSPoint(x: -4.495646, y: 48.384377, z: 58.501115, spatialReference: .wgs84())

class DistanceMeasurementAnalysisViewController: NSViewController {
    @IBOutlet weak var sceneView: AGSSceneView! {
        didSet {
            sceneView.touchDelegate = self
            sceneView.scene = scene
            sceneView.setViewpointCamera(AGSCamera(lookAt: defaultStartPoint, distance: 200, heading: 0, pitch: 45, roll: 0))
            sceneView.analysisOverlays.add(AGSAnalysisOverlay(analyses: [locationDistanceMeasurement]))
        }
    }
    
    let scene = AGSScene(basemap: .imagery())
    var locationDistanceMeasurement = AGSLocationDistanceMeasurement(startLocation: defaultStartPoint, endLocation: defaultEndPoint)
    
    var distanceWindowController: NSWindowController?
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibName:bundle:) has not been implemented")
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        let surface = AGSSurface(
            elevationSources: [
                AGSArcGISTiledElevationSource(url: .terrain3DService),
                AGSArcGISTiledElevationSource(url: URL(string: "https://tiles.arcgis.com/tiles/d3voDfTFbHOCRwVR/arcgis/rest/services/MNT_IDF/ImageServer")!)
            ]
        )
        let buildingsLayer = AGSArcGISSceneLayer(url: .brestBuildingsService)
        
        scene.baseSurface = surface
        scene.operationalLayers.add(buildingsLayer)
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
}

extension DistanceMeasurementAnalysisViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTouchDownAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint, completion: @escaping (Bool) -> Void) {
        sceneView.screen(toLocation: screenPoint) { [weak self] mapLocation in
            guard let measurement = self?.locationDistanceMeasurement else { return }
            if measurement.startLocation != measurement.endLocation {
                measurement.startLocation = mapLocation
                measurement.endLocation = mapLocation
            } else {
                measurement.endLocation = mapLocation
            }
        }
        completion(true)
    }
    
    func geoView(_ geoView: AGSGeoView, didTouchDragToScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        sceneView.screen(toLocation: screenPoint) { [weak self] mapLocation in
            guard let measurement = self?.locationDistanceMeasurement else { return }
            measurement.endLocation = mapLocation
        }
    }
}
