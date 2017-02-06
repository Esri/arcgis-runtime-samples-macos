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

class ManageBookmarksViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {

    @IBOutlet var mapView:AGSMapView!
    @IBOutlet var tableView:NSTableView!
    
    private var map:AGSMap!
    private var alert:NSAlert!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize map using imagery with labels basemap
        self.map = AGSMap(basemap: AGSBasemap.imageryWithLabels())
        
        //assign map to the mapView
        self.mapView.map = self.map
        
        //add default bookmarks
        self.addDefaultBookmarks()
        
        //zoom to the last bookmark
        self.map.initialViewpoint = (self.map.bookmarks.lastObject as AnyObject).viewpoint
        
        self.tableView.reloadData()
    }
    
    private func addDefaultBookmarks() {
        //create a few bookmarks and add them to the map
        var viewpoint:AGSViewpoint, bookmark:AGSBookmark
        
        //Mysterious Desert Pattern
        viewpoint = AGSViewpoint(latitude: 27.3805833, longitude: 33.6321389, scale: 6e3)
        bookmark = AGSBookmark()
        bookmark.name = "Mysterious Desert Pattern"
        bookmark.viewpoint = viewpoint
        //add the bookmark to the map
        self.map.bookmarks.add(bookmark)
        
        //Strange Symbol
        viewpoint = AGSViewpoint(latitude: 37.401573, longitude: -116.867808, scale: 6e3)
        bookmark = AGSBookmark()
        bookmark.name = "Strange Symbol"
        bookmark.viewpoint = viewpoint
        //add the bookmark to the map
        self.map.bookmarks.add(bookmark)
        
        //Guitar-Shaped Forest
        viewpoint = AGSViewpoint(latitude: -33.867886, longitude: -63.985, scale: 4e4)
        bookmark = AGSBookmark()
        bookmark.name = "Guitar-Shaped Forest"
        bookmark.viewpoint = viewpoint
        //add the bookmark to the map
        self.map.bookmarks.add(bookmark)
        
        //Grand Prismatic Spring
        viewpoint = AGSViewpoint(latitude: 44.525049, longitude: -110.83819, scale: 6e3)
        bookmark = AGSBookmark()
        bookmark.name = "Grand Prismatic Spring"
        bookmark.viewpoint = viewpoint
        //add the bookmark to the map
        self.map.bookmarks.add(bookmark)
    }
    
    private func addBookmark(with name:String) {
        //instantiate a bookmark and set the properties
        let bookmark = AGSBookmark()
        bookmark.name = name
        bookmark.viewpoint = self.mapView.currentViewpoint(with: AGSViewpointType.boundingGeometry)
        
        //add the bookmark to the map
        self.map.bookmarks.add(bookmark)
        
        //refresh the table view if it exists
        self.tableView.reloadData()
    }
    
    //MARK: - NSTableViewDataSource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.map?.bookmarks.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let bookmark = self.map.bookmarks[row]
        
        let cellView = tableView.make(withIdentifier: "BookmarkCellView", owner: self) as! NSTableCellView
        
        //bookmark name
        cellView.textField?.stringValue = (bookmark as AnyObject).name
        
        return cellView
    }
    
    //MARK: - NSTableViewDelegate
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let index = self.tableView.selectedRow
        let bookmark = self.map.bookmarks[index] as! AGSBookmark
        self.mapView.setViewpoint(bookmark.viewpoint!)
    }
    
    //MARK: - Actions
    
    @IBAction private func addAction(_ sender:NSButton) {
        
        //show alert to get name for new bookmark
        self.alert = NSAlert()
        self.alert.messageText = "Provide a name for the bookmark"
        self.alert.addButton(withTitle: "OK")
        self.alert.addButton(withTitle: "Cancel")
        
        //disable ok button at first, will enable on text input
        self.alert.buttons[0].isEnabled = false
        
        //textfield for input
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.delegate = self
        self.alert.accessoryView = textField
        
        //show alert
        self.alert.beginSheetModal(for: self.view.window!) { [weak self] (response: NSModalResponse) in
            //on OK
            if response == NSAlertFirstButtonReturn {
                self?.addBookmark(with: textField.stringValue)
            }
        }
    }
    
    //MARK: - NSTextFieldDelegate
    
    override func controlTextDidChange(_ obj: Notification) {
        //enable OK button on alert when textfield gets input
        let textField = obj.object as! NSTextField
        if textField.stringValue.isEmpty {
            self.alert.buttons[0].isEnabled = false
        }
        else {
            self.alert.buttons[0].isEnabled = true
        }
    }
}
