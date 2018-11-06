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

class DisplayDeviceLocationViewController: NSViewController {
    
    @IBOutlet var mapView:AGSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// The map to display in the map view.
        let map = AGSMap(basemap: .imagery())
        
        // assign the map to map view
        mapView.map = map
    }

    @IBAction func showLocationButtonAction(_ sender: NSButton) {
        
        let isChecked = sender.state == .on
        
        // don't start or stop the location display if it's already started or stopped
        guard mapView.locationDisplay.started != isChecked else {
            return
        }
        
        if isChecked {
            // attempt to start showing the device location
            mapView.locationDisplay.start {[weak self] (error) in
                if let error = error,
                    let window = self?.view.window {
                    // show the error if one occurred
                    NSAlert(error: error).beginSheetModal(for: window)
                }
            }
        }
        else {
            // stop showing the device location
            mapView.locationDisplay.stop()
        }
    }
    
    @IBAction func autoPanModePopupAction(_ sender: NSPopUpButton) {
        // get the mode for the index
        if let autoPanMode = AGSLocationDisplayAutoPanMode(rawValue: sender.indexOfSelectedItem) {
            // set the displayed location mode to the selected one
            mapView.locationDisplay.autoPanMode = autoPanMode
        }
    }
}
