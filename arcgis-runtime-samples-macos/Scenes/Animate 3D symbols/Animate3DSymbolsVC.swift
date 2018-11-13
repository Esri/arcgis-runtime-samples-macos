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

import Cocoa
import ArcGIS

class Animate3DSymbolsVC: NSViewController {

    @IBOutlet var sceneView: AGSSceneView!
    @IBOutlet var popUpButton: NSPopUpButton!
    @IBOutlet var speedSlider: NSSlider!
    @IBOutlet var progressIndicator: NSProgressIndicator!
    @IBOutlet var playButton: NSButton!
    
    @IBOutlet var headingOffsetSlider: NSSlider!
    @IBOutlet var pitchOffsetSlider: NSSlider!
    @IBOutlet var distanceSlider: NSSlider!
    @IBOutlet var distanceLabel: NSTextField!
    @IBOutlet var headingOffsetLabel: NSTextField!
    @IBOutlet var pitchOffsetLabel: NSTextField!
    @IBOutlet var autoHeadingEnabledButton: NSButton!
    @IBOutlet var autoPitchEnabledButton: NSButton!
    @IBOutlet var autoRollEnabledButton: NSButton!
    
    @IBOutlet var altitiudeLabel: NSTextField!
    @IBOutlet var headingLabel: NSTextField!
    @IBOutlet var pitchLabel: NSTextField!
    @IBOutlet var rollLabel: NSTextField!
    
    private var sceneGraphicsOverlay = AGSGraphicsOverlay()
    private var frames: [Frame]!
    private var fileNames: [String]!
    private var planeModelSymbol: AGSModelSceneSymbol!
    private var planeModelGraphic: AGSGraphic!
    private var currentFrameIndex = 0
    private var animationTimer: Timer!
    private var orbitGeoElementCameraController: AGSOrbitGeoElementCameraController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initalize scene with imagery basemap
        let scene = AGSScene(basemap: .imagery())
        
        //assign scene to scene view
        self.sceneView.scene = scene
        
        /// The url of the Terrain 3D ArcGIS REST Service.
        let worldElevationServiceURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
        //elevation source
        let elevationSource = AGSArcGISTiledElevationSource(url: worldElevationServiceURL)
        
        //surface
        let surface = AGSSurface()
        surface.elevationSources.append(elevationSource)
        scene.baseSurface = surface
        
        //graphics overlay for scene view
        self.sceneGraphicsOverlay.sceneProperties?.surfacePlacement = .absolute
        sceneView.graphicsOverlays.add(self.sceneGraphicsOverlay)
        
        //renderer for scene graphics overlay
        let renderer = AGSSimpleRenderer()
        
        //expressions
        renderer.sceneProperties?.headingExpression = "[HEADING]"
        renderer.sceneProperties?.pitchExpression = "[PITCH]"
        renderer.sceneProperties?.rollExpression = "[ROLL]"
        
        //set renderer on the overlay
        self.sceneGraphicsOverlay.renderer = renderer
        
        //populate pop up button with mission files
        self.populatePopUpButton()
        
        //add the plane model
        self.addPlane3D()
        
        //setup camera to follow the plane
        self.setupCamera()
        
        //select the first mission by default
        self.changeMissionAction(self.popUpButton)
    }
    
    private func addPlane3D() {
        //model symbol
        self.planeModelSymbol = AGSModelSceneSymbol(name: "Bristol", extension: "dae", scale: 20)
        self.planeModelSymbol.anchorPosition = .center
        
        //arbitrary geometry for time being, the geometry will update with animation
        let point = AGSPoint(x: 0, y: 0, z: 0, spatialReference: AGSSpatialReference.wgs84())
        
        //create graphic for the model
        self.planeModelGraphic = AGSGraphic()
        self.planeModelGraphic.geometry = point
        self.planeModelGraphic.symbol = self.planeModelSymbol
        
        //add graphic to the graphics overlay
        self.sceneGraphicsOverlay.graphics.add(self.planeModelGraphic)
    }
    
    private func setupCamera() {
        
        //AGSOrbitGeoElementCameraController to follow plane graphic
        //initialize object specifying the target geo element and distance to keep from it
        self.orbitGeoElementCameraController = AGSOrbitGeoElementCameraController(targetGeoElement: self.planeModelGraphic, distance: 1000)
        
        //set camera to align its heading with the model
        self.orbitGeoElementCameraController.isAutoHeadingEnabled = true
        
        //will keep the camera still while the model pitches or rolls
        self.orbitGeoElementCameraController.isAutoPitchEnabled = false
        self.orbitGeoElementCameraController.isAutoRollEnabled = false
        
        //min and max distance values between the model and the camera
        self.orbitGeoElementCameraController.minCameraDistance = 500
        self.orbitGeoElementCameraController.maxCameraDistance = 8000
        
        //set the camera controller on scene view
        self.sceneView.cameraController = self.orbitGeoElementCameraController
        
        //add observers to update the sliders
        self.orbitGeoElementCameraController.addObserver(self, forKeyPath: "cameraDistance", options: .new, context: nil)
        self.orbitGeoElementCameraController.addObserver(self, forKeyPath: "cameraHeadingOffset", options: .new, context: nil)
        self.orbitGeoElementCameraController.addObserver(self, forKeyPath: "cameraPitchOffset", options: .new, context: nil)
    }
    
    private func populatePopUpButton() {
        
        if fileNames == nil,
            let resourcePath = Bundle.main.resourcePath,
            let content = try? FileManager.default.contentsOfDirectory(atPath: resourcePath) {
            
            //fetch csv file names in the bundle
            fileNames = content.filter { $0.lowercased().hasSuffix(".csv") }
        }
        
        //remove existing values
        self.popUpButton.removeAllItems()
        
        //add the filenames
        self.popUpButton.addItems(withTitles: self.fileNames)
    }

    private func loadMissionData(_ name: String) {
        
        //get the path of the specified file in the bundle
        if let path = Bundle.main.path(forResource: name, ofType: nil) {
            
            //get content of the file
            if let content = try? String(contentsOfFile: path) {
                
                //split content into array of lines separated by new line character
                //each line is one frame
                let lines = content.components(separatedBy: CharacterSet.newlines)
                
                //initialize array of frames
                var frames = [Frame]()
                
                //create a frame object for each line
                for line in lines {
                    let details = line.components(separatedBy: ",")
                    
                    //load position, heading, pitch and roll for each frame
                    let frame = Frame()
                    frame.position = AGSPoint(x: Double(details[0])!, y: Double(details[1])!, z: Double(details[2])!, spatialReference: AGSSpatialReference.wgs84())
                    frame.heading = Double(details[3])!
                    frame.pitch = Double(details[4])!
                    frame.roll = Double(details[5])!
                    
                    frames.append(frame)
                }
                
                self.frames = frames
            }
        }
        else {
            Swift.print("Mission file not found")
        }
    }
    
    private func startAnimation() {
        
        //invalidate timer to stop previous ongoing animation
        self.animationTimer?.invalidate()
        
        //duration or interval
        let duration = 1 / self.speedSlider.doubleValue
        
        //new timer
        self.animationTimer = Timer(timeInterval: duration, target: self, selector: #selector(animate), userInfo: nil, repeats: true)
        RunLoop.main.add(self.animationTimer, forMode: .common)
    }
    
    @objc func animate() {
        
        //validations
        if self.frames == nil || self.planeModelSymbol == nil {
            return
        }
        
        //if animation is complete
        if self.currentFrameIndex >= self.frames.count {
            
            //invalidate timer
            self.animationTimer?.invalidate()
            
            //change state of play button
            self.playButton.state = NSControl.StateValue.off
            
            //reset index
            self.currentFrameIndex = 0
            
            return
        }
        
        //else get the frame
        let frame = self.frames[self.currentFrameIndex]
        
        //update the properties on the model
        self.planeModelGraphic.geometry = frame.position
        self.planeModelGraphic.attributes["HEADING"] = frame.heading
        self.planeModelGraphic.attributes["PITCH"] = frame.pitch
        self.planeModelGraphic.attributes["ROLL"] = frame.roll
    
        //update progress
        self.progressIndicator.doubleValue = Double(self.currentFrameIndex) / Double(self.frames.count) * 100
        
        //update labels
        self.altitiudeLabel.stringValue = "\(Int(frame.position.z))"
        self.headingLabel.stringValue = "\(Int(frame.heading))º"
        self.pitchLabel.stringValue = "\(Int(frame.pitch))º"
        self.rollLabel.stringValue = "\(Int(frame.roll))º"
        
        //increment current frame index
        self.currentFrameIndex += 1
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        
        DispatchQueue.main.async { [weak self] in
        
            guard let weakSelf = self else {
                return
            }
            
            if keyPath == "cameraDistance" {
                weakSelf.distanceSlider.integerValue = Int(weakSelf.orbitGeoElementCameraController.cameraDistance)
                
                //update label
                weakSelf.distanceLabel.stringValue = "\(weakSelf.distanceSlider.integerValue)"
            }
            else if keyPath == "cameraHeadingOffset" {
                weakSelf.headingOffsetSlider.integerValue = Int(weakSelf.orbitGeoElementCameraController.cameraHeadingOffset)
                
                //update label
                weakSelf.headingOffsetLabel.stringValue = "\(weakSelf.headingOffsetSlider.integerValue)º"
            }
            else if keyPath == "cameraPitchOffset" {
                weakSelf.pitchOffsetSlider.integerValue = Int(weakSelf.orbitGeoElementCameraController.cameraPitchOffset)
                
                //update label
                weakSelf.pitchOffsetLabel.stringValue = "\(weakSelf.pitchOffsetSlider.integerValue)º"
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func changeMissionAction(_ sender: NSPopUpButton) {
        
        //invalidate timer
        self.animationTimer?.invalidate()
        
        //set play button state to off
        self.playButton.state = NSControl.StateValue.off
        
        //new mission name
        self.loadMissionData(sender.selectedItem!.title)
        
        //create a polyline from position in each frame to be used as path
        var points = [AGSPoint]()
        
        for frame in self.frames {
            points.append(frame.position)
        }
        
        //set current frame to zero
        self.currentFrameIndex = 0
        
        //animate to first frame
        self.animate()
    }
    
    @IBAction func distanceValueChanged(_ sender: NSSlider) {
        
        //update property
        self.orbitGeoElementCameraController.cameraDistance = sender.doubleValue
        
        //update label
        self.distanceLabel.stringValue = "\(sender.integerValue)"
    }
    
    @IBAction func headingOffsetValueChanged(_ sender: NSSlider) {
        
        //update property
        self.orbitGeoElementCameraController.cameraHeadingOffset = sender.doubleValue
        
        //update label
        self.headingOffsetLabel.stringValue = "\(sender.integerValue)º"
    }
    
    @IBAction func pitchOffsetValueChanged(_ sender: NSSlider) {
        
        //update property
        self.orbitGeoElementCameraController.cameraPitchOffset = sender.doubleValue
        
        //update label
        self.pitchOffsetLabel.stringValue = "\(sender.integerValue)º"
    }
    
    @IBAction func autoHeadingEnabledAction(_ sender: NSButton) {
        
        //update property
        self.orbitGeoElementCameraController.isAutoHeadingEnabled = (sender.state == NSControl.StateValue.on)
    }
    
    @IBAction func autoPitchEnabledAction(_ sender: NSButton) {
        
        //update property
        self.orbitGeoElementCameraController.isAutoPitchEnabled = (sender.state == NSControl.StateValue.on)
    }
    
    @IBAction func autoRollEnabledAction(_ sender: NSButton) {
        
        //update property
        self.orbitGeoElementCameraController.isAutoRollEnabled = (sender.state == NSControl.StateValue.on)
    }
    
    @IBAction func speedValueChanged(_ sender: NSSlider) {
        
        //if the animation is playing, invalidate the timer and 
        //start the animation for the speed to take effect
        //else do nothing
        if self.playButton.state == NSControl.StateValue.on {

            //invalidate previous timer
            self.animationTimer?.invalidate()
            
            //start new timer
            self.startAnimation()
        }
    }
    
    @IBAction func playAction(_ sender: NSButton) {
        
        //if the button is now in on state then start animation
        //else stop animation by invalidating the timer
        if sender.state == NSControl.StateValue.on {
            self.startAnimation()
        }
        else {
            self.animationTimer?.invalidate()
        }
    }
    
    deinit {
        //remove observers
        self.orbitGeoElementCameraController.removeObserver(self, forKeyPath: "cameraDistance")
        self.orbitGeoElementCameraController.removeObserver(self, forKeyPath: "cameraHeadingOffset")
        self.orbitGeoElementCameraController.removeObserver(self, forKeyPath: "cameraPitchOffset")
    }
}

class Frame {
    var position: AGSPoint!
    var heading: Double = 0.0
    var pitch: Double = 0.0
    var roll: Double = 0.0
}
