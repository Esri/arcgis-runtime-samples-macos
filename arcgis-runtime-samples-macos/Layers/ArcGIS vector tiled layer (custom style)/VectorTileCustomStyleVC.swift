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

class VectorTileCustomStyleVC: NSViewController {

    @IBOutlet private var mapView:AGSMapView!
    @IBOutlet weak var stylesPopUpButton: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // The styles to display in the popup menu
        let vectorStyleItems: [VectorStyleItem] = [
            VectorStyleItem(itemId: "1349bfa0ed08485d8a92c442a3850b06",
                            label: "Dark / Light Gray",
                            color1: #colorLiteral(red: 0.8117647059, green: 0.8117647059, blue: 0.831372549, alpha: 1),
                            color2: #colorLiteral(red: 0.9294117647, green: 0.9294117647, blue: 0.9294117647, alpha: 1)),
            VectorStyleItem(itemId: "bd8ac41667014d98b933e97713ba8377",
                            label: "Navy / Green",
                            color1: #colorLiteral(red: 0, green: 0.4, blue: 0.6666666667, alpha: 1),
                            color2: #colorLiteral(red: 0.4666666667, green: 0.7333333333, blue: 0, alpha: 1)),
            VectorStyleItem(itemId: "02f85ec376084c508b9c8e5a311724fa",
                            label: "Yellow / Purple",
                            color1: #colorLiteral(red: 0.8235294118, green: 0.8745098039, blue: 0, alpha: 1),
                            color2: #colorLiteral(red: 0.5529411765, green: 0, blue: 0.8745098039, alpha: 1)),
            VectorStyleItem(itemId: "1bf0cc4a4380468fbbff107e100f65a5",
                            label: "Blue / Red",
                            color1: #colorLiteral(red: 0.2588235294, green: 0.7058823529, blue: 0.9490196078, alpha: 1),
                            color2: #colorLiteral(red: 0.7294117647, green: 0, blue: 0.1607843137, alpha: 1))
        ]
        
        // populate the popup button's menu with the style items
        for vectorStyleItem in vectorStyleItems {
            let menuItem = NSMenuItem()
            menuItem.title = vectorStyleItem.label
            menuItem.image = vectorStyleItem.thumbnailImage
            menuItem.representedObject = vectorStyleItem
            stylesPopUpButton.menu?.addItem(menuItem)
        }
        
        //initialize a map
        let map = AGSMap()
        
        //set the map's initial viewpoint
        let centerPoint = AGSPoint(x: 1990591.559979, y: 794036.007991, spatialReference: AGSSpatialReference(wkid: 3857))
        map.initialViewpoint = AGSViewpoint(center: centerPoint, scale: 88659253.829259947)
        
        //assign the map to map view
        mapView.map = map
        
        //load the inital vector style basemap
        setBasemap(item: vectorStyleItems.first!)
    }
    
    private func setBasemap(item: VectorStyleItem) {
        
        // create a vector tiled layer from the item's URL
        let vectorTiledLayer = AGSArcGISVectorTiledLayer(url: item.itemURL)
        
        //create a basemap from the layer
        let basemap = AGSBasemap(baseLayer: vectorTiledLayer)
        
        // assign the basemap to the displayed map
        mapView.map?.basemap = basemap
    }
    
    @IBAction func stylesPopUpButtonAction(_ sender: NSPopUpButton) {
        if let item = sender.selectedItem?.representedObject as? VectorStyleItem {
            // set the basemap for the selected item
            setBasemap(item: item)
        }
    }
    
    /// A model for the items in the vectors styles popup menu
    struct VectorStyleItem {
        var itemId: String
        var label: String
        var color1: NSColor
        var color2: NSColor
    }
    
}

extension VectorTileCustomStyleVC.VectorStyleItem {
    
    var itemURL: URL {
        return URL(string: "https://arcgisruntime.maps.arcgis.com/home/item.html?id=\(itemId)")!
    }
    
    /// Image for the popup menu, generated from the style's colors
    var thumbnailImage: NSImage {
        
        // a reasonable size for a menu item image
        let size = CGSize(width: 28, height: 16)
        
        // setup a view with the first color
        let view = NSView(frame: CGRect(origin: .zero, size: size))
        view.wantsLayer = true
        view.layer?.backgroundColor = color1.cgColor
        
        // create and add a layer for the second color
        let color2Layer = CALayer()
        color2Layer.backgroundColor = color2.cgColor
        view.layer?.addSublayer(color2Layer)
        color2Layer.frame = CGRect(x: size.width/2, y: 0, width: size.width/2, height: size.height)
        
        // create and return an image based on the view
        let imageRep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
        view.cacheDisplay(in: view.bounds, to: imageRep)
        return NSImage(cgImage: imageRep.cgImage!, size: imageRep.size)
    }
    
}
