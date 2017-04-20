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

class BasemapCollectionViewItem: NSCollectionViewItem {

    @IBOutlet var thumbnail:NSImageView!
    @IBOutlet var label:NSTextField!
    
    var portalItem:AGSPortalItem! {
        didSet {
            
            //label
            self.label.stringValue = portalItem.title
            
            //thumbnail
            if let image = portalItem.thumbnail?.image {
                self.thumbnail.image = image
            }
            else {
                //clear image for reused item
                self.thumbnail.image = nil
                
                //if the thumbnail is not already downloaded
                portalItem.thumbnail?.load { [weak self] (error: Error?) in
                    if let error = error {
                        print(error)
                    }
                    else {
                        self?.thumbnail.image = self?.portalItem.thumbnail?.image
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.wantsLayer = true
        self.view.layer?.borderColor = NSColor.black.cgColor
        self.view.layer?.borderWidth = 1
        
        self.thumbnail.layer?.borderColor = NSColor.black.cgColor
        self.thumbnail.layer?.borderWidth = 1
    }
    
}
