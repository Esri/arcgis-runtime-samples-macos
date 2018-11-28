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

class BlendRendererViewController: NSViewController {

    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var altitudeSlider: NSSlider!
    @IBOutlet var azimuthSlider: NSSlider!
    @IBOutlet var altitudeLabel: NSTextField!
    @IBOutlet var azimuthLabel: NSTextField!
    @IBOutlet var slopeTypePopUp: NSPopUpButton!
    @IBOutlet var colorRampPopUp: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //create a raster
        let raster = AGSRaster(name: "Shasta", extension: "tif")
        
        //create raster layer using raster
        let rasterLayer = AGSRasterLayer(raster: raster)
        
        //initialize map with raster layer as the basemap
        let map = AGSMap(basemap: AGSBasemap(baseLayer: rasterLayer))
        
        //assign map to the map view
        mapView.map = map
    }
    
    private func generateBlendRenderer(withAltitude altitude: Double, azimuth: Double, slopeType: AGSSlopeType, colorRampType: AGSPresetColorRampType) -> AGSBlendRenderer {
        
        //create the raster to be used as elevation raster
        let raster = AGSRaster(name: "Shasta_Elevation", extension: "tif")
        
        //create a colorRamp object from the type specified
        let colorRamp = AGSColorRamp(type: colorRampType, size: 800)
        
        //create a blend renderer
        let renderer = AGSBlendRenderer(elevationRaster: raster, outputMinValues: [9], outputMaxValues: [255], sourceMinValues: [], sourceMaxValues: [], noDataValues: [], gammas: [], colorRamp: colorRamp, altitude: altitude, azimuth: azimuth, zFactor: 1, slopeType: slopeType, pixelSizeFactor: 1, pixelSizePower: 1, outputBitDepth: 8)
        
        return renderer
    }
    
    func selectedSlope() -> AGSSlopeType {
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
    
    func selectedColorRamp() -> AGSPresetColorRampType {
        switch colorRampPopUp.indexOfSelectedItem {
        case 0:
            return .none
        case 1:
            return .elevation
        case 2:
            return .demLight
        default:
            return .demScreen
        }
    }
    
    private func updateRenderer() {
        
        let altitude = altitudeSlider.doubleValue
        let azimuth = azimuthSlider.doubleValue
        
        let slopeType = selectedSlope()
        let colorRampType = selectedColorRamp()
        
        //get the blend render for the specified settings
        let blendRenderer = generateBlendRenderer(withAltitude: altitude, azimuth: azimuth, slopeType: slopeType, colorRampType: colorRampType)
        
        //if the colorRamp type is None, then use the Shasta.tif for blending.
        //else use the elevation raster with color ramp
        let baseRaster: AGSRaster
        if colorRampType == .none {
            baseRaster = AGSRaster(name: "Shasta", extension: "tif")
        } else {
            baseRaster = AGSRaster(name: "Shasta_Elevation", extension: "tif")
        }
        
        //create a raster layer with the new raster
        let rasterLayer = AGSRasterLayer(raster: baseRaster)
        
        //apply the blend renderer on this new raster layer
        rasterLayer.renderer = blendRenderer
        
        //add the raster layer as the basemap
        mapView.map?.basemap = AGSBasemap(baseLayer: rasterLayer)
    }
    
    // MARK: - Actions
    
    @IBAction func popUpAction(_ sender: NSPopUpButton) {
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
