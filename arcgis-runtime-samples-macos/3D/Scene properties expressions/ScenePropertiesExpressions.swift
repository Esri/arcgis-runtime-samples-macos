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

import Cocoa
import ArcGIS

class ScenePropertiesExpressions: NSViewController {

    @IBOutlet var sceneView: AGSSceneView!
    @IBOutlet var headingLabel: NSTextField!
    @IBOutlet var pitchLabel: NSTextField!
    
    private var coneGraphic: AGSGraphic!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize scene with topographic basemap
        let scene = AGSScene(basemap: AGSBasemap.streetsBasemap())
        //assign scene to the scene view
        self.sceneView.scene = scene
        
        //set the viewpoint camera
        let point = AGSPoint(x: 83.9, y: 28.4, z: 6200, spatialReference: AGSSpatialReference.WGS84())
        let camera = AGSCamera(lookAtPoint: point, distance: 1000, heading: 0, pitch: 50, roll: 0)
        self.sceneView.setViewpointCamera(camera)
        
        //create a graphics overlay
        let graphicsOverlay = AGSGraphicsOverlay()
        graphicsOverlay.sceneProperties?.surfacePlacement = .Relative
        
        //add it to the scene view
        self.sceneView.graphicsOverlays.addObject(graphicsOverlay)
        
        //add renderer using rotation expressions
        let renderer = AGSSimpleRenderer()
        renderer.sceneProperties?.headingExpression = "[HEADING]"
        renderer.sceneProperties?.pitchExpression = "[PITCH]"
        graphicsOverlay.renderer = renderer
        
        //create a red cone graphic
        let coneSymbol = AGSSimpleMarkerSceneSymbol(style: .Cone, color: NSColor.redColor(), height: 200, width: 100, depth: 100, anchorPosition: .Center)
        coneSymbol.pitch = 90  //correct symbol's default pitch
        let conePoint = AGSPoint(x: 83.9, y: 28.404, z: 6000, spatialReference: AGSSpatialReference.WGS84())
        let coneAttributes = ["HEADING": 0, "PITCH": 0]
        self.coneGraphic = AGSGraphic(geometry: conePoint, symbol: coneSymbol, attributes: coneAttributes)
        graphicsOverlay.graphics.addObject(self.coneGraphic)
    }
    
    @IBAction func headingSliderValueChanged(slider: NSSlider) {
        coneGraphic.attributes["HEADING"] = slider.doubleValue
        //update label
        self.headingLabel.stringValue = "\(slider.intValue)"
    }
    
    @IBAction func pitchSliderValueChanged(slider: NSSlider) {
        coneGraphic.attributes["PITCH"] = slider.doubleValue
        //update label
        self.pitchLabel.stringValue = "\(slider.intValue)"
    }
}
