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

protocol ExistingMapsListDelegate:class {
    func existingMapsListViewController(_:ExistingMapsListViewController, didSelectItemAtIndex index:Int)
}

class ExistingMapsListViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    private var titles = ["Housing with Mortgages", "USA Tapestry Segmentation", "Geology of United States"]
    private var imageNames = ["OpenExistingMapThumbnail1", "OpenExistingMapThumbnail2", "OpenExistingMapThumbnail3"]
    
    @IBOutlet private var tableView:NSTableView!
    
    weak var delegate:ExistingMapsListDelegate?
    
    //MARK: - NSTableViewDataSource
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return 3
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellView = tableView.makeViewWithIdentifier("MapCell", owner: self)
        
        
        if let titleLabel = cellView?.viewWithTag(11) as? NSTextField {
            titleLabel.stringValue = self.titles[row]
        }
        
        if let imageView = cellView?.viewWithTag(10) as? NSImageView {
            imageView.image = NSImage(named: self.imageNames[row])
        }
        
        return cellView
    }
    
    //MARK: - NSTableViewDelegate
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        self.delegate?.existingMapsListViewController(self, didSelectItemAtIndex: self.tableView.selectedRow)
        self.dismissController(nil)
    }
}
