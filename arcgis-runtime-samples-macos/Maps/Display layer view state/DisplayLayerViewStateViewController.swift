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

/// A view controller that manages the interface of the Display Layer View State
/// sample.
class DisplayLayerViewStateViewController: NSViewController /*, UITableViewDataSource, UITableViewDelegate */ {
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView!
    
    /// Creates a map with three operational layers: a tiled layer, an image
    /// layer, and a feature layer.
    func makeMap() -> AGSMap {
        let tiledLayer = AGSArcGISTiledLayer(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/WorldTimeZones/MapServer")!)
        
        let imageLayer = AGSArcGISMapImageLayer(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Census/MapServer")!)
        imageLayer.minScale = 40_000_000
        imageLayer.maxScale = 2_000_000
        
        let featureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Recreation/FeatureServer/0")!)
        let featurelayer = AGSFeatureLayer(featureTable: featureTable)
        
        let map = AGSMap()
        map.operationalLayers.addObjects(from: [tiledLayer, imageLayer, featurelayer])
        
        return map
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.map = makeMap()
        mapView.setViewpoint(AGSViewpoint(center: AGSPoint(x: -11_000_000, y: 4_500_000, spatialReference: .webMercator()), scale: 50_000_000))
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        performSegue(withIdentifier: "showLayerViewStatusPanel", sender: self)
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        if let windowController = presentedLayerViewStatusWindowController {
            windowController.close()
            presentedLayerViewStatusWindowController = nil
        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let windowController = segue.destinationController as? NSWindowController,
            let window = windowController.window,
            let layerViewStatusViewController = windowController.contentViewController as? LayerViewStatusViewController else {
                preconditionFailure()
        }
        let topRight = view.window!.convertToScreen(view.convert(view.bounds, to: nil))
        window.setFrameOrigin(NSPoint(x: topRight.maxX - window.frame.width - 32, y: topRight.maxY - window.frame.height - 16))
        layerViewStatusViewController.mapView = mapView
        presentedLayerViewStatusWindowController = windowController
    }
    
    var presentedLayerViewStatusWindowController: NSWindowController?
}
