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

class StretchRendererViewController: NSViewController {
    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var stretchTypePopUp: NSPopUpButton!
    @IBOutlet var label1: NSTextField!
    @IBOutlet var label2: NSTextField!
    @IBOutlet var textField1: NSTextField!
    @IBOutlet var textField2: NSTextField!
    @IBOutlet var textField2TopConstraint: NSLayoutConstraint!
    @IBOutlet var textField2HeightConstraint: NSLayoutConstraint!
    
    private var rasterLayer: AGSRasterLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let raster = AGSRaster(name: "ShastaBW", extension: "tif")
        
        let rasterLayer = AGSRasterLayer(raster: raster)
        self.rasterLayer = rasterLayer
        
        let map = AGSMap(basemap: AGSBasemap(baseLayer: rasterLayer))
        mapView.map = map
    }
    
    private func expandView() {
        textField2TopConstraint.constant = 12
        textField2HeightConstraint.constant = 22
        label2.isHidden = false
    }
    
    private func shrinkView() {
        textField2TopConstraint.constant = 0
        textField2HeightConstraint.constant = 0
        label2.isHidden = true
    }
    
    private func updateRenderer() {
        let stretchParameters: AGSStretchParameters = {
            switch stretchTypePopUp.indexOfSelectedItem {
            case 0:
                let minValue = textField1.integerValue
                let maxValue = textField2.integerValue
                return AGSMinMaxStretchParameters(minValues: [NSNumber(value: minValue)], maxValues: [NSNumber(value: maxValue)])
            case 1:
                let min = textField1.doubleValue
                let max = textField2.doubleValue
                return AGSPercentClipStretchParameters(min: min, max: max)
            default:
                let factor = textField1.doubleValue
                return AGSStandardDeviationStretchParameters(factor: factor)
            }
        }()
        
        let renderer = AGSStretchRenderer(
            stretchParameters: stretchParameters,
            gammas: [],
            estimateStatistics: true,
            colorRamp: AGSColorRamp(type: .demLight, size: 1000)
        )
        rasterLayer?.renderer = renderer
    }
    
    // MARK: - Actions
    
    @IBAction func popUpButtonAction(_ sender: NSPopUpButton) {
        switch sender.indexOfSelectedItem {
        case 0:
            label1.stringValue = "Min Value"
            label2.stringValue = "Max Value"
            textField1.stringValue = "0"
            textField2.stringValue = "255"
            expandView()
        case 1:
            label1.stringValue = "Min"
            label2.stringValue = "Max"
            textField1.stringValue = "0"
            textField2.stringValue = "0"
            expandView()
        default:
            label1.stringValue = "Factor"
            textField1.stringValue = "1"
            shrinkView()
        }
        updateRenderer()
    }
    
    @IBAction func textFieldAction(_ sender: NSTextField) {
        updateRenderer()
    }
}
