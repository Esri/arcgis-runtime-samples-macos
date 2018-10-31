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

class OpenMobileMapViewController: NSViewController {

    @IBOutlet private var mapView:AGSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize map package
        let mapPackage = AGSMobileMapPackage(name: "Yellowstone")
        
        //load map package
        mapPackage.load { [weak self] (error: Error?) in
            guard let self = self else {
                return
            }

            if let error = error {
                NSAlert(error: error).beginSheetModal(for: self.view.window!)
            }
            else if !mapPackage.maps.isEmpty {
                //assign the first map from the map package to the map view
                self.mapView.map = mapPackage.maps[0]
            }
            else {
                let alert = NSAlert()
                alert.messageText = "No mobile maps found in the map package."
                alert.beginSheetModal(for: self.view.window!)
            }
        }
    }
    
}
