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

class MapLoadedViewController: NSViewController {
    /// The map displayed in the map view.
    let map = AGSMap(basemap: .imageryWithLabels())
    private var loadStatusObservation: NSKeyValueObservation?
    
    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var bannerLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Assign map to map view.
        mapView.map = map
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        // The sample uses Key-Value Observing to register and receive
        // observations on the loadStatus property of the AGSMap. The banner
        // label will be updated everytime the status changes.
        
        // Register as an observer for loadStatus property on map.
        loadStatusObservation = map.observe(\.loadStatus, options: .initial) { [weak self] (_, _) in
            // Update the banner label on main thread.
            DispatchQueue.main.async { self?.updateBannerLabel() }
        }
    }
    
    func updateBannerLabel() {
        guard isViewLoaded else { return }
        bannerLabel.stringValue = "Load status: \(map.loadStatus.title)"
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        loadStatusObservation = nil
    }
}

extension AGSLoadStatus {
    /// The human readable name of the load status.
    var title: String {
        switch self {
        case .loaded:
            return "Loaded"
        case .loading:
            return "Loading"
        case .failedToLoad:
            return "Failed to Load"
        case .notLoaded:
            return "Not Loaded"
        case .unknown:
            return "Unknown"
        }
    }
}
