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

protocol ExistingMapsListViewControllerDelegate: class {
    func existingMapsListViewController(_:ExistingMapsListViewController, didSelectItemAt index: Int)
}

class ExistingMapsListViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    var existingMaps = [ExistingMap]() {
        didSet {
            tableView?.reloadData()
        }
    }
    weak var delegate: ExistingMapsListViewControllerDelegate?
    
    @IBOutlet private var tableView: NSTableView!
    
    //MARK: - NSTableViewDataSource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return existingMaps.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let existingMap = existingMaps[row]
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
        delegate?.existingMapsListViewController(self, didSelectItemAt: tableView.selectedRow)
        dismiss(nil)
    }
}
