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

class FeatureTemplateInfo {
    var featureType:AGSFeatureType!
    var featureTemplate:AGSFeatureTemplate!
    var featureLayer:AGSFeatureLayer!
}

protocol FeatureTemplatePickerVCDelegate:class {
    
    func featureTemplatePickerVC(_ featureTemplatePickerVC:FeatureTemplatePickerVC, didSelectFeatureTemplate template:AGSFeatureTemplate, forFeatureLayer featureLayer:AGSFeatureLayer)
    
    func featureTemplatePickerVCDidCancel(_ featureTemplatePickerVC:FeatureTemplatePickerVC)
}

class FeatureTemplatePickerVC: NSViewController {
    
    var infos = [FeatureTemplateInfo]()
    @IBOutlet weak var featureTemplateTableView: NSTableView!
    weak var delegate:FeatureTemplatePickerVCDelegate?
    var featureLayer: AGSFeatureLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.preferredContentSize = CGSize(width: 300, height: 300)
        self.addTemplatesFromLayer(self.featureLayer)
    }
    
    func addTemplatesFromLayer(_ featureLayer:AGSFeatureLayer) {
        
        let featureTable = featureLayer.featureTable as! AGSServiceFeatureTable
        //if layer contains only templates (no feature types)
        if featureTable.featureTemplates.count > 0 {
            //for each template
            for template in featureTable.featureTemplates {
                let info = FeatureTemplateInfo()
                info.featureLayer = featureLayer
                info.featureTemplate = template
                info.featureType = nil
                
                //add to array
                self.infos.append(info)
            }
        }
            //otherwise if layer contains feature types
        else  {
            //for each type
            for type in featureTable.featureTypes {
                //for each temple in type
                for template in type.templates {
                    let info = FeatureTemplateInfo()
                    info.featureLayer = featureLayer
                    info.featureTemplate = template
                    info.featureType = type
                    
                    //add to array
                    self.infos.append(info)
                }
            }
        }
    }
    
    @IBAction func cancelAction(_ sender: NSButton) {
        self.delegate?.featureTemplatePickerVCDidCancel(self)
    }
    
    //MARK: - NSTableViewDataSource
    
    func numberOfRowsInTableView(_ tableView: NSTableView) -> Int {
        return self.infos.count
    }
    
    func tableView(_ tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellView = tableView.make(withIdentifier: "FeatureTemplateCell", owner: self)
        
        let info = self.infos[row]
        
        if let titleLabel = cellView?.viewWithTag(11) as? NSTextField {
            titleLabel.stringValue = info.featureTemplate.name
        }
        
        if let imageView = cellView?.viewWithTag(10) as? NSImageView {
            
            let featureTable = self.featureLayer.featureTable as! AGSArcGISFeatureTable
            //create a new feature based on the template
            let newFeature = featureTable.createFeature(with: info.featureTemplate)!
            let symbol = self.featureLayer.renderer?.symbol(for: newFeature)
            symbol?.createSwatch(completion: { (image: NSImage?, error: Error?) in
                imageView.image = image
            })
        }
        
        return cellView
    }
    
    //MARK: - NSTableViewDelegate
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        let row = self.featureTemplateTableView.selectedRow
        
        //Notify the delegate that the user picked a feature template
        let info = self.infos[row]
        self.delegate?.featureTemplatePickerVC(self, didSelectFeatureTemplate: info.featureTemplate, forFeatureLayer: info.featureLayer)
        
        self.dismiss(nil)
    }
}

