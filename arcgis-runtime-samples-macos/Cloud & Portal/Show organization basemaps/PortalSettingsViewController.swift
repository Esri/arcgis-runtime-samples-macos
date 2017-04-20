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

import Cocoa
import ArcGIS

protocol PortalSettingsVCDelegate:class {
    
    func portalSettingsViewControllerDidFinish(_ portalSettingsViewController:PortalSettingsViewController)
}

class PortalSettingsViewController: NSViewController {

    @IBOutlet private var textField:NSTextField!
    @IBOutlet private var anonymousCheck:NSButton!
    
    var portalURLString = "https://www.arcgis.com"
    var anonymousUser = true
    
    weak var delegate:PortalSettingsVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set initial values
        self.textField.stringValue = self.portalURLString
        self.anonymousCheck.state = self.anonymousUser ? 1 : 0
    }
    
    @IBAction func doneAction(sender:NSButton) {
        if textField.stringValue.isEmpty {
            textField.stringValue = "https://www.arcgis.com"
        }
        
        //set values
        self.portalURLString = self.textField.stringValue
        self.anonymousUser = self.anonymousCheck.state == 1
        
        //notify delegate
        self.delegate?.portalSettingsViewControllerDidFinish(self)
    }
}
