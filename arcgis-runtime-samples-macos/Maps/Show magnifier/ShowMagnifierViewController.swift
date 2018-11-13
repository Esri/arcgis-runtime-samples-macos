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

class ShowMagnifierViewController: NSViewController {

    @IBOutlet private weak var mapView: AGSMapView!
    
    private var map: AGSMap!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //instantiate map with topographic basemap
        self.map = AGSMap(basemap: .imagery())
        
        //asssign map to the map view
        self.mapView.map = self.map
        
        //enable magnifier
        self.mapView.interactionOptions.isMagnifierEnabled = true
        
        //zoom to custom viewpoint
        let viewpoint = AGSViewpoint(center: AGSPoint(x: -110.8258, y: 32.1545089, spatialReference: AGSSpatialReference.wgs84()), scale: 5e3)
        self.mapView.setViewpoint(viewpoint)
    }
}
