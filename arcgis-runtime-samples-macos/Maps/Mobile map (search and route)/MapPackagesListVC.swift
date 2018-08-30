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

protocol MapPackagesListVCDelegate: AnyObject {
    
    func mapPackagesListVC(_ mapPackagesListVC: MapPackagesListVC, wantsToShowMap map: AGSMap, withLocatorTask locatorTask: AGSLocatorTask?)
}

class MapPackagesListVC: NSViewController, NSTableViewDataSource, NSTableViewDelegate, MapPackageCellDelegate {

    @IBOutlet private var tableView:NSTableView!
    
    private var mapPackages:[AGSMobileMapPackage]!
    private var selectedRow = -1
    
    weak var delegate:MapPackagesListVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.fetchMapPackages()
    }
    
    func fetchMapPackages() {
        //load map packages from the bundle
        let bundleMMPKPaths = Bundle.main.paths(forResourcesOfType: "mmpk", inDirectory: nil)
        
        //create map packages from the paths
        self.mapPackages = [AGSMobileMapPackage]()
        
        for path in bundleMMPKPaths {
            let mapPackage = AGSMobileMapPackage(fileURL: URL(fileURLWithPath: path))
            self.mapPackages.append(mapPackage)
        }
        
        self.tableView.reloadData()
    }
    
    //MARK: - NSTableViewDataSource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.mapPackages?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MapPackageCell"), owner: self) as! MapPackageCellView
        
        let mapPackage = self.mapPackages[row]
        cellView.mapPackage = mapPackage
        cellView.delegate = self
        
        return cellView
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if row == self.tableView.selectedRow {
            return 158  //height for expanded row
        }
        else {
            return 35   //height for regular row
        }
    }
    
    //MARK: - NSTableViewDelegate
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if self.selectedRow != -1 {
            let previouslySelectedRow = self.selectedRow
            let previousIndexSet = IndexSet(integer: previouslySelectedRow)
            self.tableView.noteHeightOfRows(withIndexesChanged: previousIndexSet)
            
            //unselect selection for collection view
            let cellView = self.tableView.view(atColumn: 0, row: previouslySelectedRow, makeIfNecessary: false) as! MapPackageCellView
            cellView.collectionView.deselectAll(self)
        }
        
        let indexSet = IndexSet(integer: self.tableView.selectedRow)
        self.tableView.noteHeightOfRows(withIndexesChanged: indexSet)
        self.selectedRow = self.tableView.selectedRow
    }
    
    //MARK: - MapPackageCellDelegate
    
    func mapPackageCellView(_ mapPackageCellView: MapPackageCellView, didSelectMap map: AGSMap) {
        
        self.delegate?.mapPackagesListVC(self, wantsToShowMap: map, withLocatorTask: mapPackageCellView.mapPackage.locatorTask)
    }
}
