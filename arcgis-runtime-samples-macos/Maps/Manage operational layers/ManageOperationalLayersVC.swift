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

class ManageOperationalLayersVC: NSViewController, NSTableViewDataSource, NSTableViewDelegate, AddedLayerCellViewDelegate {

    @IBOutlet var mapView:AGSMapView!
    @IBOutlet var tableView1:NSTableView!
    @IBOutlet var tableView2:NSTableView!
    
    private var removedLayers = [AGSLayer]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let map = AGSMap(basemap: AGSBasemap.topographicBasemap())
        
        let imageLayer = AGSArcGISMapImageLayer(URL: NSURL(string: "https://sampleserver5.arcgisonline.com/arcgis/rest/services/Elevation/WorldElevations/MapServer")!)
        map.operationalLayers.addObject(imageLayer)
        
        let tiledLayer = AGSArcGISMapImageLayer(URL: NSURL(string: "https://sampleserver5.arcgisonline.com/arcgis/rest/services/Census/MapServer")!)
        map.operationalLayers.addObject(tiledLayer)
        
        self.mapView.map = map
        self.mapView.setViewpoint(AGSViewpoint(center: AGSPoint(x: -133e5, y: 45e5, spatialReference: AGSSpatialReference(WKID: 3857)), scale: 2e7))
        
        self.mapView.map?.loadWithCompletion({ [weak self] (error:NSError?) in
            self?.tableView1.reloadData()
        })
        
        self.tableView1.registerForDraggedTypes(["hey"])
        
    }
    
    func moveLayer(layer: AGSLayer, from: Int, to: Int) {
        self.mapView.map?.operationalLayers.removeObjectAtIndex(from)
        
        if(to > self.mapView.map!.operationalLayers.count - 1) {
            self.mapView.map?.operationalLayers.addObject(layer)
        }
        else {
            self.mapView.map?.operationalLayers.insertObject(layer, atIndex: to)
        }
        self.tableView1.reloadData()
    }
    
    //MARK: - NSTableViewDataSource
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        if tableView == self.tableView1 {
            return self.mapView?.map?.operationalLayers.count ?? 0
        }
        else {
            return self.removedLayers.count
        }
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        
        if tableView == self.tableView1 {
            let layer = self.mapView.map!.operationalLayers.reverse()[row]
            
            let rowView = tableView.makeViewWithIdentifier("AddedLayerRowView", owner: self) as! AddedLayerCellView
            rowView.delegate = self
            rowView.index = self.mapView.map!.operationalLayers.indexOfObject(layer)
            rowView.textField?.stringValue = layer.name ?? ""
            return rowView
        }
        else {
            let rowView = tableView.makeViewWithIdentifier("RemovedLayerRowView", owner: self) as! NSTableCellView
            let layer = self.removedLayers[row]
            rowView.textField?.stringValue = layer.name ?? ""
            return rowView
        }
    }
    
    func tableView(tableView: NSTableView, writeRowsWithIndexes rowIndexes: NSIndexSet, toPasteboard pboard: NSPasteboard) -> Bool {
        if tableView == tableView1 {
            
            let data = NSKeyedArchiver.archivedDataWithRootObject([rowIndexes])
            pboard.declareTypes(["hey"], owner:self)
            pboard.setData(data, forType:"hey")
            
            return true
        }
        else {
            return false
        }
    }
    
    func tableView(tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
        if tableView == tableView1 {
            tableView.setDropRow(row, dropOperation: NSTableViewDropOperation.Above)
            return .Move
        }
        else {
            return .None
        }
    }
    
    func tableView(tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {
        
        let pasteboard = info.draggingPasteboard()
        let rowData = pasteboard.dataForType("hey")
        
        if(rowData != nil) {
            var dataArray = NSKeyedUnarchiver.unarchiveObjectWithData(rowData!) as! Array<NSIndexSet>,
            indexSet = dataArray[0]
            
            let movingFromIndex = indexSet.firstIndex
            let layer = self.mapView.map!.operationalLayers[movingFromIndex] as! AGSLayer
            
            self.moveLayer(layer, from: movingFromIndex, to: row)
            
            return true
        }
        else {
            return false
        }
    }
    
    //MARK: - NSTableViewDelegate
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        if let tableView = notification.object as? NSTableView {
            if tableView == tableView2 {
                //add layer to the operational layers
                let layer = self.removedLayers[tableView.selectedRow]
                self.removedLayers.removeAtIndex(tableView.selectedRow)
                self.tableView2.reloadData()
                self.mapView.map?.operationalLayers.addObject(layer)
                self.tableView1.reloadData()
            }
        }
    }
    
    //MARK: - AddedLayerCellViewDelegate
    
    func addedLayerCellViewWantsToDelete(addedLayerCellView: AddedLayerCellView) {
        //remove layer and add to removed layers list
        let index = addedLayerCellView.index
        let layer = self.mapView.map?.operationalLayers[index] as! AGSLayer
        self.mapView.map?.operationalLayers.removeObjectAtIndex(index)
        self.tableView1.reloadData()
        
        self.removedLayers.append(layer)
        self.tableView2.reloadData()
    }
}
