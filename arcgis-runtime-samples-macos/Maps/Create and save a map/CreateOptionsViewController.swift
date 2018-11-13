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

protocol CreateOptionsVCDelegate: AnyObject {
    func createOptionsViewController(_ createOptionsViewController: CreateOptionsViewController, didSelectBasemap basemap: AGSBasemap, layers: [AGSLayer]?)
}

class CreateOptionsViewController: NSViewController {
    
    private var selectedLayersIndexes = [Int]()
    private var selectedBasemapIndex: Int!
    
    private var basemaps: [AGSBasemap] = [.streets(), .imagery(), .topographic(), .oceans()]
    
    private var layers = [AGSLayer]()
    
    private var layerURLs = ["https://sampleserver5.arcgisonline.com/arcgis/rest/services/Elevation/WorldElevations/MapServer",
                             "https://sampleserver5.arcgisonline.com/arcgis/rest/services/Census/MapServer"]
 
    weak var delegate: CreateOptionsVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //populate layers array
        for urlString in self.layerURLs {
            let layer = AGSArcGISMapImageLayer(url: URL(string: urlString)!)
            self.layers.append(layer)
        }
    }
    
    @IBAction func radioAction(_ sender: NSButton) {
        self.selectedBasemapIndex = sender.tag
    }

    @IBAction func checkAction(_ sender: NSButton) {
        if sender.state == NSControl.StateValue.off {
            //remove from the array if already present
            if let index = self.selectedLayersIndexes.index(of: sender.tag) {
                self.selectedLayersIndexes.remove(at: index)
            }
        }
        else {
            self.selectedLayersIndexes.append(sender.tag)
        }
    }
    
    @IBAction func doneAction(_ sender: AnyObject) {
        //validation
        if self.selectedBasemapIndex == nil {
            self.showAlert(withText: "A basemap is required")
            return
        }
        
        //create a basemap with the selected basemap index
        let basemap = self.basemaps[self.selectedBasemapIndex].copy() as! AGSBasemap
        
        //create an array of the selected operational layers
        var layers = [AGSLayer]()
        for index in self.selectedLayersIndexes {
            let layer = self.layers[index].copy() as! AGSLayer
            layers.append(layer)
        }
        
        self.delegate?.createOptionsViewController(self, didSelectBasemap: basemap, layers: !layers.isEmpty ? layers : nil)
    }
    
    // MARK: - Helper methods
    
    private func showAlert(withText text: String) {
        let alert = NSAlert()
        alert.messageText = "Info"
        alert.informativeText = text
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: self.view.window!)
    }
}
