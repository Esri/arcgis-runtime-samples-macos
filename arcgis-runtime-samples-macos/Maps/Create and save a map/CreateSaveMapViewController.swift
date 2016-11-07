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

class CreateSaveMapViewController: NSViewController, CreateOptionsVCDelegate, SaveMapVCDelegate {

    @IBOutlet var mapView:AGSMapView!
    @IBOutlet var optionsContainerView:NSView!
    @IBOutlet var saveMapContainerView:NSView!
    
    private var portal:AGSPortal!
    private var saveMapVC:SaveMapViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        //initialize map to imagery basemap for the blur background
        let map = AGSMap(basemap: AGSBasemap.imageryBasemap())
        
        //assign the map to the map view
        self.mapView.map = map
        
        //for visual effect view to work
        self.view.wantsLayer = true
    }
    
    //MARK: - Save map
    
    private func saveMap(title:String, tags:[String], itemDescription:String?, thumbnail:NSImage?) {
        self.mapView.map?.saveAs(title, portal: self.portal!, tags: tags, folder: nil, itemDescription: itemDescription!, thumbnail: thumbnail, forceSaveToSupportedVersion: true, completion: { [weak self] (error) -> Void in
            
            if let error = error {
                self?.showAlert("Error", informativeText: error.localizedDescription)
            }
            else {
                self?.showAlert("Info", informativeText: "Map was saved successfully")
            }
            
            //reset fields in save map view controller
            self?.saveMapVC.resetInputFields()
        })
    }
    
    
    //MARK: - Show/hide options view controller
    
    private func toggleOptionsVC(toggleOn on:Bool) {
        self.optionsContainerView.hidden = !on
    }
    
    //MARK: - Show/hide save map view controller
    
    private func toggleSaveMapVC(toggleOn on:Bool) {
        self.saveMapContainerView.hidden = !on
    }
    
    //MARK: - Navigation
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "OptionsVCSegue" {
            let controller = segue.destinationController as! CreateOptionsViewController
            controller.delegate = self
        }
        else if segue.identifier == "SaveMapVCSegue" {
            self.saveMapVC = segue.destinationController as! SaveMapViewController
            self.saveMapVC.delegate = self
        }
    }
    
    //MARK: - CreateOptionsVCDelegate
    
    func createOptionsViewController(createOptionsViewController: CreateOptionsViewController, didSelectBasemap basemap: AGSBasemap, layers: [AGSLayer]?) {
        
        //create a map with the selected basemap
        let map = AGSMap(basemap: basemap)
        
        //add the selected operational layers
        if let layers = layers {
            map.operationalLayers.addObjectsFromArray(layers)
        }
        //assign the new map to the map view
        self.mapView.map = map
        
        //hide the create options view
        self.toggleOptionsVC(toggleOn: false)
    }
    
    //MARK: - SaveMapVCDelegate
    
    func saveMapViewControllerDidCancel(saveAsViewController: SaveMapViewController) {
        self.toggleSaveMapVC(toggleOn: false)
    }
    
    func saveMapViewController(saveMapViewController: SaveMapViewController, didInitiateSaveWithTitle title: String, tags: [String], itemDescription: String?) {
        
        //set the initial viewpoint from map view
        self.mapView.map?.initialViewpoint = self.mapView.currentViewpointWithType(AGSViewpointType.CenterAndScale)
        
        self.mapView.exportImageWithCompletion { [weak self] (image:NSImage?, error:NSError?) -> Void in
            if let error = error {
                self?.showAlert("Error", informativeText: error.localizedDescription)
            }
            else {
                //crop the image from the center
                //also to cut on the size
                let croppedImage:NSImage? = image?.croppedImage(CGSize(width: 200, height: 200))
                
                self?.saveMap(title, tags: tags, itemDescription: itemDescription, thumbnail: croppedImage)
            }
        }
        
        //hide the input screen
        self.toggleSaveMapVC(toggleOn: false)
    }
    
    //MARK: - Actions
    
    @IBAction private func newAction(sender: AnyObject) {
        self.toggleOptionsVC(toggleOn: true)
    }
    
    @IBAction func saveAsAction(sender: AnyObject) {
        self.portal = AGSPortal(URL: NSURL(string: "https://www.arcgis.com")!, loginRequired: true)
        self.portal.loadWithCompletion { (error) -> Void in
            if let error = error {
                if error.code != NSUserCancelledError {
                    NSAlert(error: error).beginSheetModalForWindow(self.view.window!, completionHandler: nil)
                }
            }
            else {
                //get title etc
                self.toggleSaveMapVC(toggleOn: true)
            }
        }
    }
    
    //MARK: - Helper methods
    
    private func showAlert(messageText:String, informativeText:String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.beginSheetModalForWindow(self.view.window!, completionHandler: nil)
    }
}

extension NSImage {
    
    func croppedImage(size:CGSize) -> NSImage {
        //calculate rect based on input size
        let originX = (self.size.width - size.width)/2
        let originY = (self.size.height - size.height)/2
        
        let rect = CGRect(x: originX, y: originY, width: size.width, height: size.height)
        
        //crop image
        let croppedCGImage = CGImageCreateWithImageInRect(self.CGImageForProposedRect(nil, context: nil, hints: nil)!, rect)!
        let croppedImage = NSImage(CGImage: croppedCGImage, size: NSZeroSize)
        
        return croppedImage
    }
}
