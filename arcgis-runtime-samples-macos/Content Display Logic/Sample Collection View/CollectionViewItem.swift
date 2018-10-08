//
// Copyright © 2018 Esri.
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

import AppKit

class CollectionViewItem: NSCollectionViewItem {
    @IBOutlet var titleTextField: NSTextField!
    @IBOutlet var descriptionTextField: NSTextField!
    @IBOutlet var thumbnailView: NSImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        thumbnailView.wantsLayer = true
        thumbnailView.layer?.borderColor = NSColor.lightGray.cgColor
        thumbnailView.layer?.borderWidth = 1
        thumbnailView.layer?.cornerRadius = 5
    }
}

class CollectionViewItemHeaderView: NSView {
    @IBOutlet var textField: NSTextField! {
        didSet {
            if #available(OSX 10.14, *) {
                textField.appearance = NSAppearance(named: .darkAqua)
            }
        }
    }
    
    override func updateLayer() {
        layer?.backgroundColor = NSColor.appBlue.cgColor
    }
}

class CollectionViewItemView: NSView {
    override func updateLayer() {
        guard let layer = layer else { return }
        layer.backgroundColor = NSColor.textBackgroundColor.cgColor
        layer.borderColor = NSColor.appBlue.cgColor
        layer.cornerRadius = 10
        layer.borderWidth = 1
    }
}

private extension NSColor {
    static var appBlue: NSColor {
        if #available(OSX 10.14, *) {
            switch NSAppearance.current.bestMatch(from: [.aqua, .darkAqua]) {
            case .darkAqua?:
                return .secondaryBlue
            default:
                return .primaryBlue
            }
        } else {
            return .primaryBlue
        }
    }
}
