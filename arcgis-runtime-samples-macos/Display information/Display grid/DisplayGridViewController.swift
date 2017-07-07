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

class DisplayGridViewController: NSViewController {

    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var gridSettingsView: NSVisualEffectView!
    @IBOutlet weak var gridSettingsTextField: NSTextField!
    @IBOutlet weak var gridVisibilityControl: NSSegmentedControl!
    @IBOutlet weak var gridTypeButton: NSPopUpButton!
    @IBOutlet weak var gridColorWell: NSColorWell!
    @IBOutlet weak var labelVisibilityControl: NSSegmentedControl!
    @IBOutlet weak var labelColorWell: NSColorWell!
    @IBOutlet weak var labelPositionButton: NSPopUpButton!
    @IBOutlet weak var labelFormatButton: NSPopUpButton!
    @IBOutlet weak var labelUnitButton: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize map with imagery basemap
        let map = AGSMap(basemap: AGSBasemap.imagery())
        
        // Set initial viewpoint
        let center = AGSPoint(x: -7702852.905619, y: 6217972.345771, spatialReference: AGSSpatialReference(wkid: 3857))
        map.initialViewpoint = AGSViewpoint(center: center, scale: 23227)
        
        // Assign map to the map view
        mapView.map = map
        
        // Add lat long grid
        mapView.grid = AGSLatitudeLongitudeGrid()
    }
    
    override func viewWillAppear() {
        //
        // Set style of settings view
        gridSettingsView.wantsLayer = true
        gridSettingsView.layer?.cornerRadius = 10
        gridSettingsTextField.backgroundColor = NSColor.primaryBlue()
        gridSettingsTextField.wantsLayer = true
        gridSettingsTextField.layer?.cornerRadius = 5
    }
    
    // MARK: Actions
    
    @IBAction func gridVisibilityAction(_ sender:NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0:
            mapView.grid?.isVisible = true
        case 1:
            mapView.grid?.isVisible = false
        default:
            break
        }
    }
    
    @IBAction func gridTypeAction(_ sender:NSPopUpButton) {
        switch sender.indexOfSelectedItem {
            case 0:
                mapView.grid = AGSLatitudeLongitudeGrid()
                labelFormatButton.isEnabled = true
                labelUnitButton.isEnabled = false
            case 1:
                mapView.grid = AGSMGRSGrid()
                labelFormatButton.isEnabled = false
                labelUnitButton.isEnabled = true
            case 2:
                 mapView.grid = AGSUTMGrid()
                 labelFormatButton.isEnabled = false
                 labelUnitButton.isEnabled = false
            case 3:
                mapView.grid = AGSUSNGGrid()
                labelFormatButton.isEnabled = false
                labelUnitButton.isEnabled = true
            default:
                break
        }
        
        gridVisibilityAction(gridVisibilityControl)
        gridColorAction(gridColorWell)
        labelVisibilityAction(labelVisibilityControl)
        labelColorAction(labelColorWell)
        labelPositionAction(labelPositionButton)
        labelFormatAction(labelFormatButton)
        labelUnitAction(labelUnitButton)
    }
    
    @IBAction func gridColorAction(_ sender : NSColorWell) {
        if let gridLevels = mapView.grid?.levelCount {
            for gridLevel in 0...gridLevels-1 {
                let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: sender.color, width: CGFloat(gridLevel+1))
                mapView.grid?.setLineSymbol(lineSymbol, forLevel: gridLevel)
            }
        }
    }
    
    @IBAction func labelVisibilityAction(_ sender:NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0:
            mapView.grid?.labelVisibility = true
        case 1:
            mapView.grid?.labelVisibility = false
        default:
            break
        }
    }
    
    @IBAction func labelColorAction(_ sender : NSColorWell) {
        if let gridLevels = mapView.grid?.levelCount {
            for gridLevel in 0...gridLevels-1 {
                let textSymbol = AGSTextSymbol()
                textSymbol.color = sender.color
                textSymbol.size = 14
                textSymbol.horizontalAlignment = .left
                textSymbol.verticalAlignment = .bottom
                textSymbol.haloColor = NSColor.white
                textSymbol.haloWidth = CGFloat(gridLevel+1)
                mapView.grid?.setTextSymbol(textSymbol, forLevel: gridLevel)
            }
        }
    }
    
    @IBAction func labelPositionAction(_ sender:NSPopUpButton) {
        mapView?.grid?.labelPosition = AGSGridLabelPosition(rawValue: sender.indexOfSelectedItem)!
    }
    
    @IBAction func labelFormatAction(_ sender:NSPopUpButton) {
        if mapView?.grid is AGSLatitudeLongitudeGrid {
            (mapView?.grid as! AGSLatitudeLongitudeGrid).labelFormat = AGSLatitudeLongitudeGridLabelFormat(rawValue: sender.indexOfSelectedItem)!
        }
    }
    
    @IBAction func labelUnitAction(_ sender:NSPopUpButton) {
        if mapView?.grid is AGSMGRSGrid {
            (mapView?.grid as! AGSMGRSGrid).labelUnit = AGSMGRSGridLabelUnit(rawValue: sender.indexOfSelectedItem)!
        }
        else if mapView?.grid is AGSUSNGGrid {
            (mapView?.grid as! AGSUSNGGrid).labelUnit = AGSUSNGGridLabelUnit(rawValue: sender.indexOfSelectedItem)!
        }
    }
}
