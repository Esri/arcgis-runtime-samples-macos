//
// Copyright 2017 Esri.
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

class HillshadeRendererVC: NSViewController {

    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var altitudeSlider: NSSlider!
    @IBOutlet var azimuthSlider: NSSlider!
    @IBOutlet var altitudeLabel: NSTextField!
    @IBOutlet var azimuthLabel: NSTextField!
    @IBOutlet var slopeTypePopUp: NSPopUpButton!
    
    private var rasterLayer: AGSRasterLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        //raster layer
        let raster = AGSRaster(name: "srtm", extension: "tiff")
        let rasterLayer = AGSRasterLayer(raster: raster)
        self.rasterLayer = rasterLayer
        
        //initial map with raster layer as basemap
        let map = AGSMap(basemap: AGSBasemap(baseLayer: rasterLayer))
        
        //assign map to map view
        mapView.map = map
        
        //initial renderer
        let renderer = AGSHillshadeRenderer(altitude: 45, azimuth: 315, zFactor: 0.000016, slopeType: .none, pixelSizeFactor: 1, pixelSizePower: 1, outputBitDepth: 8)
        rasterLayer.renderer = renderer
    }
    
    private func selectedSlope() -> AGSSlopeType {
        switch slopeTypePopUp.indexOfSelectedItem {
        case 0:
            return .none
        case 1:
            return .degree
        case 2:
            return .percentRise
        default:
            return .scaled
        }
    }
    
    private func updateRenderer() {
        
        let altitude = altitudeSlider.doubleValue
        let azimuth = azimuthSlider.doubleValue
        let slopeType = selectedSlope()
        
        //initialize hill shade renderer with provided settings
        let renderer = AGSHillshadeRenderer(
            altitude: altitude,
            azimuth: azimuth,
            zFactor: 0.000016,
            slopeType: slopeType,
            pixelSizeFactor: 1,
            pixelSizePower: 1,
            outputBitDepth: 8
        )
        
        //assign renderer to raster layer
        rasterLayer?.renderer = renderer
    }
    
    // MARK: - Actions
    
    @IBAction func slopeTypePopUpAction(_ sender: NSPopUpButton) {
        updateRenderer()
    }
    
    @IBAction func altitudeSliderAction(_ sender: NSSlider) {
        altitudeLabel.stringValue = "\(sender.integerValue)"
        updateRenderer()
    }
    
    @IBAction func azimuthSliderAction(_ sender: NSSlider) {
        azimuthLabel.stringValue = "\(sender.integerValue)"
        updateRenderer()
    }
}
