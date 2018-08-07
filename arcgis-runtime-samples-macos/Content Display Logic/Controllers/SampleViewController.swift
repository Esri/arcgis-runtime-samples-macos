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

class SampleViewController: NSTabViewController {
    let sample: Node
    
    init(sample: Node) {
        self.sample = sample
        
        super.init(nibName: nil, bundle: nil)
        
        let sampleStoryboard = NSStoryboard(name: NSStoryboard.Name(sample.storyboardName), bundle: nil)
        let sampleViewController = sampleStoryboard.instantiateInitialController() as! NSViewController
        let sampleTabViewItem = NSTabViewItem(viewController: sampleViewController)
        sampleTabViewItem.label = "Live Sample"
        addTabViewItem(sampleTabViewItem)
        
        let mainStoryboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        
        let sourceCodeViewController = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("SourceCodeViewController")) as! SourceCodeViewController
        sourceCodeViewController.fileNames = sample.sourceFileNames
        let sourceCodeTabViewItem = NSTabViewItem(viewController: sourceCodeViewController)
        sourceCodeTabViewItem.label = "Source Code"
        addTabViewItem(sourceCodeTabViewItem)
        
        let readmeViewController = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("ReadmeViewController")) as! ReadmeViewController
        readmeViewController.folderName = sample.displayName
        let readmeTabViewItem = NSTabViewItem(viewController: readmeViewController)
        readmeTabViewItem.label = "Description"
        addTabViewItem(readmeTabViewItem)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .windowBackgroundColor
    }
}
