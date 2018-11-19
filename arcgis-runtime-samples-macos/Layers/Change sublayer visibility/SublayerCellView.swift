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

protocol SublayerCellViewDelegate: AnyObject {
    func sublayerCellView(_ sublayerCellView: SublayerCellView, didSetVisibility visible: Bool)
}

class SublayerCellView: NSTableCellView {

    @IBOutlet var button: NSButton!
    
    var index: Int = -1
    
    weak var delegate: SublayerCellViewDelegate?
    
    @IBAction func checkboxAction(_ sender: NSButton) {
        Swift.print(sender.state)
        self.delegate?.sublayerCellView(self, didSetVisibility: sender.state.rawValue == 1)
    }
    
}
