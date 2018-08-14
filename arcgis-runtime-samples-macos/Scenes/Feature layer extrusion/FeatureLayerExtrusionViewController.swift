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

/// A view controller that manages the interface of the Feature Layer Extrusion
/// sample.
class FeatureLayerExtrusionViewController: NSViewController {
    /// The scene displayed in the scene view.
    let scene: AGSScene
    /// The renderer of the feature layer.
    let renderer: AGSRenderer
    
    required init?(coder: NSCoder) {
        scene = AGSScene(basemapType: .topographic)
        
        // Create service feature table from US census feature service.
        let table = AGSServiceFeatureTable(url: .censusMapServiceStatesLayer)
        // Create feature layer from service feature table.
        let layer = AGSFeatureLayer(featureTable: table)
        // Feature layer must be rendered dynamically for extrusion to work.
        layer.renderingMode = .dynamic
        // Setup the symbols used to display the features (US states) from the table.
        let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: .blue, width: 1.0)
        let fillSymbol = AGSSimpleFillSymbol(style: .solid, color: .blue, outline: lineSymbol)
        renderer = AGSSimpleRenderer(symbol: fillSymbol)
        if let sceneProperties = renderer.sceneProperties {
            sceneProperties.extrusionMode = .absoluteHeight
            sceneProperties.extrusionExpression = Statistic.totalPopulation.extrusionExpression
        }
        
        // Set the renderer on the layer and add the layer to the scene.
        layer.renderer = renderer
        scene.operationalLayers.add(layer)
        
        super.init(coder: coder)
    }
    
    /// The scene view managed by the view controller.
    @IBOutlet weak var sceneView: AGSSceneView!
    /// The segmented control used to select the statistic that is extruded.
    @IBOutlet weak var extrusionControl: NSSegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView.scene = scene
        
        // Set the initial view.
        let initialLocation = AGSPoint(x: -98.585522, y: 70, spatialReference: sceneView.spatialReference)
        let orbitCamera = AGSOrbitLocationCameraController(targetLocation: initialLocation, distance: 15_000_000)
        orbitCamera.cameraPitchOffset = 75.0
        sceneView.cameraController = orbitCamera
    }
    
    enum Statistic: Int {
        case totalPopulation
        case populationDensity
        
        /// The extrusion expression for the statistic.
        var extrusionExpression: String {
            switch self {
            case .totalPopulation:
                return "[POP2007]/ 10"
            case .populationDensity:
                // The offset makes the extrusion look better over Alaska.
                let offset = 100_000
                return "([POP07_SQMI] * 5000) + \(offset)"
            }
        }
    }
    
    @IBAction func extrusionAction(_ sender: NSSegmentedControl) {
        if let statistic = Statistic(rawValue: sender.selectedSegment) {
            renderer.sceneProperties?.extrusionExpression = statistic.extrusionExpression
        } else {
            preconditionFailure()
        }
    }
}
