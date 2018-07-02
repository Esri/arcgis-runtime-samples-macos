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

class DrawingStatusViewController: NSViewController {

    @IBOutlet private var mapView:AGSMapView!
    @IBOutlet private var activityIndicatorView:NSView!
    @IBOutlet private var progressIndicator:NSProgressIndicator!
    
    private var map:AGSMap!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //instantiate the map with topographic basemap
        self.map = AGSMap(basemap: AGSBasemap.topographic())
        
        self.progressIndicator.startAnimation(self)
        
        //initial viewpoint
        self.map.initialViewpoint = AGSViewpoint(targetExtent: AGSEnvelope(xMin: -13639984, yMin: 4537387, xMax: -13606734, yMax: 4558866, spatialReference: AGSSpatialReference.webMercator()))
        
        //add a feature layer
        let featureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0")!)
        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
        self.map.operationalLayers.add(featureLayer)
        
        //assign the map to mapView
        self.mapView.map = self.map
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        mapView.addObserver(self, forKeyPath: #keyPath(AGSGeoView.drawStatus), options: .initial, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.activityIndicatorView.isHidden = strongSelf.mapView.drawStatus == .completed
        }
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        
        mapView.removeObserver(self, forKeyPath: #keyPath(AGSGeoView.drawStatus))
    }
}
