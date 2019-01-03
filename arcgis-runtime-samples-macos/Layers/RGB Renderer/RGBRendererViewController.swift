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

class RGBRendererViewController: NSViewController {
    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var stretchTypePopUp: NSPopUpButton!
    @IBOutlet var label1: NSTextField!
    @IBOutlet var label2: NSTextField!
    @IBOutlet var textField1a: NSTextField!
    @IBOutlet var textField1b: NSTextField!
    @IBOutlet var textField1c: NSTextField!
    @IBOutlet var textField2a: NSTextField!
    @IBOutlet var textField2b: NSTextField!
    @IBOutlet var textField2c: NSTextField!
    @IBOutlet var textField2TopConstraint: NSLayoutConstraint!
    @IBOutlet var textField2HeightConstraint: NSLayoutConstraint!
    
    private var rasterLayer: AGSRasterLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let raster = AGSRaster(name: "Shasta", extension: "tif")
        
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
    
    private func setExtraTextFieldsVisibility(visible: Bool) {
        textField1b.isHidden = !visible
        textField1c.isHidden = !visible
        textField2b.isHidden = !visible
        textField2c.isHidden = !visible
    }
    
    private func updateRenderer() {
        let stretchParameters: AGSStretchParameters = {
            switch stretchTypePopUp.indexOfSelectedItem {
            case 0:
                let minValues = [textField1a.integerValue, textField1b.integerValue, textField1c.integerValue]
                let maxValues = [textField2a.integerValue, textField2b.integerValue, textField2c.integerValue]
                return AGSMinMaxStretchParameters(minValues: minValues as [NSNumber], maxValues: maxValues as [NSNumber])
            case 1:
                let min = textField1a.doubleValue
                let max = textField2a.doubleValue
                return AGSPercentClipStretchParameters(min: min, max: max)
            default:
                let factor = textField1a.doubleValue
                return AGSStandardDeviationStretchParameters(factor: factor)
            }
        }()
        
        let renderer = AGSRGBRenderer(
            stretchParameters: stretchParameters,
            bandIndexes: [],
            gammas: [],
            estimateStatistics: true
        )
        rasterLayer?.renderer = renderer
    }
    
    // MARK: - Actions
    
    @IBAction func popUpButtonAction(_ sender: NSPopUpButton) {
        switch sender.indexOfSelectedItem {
        case 0:
            label1.stringValue = "Min Value"
            label2.stringValue = "Max Value"
            textField1a.stringValue = "0"
            textField1b.stringValue = "0"
            textField1c.stringValue = "0"
            textField2a.stringValue = "255"
            textField2b.stringValue = "255"
            textField2c.stringValue = "255"
            setExtraTextFieldsVisibility(visible: true)
            expandView()
        case 1:
            label1.stringValue = "Min"
            label2.stringValue = "Max"
            textField1a.stringValue = "0"
            textField2a.stringValue = "0"
            setExtraTextFieldsVisibility(visible: false)
            expandView()
        default:
            label1.stringValue = "Factor"
            textField1a.stringValue = "1"
            setExtraTextFieldsVisibility(visible: false)
            shrinkView()
        }
        updateRenderer()
    }
    
    @IBAction func textFieldAction(_ sender: NSTextField) {
        updateRenderer()
    }
}
