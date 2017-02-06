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

class OpenExistingMapViewController: NSViewController, ExistingMapsListDelegate {

    @IBOutlet private weak var mapView:AGSMapView!
    
    private var existingMapsListVC:ExistingMapsListViewController!
    
    private let itemURL1 = "https://www.arcgis.com/home/item.html?id=2d6fa24b357d427f9c737774e7b0f977"
    private let itemURL2 = "https://www.arcgis.com/home/item.html?id=01f052c8995e4b9e889d73c3e210ebe3"
    private let itemURL3 = "https://www.arcgis.com/home/item.html?id=92ad152b9da94dee89b9e387dfe21acd"
    
    private var map:AGSMap!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.map = AGSMap(url: URL(string: itemURL1)!)
        
        self.mapView.map = self.map
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "OptionsSegue" {
            self.existingMapsListVC = segue.destinationController as! ExistingMapsListViewController
            self.existingMapsListVC.delegate = self
        }
    }
    
    //MARK: - ExistingMapsListDelegate
    
    func existingMapsListViewController(_: ExistingMapsListViewController, didSelectItemAtIndex index: Int) {
        var selectedPortalItemURL:String
        switch index {
        case 1:
            selectedPortalItemURL = self.itemURL2
        case 2:
            selectedPortalItemURL = self.itemURL3
        default:
            selectedPortalItemURL = self.itemURL1
        }
        self.map = AGSMap(url: URL(string: selectedPortalItemURL)!)
        self.mapView.map = self.map
    }
}
