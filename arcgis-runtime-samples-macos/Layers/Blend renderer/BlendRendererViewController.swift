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

class BlendRendererViewController: NSViewController {

    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var altitudeSlider:NSSlider!
    @IBOutlet var azimuthSlider:NSSlider!
    @IBOutlet var altitudeLabel:NSTextField!
    @IBOutlet var azimuthLabel:NSTextField!
    @IBOutlet var slopeType:NSPopUpButton!
    @IBOutlet var colorramp:NSPopUpButton!
    
    private var map:AGSMap!
    
    private var rasterLayer: AGSRasterLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //create a raster
        let raster = AGSRaster(name: "Shasta", extension: "tif")
        
        //create raster layer using raster
        self.rasterLayer = AGSRasterLayer(raster: raster)
        
        //initialize map with raster layer as the basemap
        self.map = AGSMap(basemap: AGSBasemap(baseLayer: self.rasterLayer))
        
        //assign map to the map view
        self.mapView.map = self.map
    }
    
    private func generateBlendRenderer(_ altitude: Double, azimuth: Double, slopeType: AGSSlopeType, colorRampType: AGSPresetColorRampType) -> AGSBlendRenderer {
        
        //create the raster to be used as elevation raster
        let raster = AGSRaster(name: "Shasta_Elevation", extension: "tif")
        
        //create a colorRamp object from the type specified
        let colorRmp = AGSColorRamp(type: colorRampType, size: 800)
        
        //create a blend renderer
        let renderer = AGSBlendRenderer(elevationRaster: raster, outputMinValues: [9], outputMaxValues: [255], sourceMinValues: [], sourceMaxValues: [], noDataValues: [], gammas: [], colorRamp: colorRmp, altitude: altitude, azimuth: azimuth, zFactor: 1, slopeType: slopeType, pixelSizeFactor: 1, pixelSizePower: 1, outputBitDepth: 8)
        
        return renderer
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
    
    func selectedColorRamp() -> AGSPresetColorRampType {
        switch self.colorramp.indexOfSelectedItem {
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
    
    //MARK: -
    
    func applyRenderer(_ altitude: Double, azimuth: Double, slopeType: AGSSlopeType, colorRampType: AGSPresetColorRampType) {
        
        //get the blend render for the specified settings
        let blendRenderer = self.generateBlendRenderer(altitude, azimuth: azimuth, slopeType: slopeType, colorRampType: colorRampType)
        
        //if the colorRamp type is None, then use the Shasta.tif for blending.
        //else use the elevation raster with color ramp
        var baseRaster:AGSRaster
        if colorRampType == .none {
            baseRaster = AGSRaster(name: "Shasta", extension: "tif")
        }
        else {
            baseRaster = AGSRaster(name: "Shasta_Elevation", extension: "tif")
        }
        
        //create a raster layer with the new raster
        self.rasterLayer = AGSRasterLayer(raster: baseRaster)
        
        //add the raster layer as the basemap
        self.mapView.map?.basemap = AGSBasemap(baseLayer: self.rasterLayer)
        
        //apply the blend renderer on this new raster layer
        self.rasterLayer.renderer = blendRenderer
    }
    
    //MARK: - Actions
    
    @IBAction func applyAction(_ sender:NSButton) {
        let altitude = self.altitudeSlider.doubleValue
        let azimuth = self.azimuthSlider.doubleValue
        
        self.applyRenderer(altitude, azimuth: azimuth, slopeType: self.selectedSlope(), colorRampType: self.selectedColorRamp())
    }
    
    @IBAction func altitudeSliderAction(_ sender:NSSlider) {
        self.altitudeLabel.stringValue = "\(sender.integerValue)"
    }
    
    @IBAction func azimuthSliderAction(_ sender:NSSlider) {
        self.azimuthLabel.stringValue = "\(sender.integerValue)"
    }
}
