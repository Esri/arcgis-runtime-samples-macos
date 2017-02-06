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

class RGBRendererViewController: NSViewController {

    @IBOutlet var mapView:AGSMapView!
    @IBOutlet var stretchType:NSPopUpButton!
    @IBOutlet var label1:NSTextField!
    @IBOutlet var label2:NSTextField!
    @IBOutlet var textField1a:NSTextField!
    @IBOutlet var textField1b:NSTextField!
    @IBOutlet var textField1c:NSTextField!
    @IBOutlet var textField2a:NSTextField!
    @IBOutlet var textField2b:NSTextField!
    @IBOutlet var textField2c:NSTextField!
    @IBOutlet var textField2TopConstraint:NSLayoutConstraint!
    @IBOutlet var textField2HeightConstraint:NSLayoutConstraint!
    
    private var raster: AGSRaster!
    private var rasterLayer: AGSRasterLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.raster = AGSRaster(name: "Shasta", extension: "tif")
        
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
    
    func toggleExtraTextFields(_ on:Bool) {
        self.textField1b.isHidden = !on
        self.textField1c.isHidden = !on
        self.textField2b.isHidden = !on
        self.textField2c.isHidden = !on
    }
    
    //MARK: - Actions
    
    @IBAction func popUpButtonAction(_ sender:NSPopUpButton) {
        switch sender.indexOfSelectedItem {
        case 0:
            self.label1.stringValue = "Min value"
            self.label2.stringValue = "Max value"
            self.textField1a.stringValue = "0"
            self.textField1b.stringValue = "0"
            self.textField1c.stringValue = "0"
            self.textField2a.stringValue = "255"
            self.textField2b.stringValue = "255"
            self.textField2c.stringValue = "255"
            self.toggleExtraTextFields(true)
            self.expandView()
        case 1:
            self.label1.stringValue = "Min"
            self.label2.stringValue = "Max"
            self.textField1a.stringValue = "0"
            self.textField2a.stringValue = "0"
            self.toggleExtraTextFields(false)
            self.expandView()
        default:
            self.label1.stringValue = "Factor"
            self.textField1a.stringValue = "1"
            self.toggleExtraTextFields(false)
            self.shrinkView()
        }
    }
    
    @IBAction func applyAction(_ sender:NSButton) {
        var stretchParams:AGSStretchParameters
    
        switch self.stretchType.indexOfSelectedItem {
        case 0:
            let minValues = [self.textField1a.integerValue, self.textField1b.integerValue, self.textField1c.integerValue]
            let maxValues = [self.textField2a.integerValue, self.textField2b.integerValue, self.textField2c.integerValue]
            stretchParams = AGSMinMaxStretchParameters(minValues: minValues as [NSNumber], maxValues: maxValues as [NSNumber])
        case 1:
            let min = self.textField1a.doubleValue
            let max = self.textField2a.doubleValue
            stretchParams = AGSPercentClipStretchParameters(min: min, max: max)
        default:
            let factor = self.textField1a.doubleValue
            stretchParams = AGSStandardDeviationStretchParameters(factor: factor)
        }
        
        let renderer = AGSRGBRenderer(stretchParameters: stretchParams, bandIndexes: [], gammas: [], estimateStatistics: true)
        self.rasterLayer.renderer = renderer
    }
}
