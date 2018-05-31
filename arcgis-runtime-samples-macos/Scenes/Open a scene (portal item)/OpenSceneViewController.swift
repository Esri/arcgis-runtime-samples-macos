// Copyright 2018 Esri.
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

class OpenSceneViewController: NSViewController {
    var sceneView: AGSSceneView {
        return view as! AGSSceneView
    }
    
    let portal = AGSPortal.arcGISOnline(withLoginRequired: false)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the portal item.
        let portalItem = AGSPortalItem(portal: portal, itemID: "a13c3c3540144967bc933cb5e498b8e4")
        // Create scene from portal item.
        let scene = AGSScene(item: portalItem)
        // Set the scene.
        sceneView.scene = scene
    }
    
}
