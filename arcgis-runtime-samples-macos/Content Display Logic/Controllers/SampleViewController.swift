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

class SampleViewController: NSViewController {
    @IBOutlet private var liveSampleSegmentedControl: NSSegmentedControl!
    @IBOutlet private var containerView: NSView!
    
    private let sampleViewController: NSViewController
    private let sourceCodeViewController: SourceCodeViewController
    private let readmeViewController: ReadmeViewController
    
    private enum Item: Int, Equatable {
        case sample
        case sourceCode
        case readme
    }
    
    private var selectedItem = Item.sample {
        didSet {
            guard selectedItem != oldValue else { return }
            selectedItemDidChange()
        }
    }
    
    let sample: Node
    
    init(sample: Node) {
        self.sample = sample
        
        sampleViewController = {
            let sampleStoryboard = NSStoryboard(name: NSStoryboard.Name(sample.storyboardName), bundle: nil)
            return sampleStoryboard.instantiateInitialController() as! NSViewController
        }()
        let mainStoryboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        sourceCodeViewController = {
            let viewController = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("SourceCodeViewController")) as! SourceCodeViewController
            viewController.fileNames = sample.sourceFileNames
            return viewController
        }()
        readmeViewController = {
            let viewController = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("ReadmeViewController")) as! ReadmeViewController
            viewController.folderName = sample.displayName
            return viewController
        }()
        
        super.init(nibName: NSNib.Name("SampleViewController"), bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sampleView = sampleViewController.view
        sampleView.autoresizingMask = [.width, .height]
        sampleView.frame = containerView.bounds
        containerView.addSubview(sampleView)
        addChildViewController(sampleViewController)
    }
    
    private func selectedItemDidChange() {
        let fromViewController = childViewControllers.first!
        let toViewController = viewController(for: selectedItem)
        
        addChildViewController(toViewController)
        transition(from: fromViewController, to: toViewController, options: .crossfade) {
            fromViewController.removeFromParentViewController()
        }
    }
    
    private func viewController(for item: Item) -> NSViewController {
        switch item {
        case .sample:
            return sampleViewController
        case .sourceCode:
            return sourceCodeViewController
        case .readme:
            return readmeViewController
        }
    }
    
    @IBAction func segmentedControlDidChangeSelection(_ sender: NSSegmentedControl) {
        guard let item = Item(rawValue: sender.selectedSegment) else { return }
        selectedItem = item
    }
}
