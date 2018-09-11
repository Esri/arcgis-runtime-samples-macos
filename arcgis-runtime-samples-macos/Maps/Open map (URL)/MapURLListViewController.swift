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

protocol MapURLListViewControllerDelegate: AnyObject {
    func mapURLListViewController(_:MapURLListViewController, didSelectItemAt index: Int)
}

class MapURLListViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    var maps = [MapAtURL]() {
        didSet {
            tableView?.reloadData()
        }
    }
    weak var delegate: MapURLListViewControllerDelegate?
    
    @IBOutlet private var tableView: NSTableView!
    
    //MARK: - NSTableViewDataSource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return maps.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let existingMap = maps[row]
        let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("MapCell"), owner: self)
        
        if let titleLabel = cellView?.viewWithTag(11) as? NSTextField {
            titleLabel.stringValue = existingMap.title
        }
        
        if let imageView = cellView?.viewWithTag(10) as? NSImageView {
            imageView.image = existingMap.image
        }
        
        return cellView
    }
    
    //MARK: - NSTableViewDelegate
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        delegate?.mapURLListViewController(self, didSelectItemAt: tableView.selectedRow)
        dismiss(nil)
    }
}
