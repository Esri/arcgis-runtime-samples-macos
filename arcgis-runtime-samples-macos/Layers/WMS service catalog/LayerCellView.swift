//
// Copyright 2018 Esri.
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

protocol LayerCellViewDelegate:class {
    func layerCellView(_ layerCellView:LayerCellView, didToggleVisibility visible:Bool)
}

class LayerCellView: NSTableCellView {

    @IBOutlet var button:NSButton!
    
    var index:Int = -1
    
    weak var delegate:LayerCellViewDelegate?
    
    @IBAction func checkboxAction(_ sender:NSButton) {
        self.delegate?.layerCellView(self, didToggleVisibility: sender.state == 1)
    }
    
}
