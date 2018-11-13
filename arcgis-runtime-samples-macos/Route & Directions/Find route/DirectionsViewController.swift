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

import Cocoa
import ArcGIS

class DirectionsViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet var tableView: NSTableView!
    
    //provide route with direction maneuvers
    var route: AGSRoute?
    
    // MARK: - NSTableViewDataSource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        //return self.route?.directionManeuvers.count ?? 0
        return 12
    }
    
    // MARK: - NSTableViewDelegate
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        //cell view
        let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DirectionCellView"), owner: self)
        
        guard let directionManeuver = self.route?.directionManeuvers[row] else {
            return view
        }
        
        guard let textField = view?.viewWithTag(1) as? NSTextField else {
            return view
        }
        
        //set direction text on the textfield
        textField.stringValue = directionManeuver.directionText
        
        return view
    }
    
}
