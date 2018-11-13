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

    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var optionsContainerView: NSView!
    @IBOutlet var saveMapContainerView: NSView!
    
    private var portal: AGSPortal!
    private var saveMapVC: SaveMapViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        //Auth Manager settings
        let config = AGSOAuthConfiguration(portalURL: nil, clientID: "vVHDSfKfdKBs8lkA", redirectURL: nil)
        AGSAuthenticationManager.shared().oAuthConfigurations.add(config)
        AGSAuthenticationManager.shared().credentialCache.removeAllCredentials()
        
        //initialize map to imagery basemap for the blur background
        let map = AGSMap(basemap: .imagery())
        
        //assign the map to the map view
        self.mapView.map = map
        
        //for visual effect view to work
        self.view.wantsLayer = true
    }
    
    // MARK: - Save map
    
    private func saveMap(_ title: String, tags: [String], itemDescription: String?, thumbnail: NSImage?) {
        self.mapView.map?.save(as: title, portal: self.portal!, tags: tags, folder: nil, itemDescription: itemDescription!, thumbnail: thumbnail, forceSaveToSupportedVersion: true) { [weak self] (error) -> Void in
            
            if let error = error {
                self?.showAlert(messageText: "Error", informativeText: error.localizedDescription)
            }
            else {
                self?.showAlert(messageText: "Info", informativeText: "Map was saved successfully")
            }
            
            //reset fields in save map view controller
            self?.saveMapVC.resetInputFields()
        }
    }
    
    // MARK: - Show/hide options view controller
    
    private func toggleOptionsVC(on: Bool) {
        self.optionsContainerView.isHidden = !on
    }
    
    // MARK: - Show/hide save map view controller
    
    private func toggleSaveMapVC(on: Bool) {
        self.saveMapContainerView.isHidden = !on
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let id = segue.identifier else {
            return
        }
        if id == "OptionsVCSegue" {
            let controller = segue.destinationController as! CreateOptionsViewController
            controller.delegate = self
        }
        else if id == "SaveMapVCSegue" {
            self.saveMapVC = segue.destinationController as? SaveMapViewController
            self.saveMapVC.delegate = self
        }
    }
    
    // MARK: - CreateOptionsVCDelegate
    
    func createOptionsViewController(_ createOptionsViewController: CreateOptionsViewController, didSelectBasemap basemap: AGSBasemap, layers: [AGSLayer]?) {
        
        //create a map with the selected basemap
        let map = AGSMap(basemap: basemap)
        
        //add the selected operational layers
        if let layers = layers {
            map.operationalLayers.addObjects(from: layers)
        }
        //assign the new map to the map view
        self.mapView.map = map
        
        //hide the create options view
        self.toggleOptionsVC(on: false)
    }
    
    // MARK: - SaveMapVCDelegate
    
    func saveMapViewControllerDidCancel(_ saveAsViewController: SaveMapViewController) {
        self.toggleSaveMapVC(on: false)
    }
    
    func saveMapViewController(_ saveMapViewController: SaveMapViewController, didInitiateSaveWithTitle title: String, tags: [String], itemDescription: String?) {
        
        //set the initial viewpoint from map view
        self.mapView.map?.initialViewpoint = self.mapView.currentViewpoint(with: AGSViewpointType.centerAndScale)
        
        self.mapView.exportImage { [weak self] (image: NSImage?, error: Error?) -> Void in
            if let error = error {
                self?.showAlert(messageText: "Error", informativeText: error.localizedDescription)
            }
            else {
                //crop the image from the center
                //also to cut on the size
                let croppedImage: NSImage? = image?.croppedImage(of: CGSize(width: 200, height: 200))
                
                self?.saveMap(title, tags: tags, itemDescription: itemDescription, thumbnail: croppedImage)
            }
        }
        
        //hide the input screen
        self.toggleSaveMapVC(on: false)
    }
    
    // MARK: - Actions
    
    @IBAction private func newAction(_ sender: AnyObject) {
        self.toggleOptionsVC(on: true)
    }
    
    @IBAction func saveAsAction(_ sender: AnyObject) {
        self.portal = AGSPortal(url: URL(string: "https://www.arcgis.com")!, loginRequired: true)
        self.portal.load { (error) -> Void in
            if let error = error {
                if (error as NSError).code != NSUserCancelledError {
                    NSAlert(error: error).beginSheetModal(for: self.view.window!)
                }
            }
            else {
                //get title etc
                self.toggleSaveMapVC(on: true)
            }
        }
    }
    
    // MARK: - Helper methods
    
    private func showAlert(messageText: String, informativeText: String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.beginSheetModal(for: self.view.window!)
    }
}

extension NSImage {
    
    func croppedImage(of size: CGSize) -> NSImage {
        //calculate rect based on input size
        let originX = (self.size.width - size.width) / 2
        let originY = (self.size.height - size.height) / 2
        
        let rect = CGRect(x: originX, y: originY, width: size.width, height: size.height)
        
        //crop image
        let croppedCGImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil)!.cropping(to: rect)!
        let croppedImage = NSImage(cgImage: croppedCGImage, size: .zero)
        
        return croppedImage
    }
}
