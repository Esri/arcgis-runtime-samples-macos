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

protocol DirectionsListVCDelegate: AnyObject {
    
    func directionsListViewController(_ directionsListViewController: DirectionsListViewController, didSelectDirectionManuever directionManeuver: AGSDirectionManeuver)
    
    func directionsListViewControllerDidDeleteRoute(_ directionsListViewController: DirectionsListViewController)
}

class DirectionsListViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet var tableView: NSTableView!
    @IBOutlet var milesLabel: NSTextField!
    @IBOutlet var minutesLabel: NSTextField!
    
    weak var delegate: DirectionsListVCDelegate?
    
    var route: AGSRoute! {
        didSet {
            self.tableView?.reloadData()
            self.updateLabels()
        }
    }
    
    func updateLabels() {
        if self.route != nil {
            let miles = String(format: "%.2f", self.route.totalLength*0.000621371)
            self.milesLabel.stringValue = "(\(miles) mi)"
            
            var minutes = Int(self.route.totalTime)
            let hours = minutes/60
            minutes = minutes%60
            let hoursString = hours == 0 ? "" : "\(hours) hr "
            let minutesString = minutes == 0 ? "" : "\(minutes) min"
            self.minutesLabel.stringValue = "\(hoursString)\(minutesString)"
        }
    }
    
    // MARK: - NSTableViewDataSource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.route?.directionManeuvers.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DirectionCellView"), owner: self)
        
        if let textField = view?.viewWithTag(1) as? NSTextField {
            textField.stringValue = self.route.directionManeuvers[row].directionText
        }
        
        return view
    }
    
    // MARK: - NSTableViewDelegate
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let directionManeuver = self.route.directionManeuvers[self.tableView.selectedRow]
        self.delegate?.directionsListViewController(self, didSelectDirectionManuever: directionManeuver)
    }
    
    // MARK: - Actions
    
    @IBAction func deleteRouteAction(_ sender: NSButton) {
        self.delegate?.directionsListViewControllerDidDeleteRoute(self)
    }
}
