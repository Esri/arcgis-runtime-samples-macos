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

/// A view controller that manages a grid view which displays the view state of
/// the layers of a map view.
class LayerViewStatusViewController: NSViewController {
    @IBOutlet weak var worldTimeZonesStatusLabel: NSTextField!
    @IBOutlet weak var censusStatusLabel: NSTextField!
    @IBOutlet weak var facilitiesStatusLabel: NSTextField!
    
    var labels: [NSTextField] {
        return [worldTimeZonesStatusLabel, censusStatusLabel, facilitiesStatusLabel]
    }
    
    /// The map view whose layers should be observed for view state changes.
    var mapView: AGSMapView? {
        didSet {
            updateLabels()
            mapView?.layerViewStateChangedHandler = { [weak self] (layer, viewState) in
                DispatchQueue.main.async {
                    guard let self = self, let index = self.mapView?.map?.operationalLayers.index(of: layer) else { return }
                    self.labels[index].stringValue = viewState.status.title
                }
            }
        }
    }
    
    func updateLabels() {
        guard isViewLoaded,
            let mapView = mapView,
            let layers = mapView.map?.operationalLayers as? [AGSLayer] else {
            return
        }
        zip(labels, layers).forEach { (label, layer) in
            guard let state = mapView.layerViewState(for: layer) else { return }
            label.stringValue = state.status.title
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        updateLabels()
    }
}

private extension AGSLayerViewStatus {
    /// The human readable name of the load status.
    var title: String {
        switch self {
        case .active:
            return "Active"
        case .notVisible:
            return "Not Visible"
        case .outOfScale:
            return "Out of Scale"
        case .loading:
            return "Loading"
        case .error:
            return "Error"
        default:
            return "Unknown"
        }
    }
}
