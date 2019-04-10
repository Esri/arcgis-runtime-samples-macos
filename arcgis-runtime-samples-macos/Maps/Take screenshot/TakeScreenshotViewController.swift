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

class TakeScreenshotViewController: NSViewController {
    @IBOutlet private weak var mapView: AGSMapView!
    @IBOutlet private weak var overlayParentView: NSVisualEffectView!
    @IBOutlet private weak var overlayImageView: AspectFillImageView!
    
    var map: AGSMap!
    
    var shutterSound: SystemSoundID = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //instantiate map with imagegry basemap
        self.map = AGSMap(basemap: .imagery())
        
        //assign the map to the map view
        self.mapView.map = self.map
    }
    
    // MARK: - Actions
    
    //hide the screenshot overlay view
    func hideOverlayParentView() {
        self.overlayParentView.isHidden = true
    }
    
    //show the screenshot overlay view
    private func showOverlayParentView() {
        self.overlayParentView.isHidden = false
    }
    
    //called when the user taps on the screenshot button
    @IBAction private func screenshotAction(_ sender: AnyObject) {
        //hide the screenshot view if currently visible
        self.hideOverlayParentView()
        
        //show progress indicator
        NSApp.showProgressIndicator()
        
        //the method on map view we can use to get the screenshot image
        self.mapView.exportImage { [weak self] (image: NSImage?, error: Error?) in
            //hide progress indicator
            NSApp.hideProgressIndicator()
            
            if let error = error {
                self?.showAlert("Error", informativeText: error.localizedDescription)
            }
            if let image = image {
                //on completion imitate flash
                self?.imitateFlashAndPreview(image: image)
            }
        }
    }
    
    @IBAction private func closeAction(_ sender: NSButton) {
        self.hideOverlayParentView()
    }
    
    // MARK: - Helper methods
    
    //imitate the white flash screen when the user taps on the screenshot button
    private func imitateFlashAndPreview(image: NSImage) {
        let flashView = NSView(frame: self.mapView.bounds)
        flashView.wantsLayer = true
        flashView.layer?.backgroundColor = NSColor.white.cgColor
        self.mapView.addSubview(flashView)
        
        //animate the white flash view on and off to show the flash effect
        NSAnimationContext.runAnimationGroup({ (context: NSAnimationContext) in
            context.duration = 0.3
            flashView.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            //On completion play the shutter sound
            self?.playShutterSound()
            flashView.removeFromSuperview()
            //show the screenshot on screen
            self?.overlayImageView.image = image
            self?.showOverlayParentView()
        })
    }
    
    //to play the shutter sound once the screenshot is taken
    func playShutterSound() {
        if self.shutterSound == 0 {
            if let filepath = Bundle.main.path(forResource: "Camera Shutter", ofType: "caf") {
                let url = URL(fileURLWithPath: filepath)
                AudioServicesCreateSystemSoundID(url as CFURL, &self.shutterSound)
            }
        }
        
        AudioServicesPlaySystemSound(self.shutterSound)
    }
    
    deinit {
        AudioServicesDisposeSystemSoundID(self.shutterSound)
    }
    
    private func showAlert(_ messageText: String, informativeText: String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.beginSheetModal(for: self.view.window!)
    }
}

class AspectFillImageView: NSView {
    @IBOutlet var image: NSImage! {
        didSet {
            self.layer?.contents = image
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func commonInit() {
        self.layer = CALayer()
        self.layer?.contentsGravity = .resizeAspectFill
        self.layer?.contents = image
        self.wantsLayer = true
    }
}
