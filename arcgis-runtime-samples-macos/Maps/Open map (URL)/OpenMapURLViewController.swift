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

class OpenMapURLViewController: NSViewController {
    let maps = [
        MapAtURL(title: "Housing with Mortgages", image: #imageLiteral(resourceName: "OpenExistingMapThumbnail1"), url: URL(string: "https://www.arcgis.com/home/item.html?id=2d6fa24b357d427f9c737774e7b0f977")!),
        MapAtURL(title: "USA Tapestry Segmentation", image: #imageLiteral(resourceName: "OpenExistingMapThumbnail2"), url: URL(string: "https://www.arcgis.com/home/item.html?id=01f052c8995e4b9e889d73c3e210ebe3")!),
        MapAtURL(title: "Geology of United States", image: #imageLiteral(resourceName: "OpenExistingMapThumbnail3"), url: URL(string: "https://www.arcgis.com/home/item.html?id=92ad152b9da94dee89b9e387dfe21acd")!)
    ]
    
    @IBOutlet private weak var mapView: AGSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.map = AGSMap(url: maps.first!.url)
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        switch segue.destinationController {
        case let listViewController as MapURLListViewController:
            listViewController.maps = maps
            listViewController.delegate = self
        default:
            break
        }
    }
}

extension OpenMapURLViewController: MapURLListViewControllerDelegate {
    func mapURLListViewController(_: MapURLListViewController, didSelectItemAt index: Int) {
        let map = maps[index]
        mapView.map = AGSMap(url: map.url)
    }
}