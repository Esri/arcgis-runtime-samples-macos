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
    let sample: Sample
    
    init(sample: Sample) {
        self.sample = sample
        
        super.init(nibName: nil, bundle: nil)
        
        let sampleStoryboard = NSStoryboard(name: sample.storyboardName, bundle: nil)
        let sampleViewController = sampleStoryboard.instantiateInitialController() as! NSViewController
        let sampleTabViewItem = NSTabViewItem(viewController: sampleViewController)
        sampleTabViewItem.label = "Live Sample"
        addTabViewItem(sampleTabViewItem)
        
        let mainStoryboard = NSStoryboard(name: "Main", bundle: nil)
        
        let sourceCodeViewController = mainStoryboard.instantiateController(withIdentifier: "SourceCodeViewController") as! SourceCodeViewController
        sourceCodeViewController.fileNames = sample.sourceFilenames
        let sourceCodeTabViewItem = NSTabViewItem(viewController: sourceCodeViewController)
        sourceCodeTabViewItem.label = "Source Code"
        addTabViewItem(sourceCodeTabViewItem)
        
        let readmeViewController = mainStoryboard.instantiateController(withIdentifier: "ReadmeViewController") as! ReadmeViewController
        readmeViewController.folderName = sample.name
        let readmeTabViewItem = NSTabViewItem(viewController: readmeViewController)
        readmeTabViewItem.label = "Description"
        addTabViewItem(readmeTabViewItem)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layerBackgroundColor = .windowBackgroundColor
    }
}
