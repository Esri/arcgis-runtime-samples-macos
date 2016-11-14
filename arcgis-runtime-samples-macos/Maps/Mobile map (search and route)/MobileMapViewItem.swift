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

class AspectFillImageView: NSView {
    
    @IBOutlet var image:NSImage! {
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
        self.layer?.contentsGravity = kCAGravityResizeAspectFill
        self.layer?.contents = image
        self.wantsLayer = true
    }
}

class MobileMapViewItem: NSCollectionViewItem {

    @IBOutlet var thumbnailView:AspectFillImageView!
    @IBOutlet var searchImageView:NSImageView!
    @IBOutlet var routeImageView:NSImageView!
    @IBOutlet var label:NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //cell view border
        self.view.wantsLayer = true
        self.view.layer?.borderColor = NSColor.grayColor().CGColor
        self.view.layer?.borderWidth = 1
        
        //thumbnailView border
        self.thumbnailView.layer?.borderColor = NSColor.lightGrayColor().CGColor
        self.thumbnailView.layer?.borderWidth = 1
    }
    
}
