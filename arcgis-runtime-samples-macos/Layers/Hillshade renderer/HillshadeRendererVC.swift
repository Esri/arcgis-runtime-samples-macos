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

import Cocoa
import ArcGIS

class HillshadeRendererVC: NSViewController {

    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var altitudeSlider: NSSlider!
    @IBOutlet var azimuthSlider: NSSlider!
    @IBOutlet var altitudeLabel: NSTextField!
    @IBOutlet var azimuthLabel: NSTextField!
    @IBOutlet var slopeType: NSPopUpButton!
    
    private var map: AGSMap!
    private var rasterLayer: AGSRasterLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        //raster layer
        let raster = AGSRaster(name: "srtm", extension: "tiff")
        self.rasterLayer = AGSRasterLayer(raster: raster)
        
        //initial map with raster layer as basemap
        self.map = AGSMap(basemap: AGSBasemap(baseLayer: self.rasterLayer))
        
        //assign map to map view
        self.mapView.map = self.map
        
        //initial renderer
        let renderer = AGSHillshadeRenderer(altitude: 45, azimuth: 315, zFactor: 0.000016, slopeType: .none, pixelSizeFactor: 1, pixelSizePower: 1, outputBitDepth: 8)
        rasterLayer.renderer = renderer
    }
    
    func selectedSlope() -> AGSSlopeType {
        switch self.slopeType.indexOfSelectedItem {
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
    
    func applyRenderer(withAltitude altitude: Double, azimuth: Double, slopeType: AGSSlopeType) {
        //initialize hill shade renderer with provided settings
        let renderer = AGSHillshadeRenderer(altitude: altitude, azimuth: azimuth, zFactor: 0.000016, slopeType: slopeType, pixelSizeFactor: 1, pixelSizePower: 1, outputBitDepth: 8)
        
        //assign renderer to raster layer
        self.rasterLayer.renderer = renderer
    }
    
    //MARK: - Actions
    
    @IBAction func applyAction(_ sender: NSButton) {
        let altitude = self.altitudeSlider.doubleValue
        let azimuth = self.azimuthSlider.doubleValue
        
        self.applyRenderer(withAltitude: altitude, azimuth: azimuth, slopeType: self.selectedSlope())
    }
    
    @IBAction func altitudeSliderAction(_ sender: NSSlider) {
        self.altitudeLabel.stringValue = "\(sender.integerValue)"
    }
    
    @IBAction func azimuthSliderAction(_ sender: NSSlider) {
        self.azimuthLabel.stringValue = "\(sender.integerValue)"
    }
}
