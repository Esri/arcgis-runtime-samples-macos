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
    @IBOutlet var stretchType: NSPopUpButton!
    @IBOutlet var label1: NSTextField!
    @IBOutlet var label2: NSTextField!
    @IBOutlet var textField1: NSTextField!
    @IBOutlet var textField2: NSTextField!
    @IBOutlet var textField2TopConstraint: NSLayoutConstraint!
    @IBOutlet var textField2HeightConstraint: NSLayoutConstraint!
    
    private var raster: AGSRaster!
    private var rasterLayer: AGSRasterLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.raster = AGSRaster(name: "ShastaBW", extension: "tif")
        
        self.rasterLayer = AGSRasterLayer(raster: self.raster)
        
        let map = AGSMap(basemap: AGSBasemap(baseLayer: self.rasterLayer))
        
        self.mapView.map = map
    }
    
    func expandView() {
        self.textField2TopConstraint.constant = 12
        self.textField2HeightConstraint.constant = 22
        self.label2.isHidden = false
    }
    
    func shrinkView() {
        self.textField2TopConstraint.constant = 0
        self.textField2HeightConstraint.constant = 0
        self.label2.isHidden = true
    }
    
    //MARK: - Actions
    
    @IBAction func popUpButtonAction(_ sender: NSPopUpButton) {
        switch sender.indexOfSelectedItem {
        case 0:
            self.label1.stringValue = "Min value"
            self.label2.stringValue = "Max value"
            self.textField1.stringValue = "0"
            self.textField2.stringValue = "255"
            self.expandView()
        case 1:
            self.label1.stringValue = "Min"
            self.label2.stringValue = "Max"
            self.textField1.stringValue = "0"
            self.textField2.stringValue = "0"
            self.expandView()
        default:
            self.label1.stringValue = "Factor"
            self.textField1.stringValue = "1"
            self.shrinkView()
        }
    }
    
    @IBAction func applyAction(_ sender: NSButton) {
        var stretchParams: AGSStretchParameters
        
        switch self.stretchType.indexOfSelectedItem {
        case 0:
            let minValue = self.textField1.integerValue
            let maxValue = self.textField2.integerValue
            stretchParams = AGSMinMaxStretchParameters(minValues: [NSNumber(value: minValue)], maxValues: [NSNumber(value: maxValue)])
        case 1:
            let min = self.textField1.doubleValue
            let max = self.textField2.doubleValue
            stretchParams = AGSPercentClipStretchParameters(min: min, max: max)
        default:
            let factor = self.textField1.doubleValue
            stretchParams = AGSStandardDeviationStretchParameters(factor: factor)
        }
        
        let renderer = AGSStretchRenderer(stretchParameters: stretchParams, gammas: [], estimateStatistics: true, colorRamp: AGSColorRamp(type: .demLight, size: 1000))
        self.rasterLayer.renderer = renderer
    }
    
}
