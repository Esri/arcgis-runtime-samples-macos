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
import ArcGIS

class ManageOperationalLayersVC: NSViewController, NSTableViewDataSource, NSTableViewDelegate, AddedLayerCellViewDelegate {

    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var tableView1: NSTableView!
    @IBOutlet var tableView2: NSTableView!
    
    private var removedLayers = [AGSLayer]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let map = AGSMap(basemap: .topographic())
        
        let imageLayer = AGSArcGISMapImageLayer(url: URL(string: "https://sampleserver5.arcgisonline.com/arcgis/rest/services/Elevation/WorldElevations/MapServer")!)
        map.operationalLayers.add(imageLayer)
        
        let tiledLayer = AGSArcGISMapImageLayer(url: URL(string: "https://sampleserver5.arcgisonline.com/arcgis/rest/services/Census/MapServer")!)
        map.operationalLayers.add(tiledLayer)
        
        self.mapView.map = map
        self.mapView.setViewpoint(AGSViewpoint(center: AGSPoint(x: -133e5, y: 45e5, spatialReference: AGSSpatialReference(wkid: 3857)), scale: 2e7))
        
        self.mapView.map?.load(completion: { [weak self] (error: Error?) in
            self?.tableView1.reloadData()
        })
        
        self.tableView1.registerForDraggedTypes([NSPasteboard.PasteboardType(rawValue: "hey")])
        
    }
    
    func moveLayer(_ layer: AGSLayer, from: Int, to: Int) {
        self.mapView.map?.operationalLayers.removeObject(at: from)
        
        if(to > self.mapView.map!.operationalLayers.count - 1) {
            self.mapView.map?.operationalLayers.add(layer)
        }
        else {
            self.mapView.map?.operationalLayers.insert(layer, at: to)
        }
        self.tableView1.reloadData()
    }
    
    //MARK: - NSTableViewDataSource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == self.tableView1 {
            return self.mapView?.map?.operationalLayers.count ?? 0
        }
        else {
            return self.removedLayers.count
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        
        if tableView == self.tableView1 {
            let layer = self.mapView.map!.operationalLayers.reversed()[row]
            
            let rowView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "AddedLayerRowView"), owner: self) as! AddedLayerCellView
            rowView.delegate = self
            rowView.index = self.mapView.map!.operationalLayers.index(of: layer)
            rowView.textField?.stringValue = (layer as AnyObject).name ?? ""
            return rowView
        }
        else {
            let rowView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RemovedLayerRowView"), owner: self) as! NSTableCellView
            let layer = self.removedLayers[row]
            rowView.textField?.stringValue = layer.name 
            return rowView
        }
    }
    
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        if tableView == tableView1 {
            
            let data = NSKeyedArchiver.archivedData(withRootObject: [rowIndexes])
            pboard.declareTypes([NSPasteboard.PasteboardType(rawValue: "hey")], owner: self)
            pboard.setData(data, forType: NSPasteboard.PasteboardType(rawValue: "hey"))
            
            return true
        }
        else {
            return false
        }
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        if tableView == tableView1 {
            tableView.setDropRow(row, dropOperation: NSTableView.DropOperation.above)
            return .move
        }
        else {
            return NSDragOperation()
        }
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        
        let pasteboard = info.draggingPasteboard
        let rowData = pasteboard.data(forType: NSPasteboard.PasteboardType(rawValue: "hey"))
        
        if(rowData != nil) {
            var dataArray = NSKeyedUnarchiver.unarchiveObject(with: rowData!) as! Array<IndexSet>,
            indexSet = dataArray[0]
            
            let movingFromIndex = indexSet.first
            let layer = self.mapView.map!.operationalLayers[movingFromIndex!] as! AGSLayer
            
            self.moveLayer(layer, from: movingFromIndex!, to: row)
            
            return true
        }
        else {
            return false
        }
    }
    
    //MARK: - NSTableViewDelegate
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if let tableView = notification.object as? NSTableView {
            if tableView == tableView2, tableView.selectedRow != -1 {
                //add layer to the operational layers
                let layer = self.removedLayers[tableView.selectedRow]
                self.removedLayers.remove(at: tableView.selectedRow)
                self.tableView2.reloadData()
                self.mapView.map?.operationalLayers.add(layer)
                self.tableView1.reloadData()
            }
        }
    }
    
    //MARK: - AddedLayerCellViewDelegate
    
    func addedLayerCellViewWantsToDelete(_ addedLayerCellView: AddedLayerCellView) {
        //remove layer and add to removed layers list
        let index = addedLayerCellView.index
        let layer = self.mapView.map?.operationalLayers[index] as! AGSLayer
        self.mapView.map?.operationalLayers.removeObject(at: index)
        self.tableView1.reloadData()
        
        self.removedLayers.append(layer)
        self.tableView2.reloadData()
    }
}
