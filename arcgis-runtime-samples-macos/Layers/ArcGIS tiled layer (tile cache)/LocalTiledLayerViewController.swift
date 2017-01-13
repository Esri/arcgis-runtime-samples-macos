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

class LocalTiledLayerViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet var mapView:AGSMapView!
    @IBOutlet var tableView:NSTableView!
    
    private var bundleTPKPaths:[String]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //create a tiled layer using one of the tile packages
        let tileCache = AGSTileCache(name: "SanFrancisco")
        let localTiledLayer = AGSArcGISTiledLayer(tileCache: tileCache)
        
        //instantiate a map, use the tiled layer as the basemap
        let map = AGSMap(basemap: AGSBasemap(baseLayer: localTiledLayer))
        
        //assign the map to the map view
        self.mapView.map = map
        
        //
        self.fetchTilePackages()
    }
    
    func fetchTilePackages() {
        self.bundleTPKPaths = NSBundle.mainBundle().pathsForResourcesOfType("tpk", inDirectory: nil)
        self.tableView.reloadData()
    }
    
    func extractName(path:String) -> String {
        var index = path.rangeOfString("/", options: .BackwardsSearch, range: nil, locale: nil)?.startIndex
        index = index?.advancedBy(1)
        let name = path.substringFromIndex(index!)
        return name
    }
    
    //MARK: - NSTableViewDataSource
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return self.bundleTPKPaths?.count ?? 0
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let path = self.bundleTPKPaths[row]
        
        let cellView = tableView.makeViewWithIdentifier("TPKCellView", owner: self) as! NSTableCellView
        cellView.textField?.stringValue = self.extractName(path)
        
        return cellView
    }
    
    //MARK: - NSTableViewDelegate
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        let row = self.tableView.selectedRow
        let path = self.bundleTPKPaths[row]
        
        //create a new map with selected tile package as the basemap
        let localTiledLayer = AGSArcGISTiledLayer(tileCache: AGSTileCache(fileURL: NSURL(fileURLWithPath: path)))
        let map = AGSMap(basemap: AGSBasemap(baseLayer: localTiledLayer))
        self.mapView.map = map
    }
}
