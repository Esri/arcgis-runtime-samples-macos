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

import ArcGIS

private let kDragRowType:String = "AGSLayerInMap"
private let kLayerInTableRowKey:String = "AddedLayerRowView"
private let kLayerNotInTableRowKey:String = "RemovedLayerRowView"

class ReadGeopackageViewController: NSViewController {
    
    @IBOutlet weak var mapView:AGSMapView!
    
    @IBOutlet weak var layersInMapTableView: NSTableView!
    @IBOutlet weak var layersNotInMapTableView: NSTableView!
    
    private var geoPackage:AGSGeoPackage?
    fileprivate var allLayers:[AGSLayer] = [] {
        didSet {
            var rasterCount = 1
            for layer in allLayers where layer is AGSRasterLayer &&
                layer.name.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty {
                    // Give raster layers a name
                    layer.name = "Raster Layer \(rasterCount)"
                    rasterCount += 1
            }
        }
    }
    
    fileprivate var layersInMap:[AGSLayer] {
        // 0 is the bottom-most layer on the map, but first cell in a table.
        // By reversing the layer order from the map, we match the UITableView order.
        return mapView.map?.operationalLayers.reversed() as? [AGSLayer] ?? []
    }
    
    fileprivate var layersNotInMap:[AGSLayer] {
        guard mapView.map != nil else {
            return allLayers
        }
        
        return allLayers.filter({ layer -> Bool in
            return !layersInMap.contains(layer)
        })
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Instantiate and display a map using a basemap, location, and zoom level.
        mapView.map = AGSMap(basemapType: .streets, latitude: 39.7294, longitude: -104.8319, levelOfDetail: 11)
        
        // Create a geopackage from a named bundle resource.
        geoPackage = AGSGeoPackage(name: "AuroraCO")
        
        // Load the geopackage.
        geoPackage?.load { [weak self] error in
            guard error == nil else {
                print("Error loading the geopackage: \(error!.localizedDescription)")
                return
            }

            // Create feature layers for each feature table in the geopackage.
            let featureLayers = self?.geoPackage?.geoPackageFeatureTables.map({ featureTable -> AGSLayer in
                return AGSFeatureLayer(featureTable: featureTable)
            }) ?? []
            
            // Create raster layers for each raster in the geopackage.
            let rasterLayers = self?.geoPackage?.geoPackageRasters.map({ raster -> AGSLayer in
                return AGSRasterLayer(raster: raster)
            }) ?? []

            // Keep an array of all the feature layers and raster layers in this geopackage.
            var layers = [AGSLayer]()
            layers.append(contentsOf: rasterLayers)
            layers.append(contentsOf: featureLayers)
            self?.allLayers = layers
            
            self?.layersInMapTableView.reloadData()
            self?.layersNotInMapTableView.reloadData()
        }
        
        layersInMapTableView.register(forDraggedTypes: [kDragRowType])
    }

}

extension ReadGeopackageViewController: NSTableViewDataSource, NSTableViewDelegate, GPKGLayerTableCellDelegate {
    //MARK: - NSTableViewDataSource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == self.layersInMapTableView {
            return layersInMap.count
        }
        else {
            return layersNotInMap.count
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if tableView == self.layersInMapTableView {
            if let rowView = tableView.make(withIdentifier: kLayerInTableRowKey, owner: self) as? GPKGLayerTableCell {
                rowView.agsLayer = layersInMap[row]
                rowView.delegate = self
                return rowView
            }
        }
        else {
            if let rowView = tableView.make(withIdentifier: kLayerNotInTableRowKey, owner: self) as? NSTableCellView {
                let layer = layersNotInMap[row]
                rowView.textField?.stringValue = layer.name
                return rowView
            }
        }
        print("Unable to create tableview row view!")
        return nil
    }
    
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        if tableView == layersInMapTableView {
            
            let data = NSKeyedArchiver.archivedData(withRootObject: [rowIndexes])
            pboard.declareTypes([kDragRowType], owner:self)
            pboard.setData(data, forType:kDragRowType)
            
            return true
        }
        else {
            return false
        }
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
        if tableView == layersInMapTableView {
            tableView.setDropRow(row, dropOperation: NSTableViewDropOperation.above)
            return .move
        }
        else {
            return NSDragOperation()
        }
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {
        
        let pasteboard = info.draggingPasteboard()
        let rowData = pasteboard.data(forType: kDragRowType)
        
        if(rowData != nil) {
            let dataArray = NSKeyedUnarchiver.unarchiveObject(with: rowData!) as! Array<IndexSet>
            
            if let movingFromIndex = dataArray.first?.first {
                self.moveLayer(from: movingFromIndex, to: row)
            
                return true
            }
            return false
        }
        else {
            return false
        }
    }
    
    func moveLayer(from: Int, to: Int) {
        guard let map = mapView.map else {
            print("No map to manipulate layers on!")
            return
        }
        
        guard from != to && to != from + 1 else {
            // Don't do anything if we drop it into the gap between itself and
            // the row before or itself and the row after.
            return
        }
        
        let newMapIndex = map.operationalLayers.count - to
        let layer = layersInMap[from]

        map.operationalLayers.remove(layer)
        map.operationalLayers.insert(layer, at: newMapIndex)

        layersInMapTableView.reloadData()
    }

    
    //MARK: - NSTableViewDelegate
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if let tableView = notification.object as? NSTableView {
            if tableView == layersNotInMapTableView {
                //add layer to the operational layers
                let layer = layersNotInMap[tableView.selectedRow]
                mapView.map?.operationalLayers.add(layer)
                layersInMapTableView.reloadData()
                layersNotInMapTableView.reloadData()
            }
        }
    }
    
    //MARK: - GPKGLayerTableCellDelegate
    
    func removeLayerFromMap(cell: GPKGLayerTableCell) {
        if let layer = cell.agsLayer {
            mapView.map?.operationalLayers.remove(layer)
            layersInMapTableView.reloadData()
            layersNotInMapTableView.reloadData()
        }
    }
}
