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

class ChangeBasemapViewController: NSViewController {

    @IBOutlet private weak var mapView:AGSMapView!
    @IBOutlet private weak var segmentedControl:NSSegmentedControl!
    
    var map:AGSMap!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize the map with topographic basemap
        self.map = AGSMap(basemap: AGSBasemap.topographicBasemap())
        
        //assign the map to the map view
        self.mapView.map = map
        
    }
    
    @IBAction func segmentValueChanged(sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0:
            self.map.basemap = AGSBasemap.topographicBasemap()
        case 1:
            self.map.basemap = AGSBasemap.streetsBasemap()
        case 2:
            self.map.basemap = AGSBasemap.imageryBasemap()
        default:
            self.map.basemap = AGSBasemap.oceansBasemap()
        }
    }
    
}
