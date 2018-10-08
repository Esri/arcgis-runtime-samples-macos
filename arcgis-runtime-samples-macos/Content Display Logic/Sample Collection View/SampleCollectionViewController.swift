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

protocol SampleCollectionViewControllerDelegate: AnyObject {
    func sampleCollectionViewController(_ controller: SampleCollectionViewController, didSelect sample: Sample)
}

class SampleCollectionViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate {
    @IBOutlet var collectionView: NSCollectionView!
    @IBOutlet var collectionViewLayout: NSCollectionViewFlowLayout!
    
    weak var delegate: SampleCollectionViewControllerDelegate?
    
    let samples: [Sample]
    
    init<S: Sequence>(samples: S) where S.Element == Sample {
        self.samples = Array(samples)
        super.init(nibName: "SampleCollectionViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.register(NSNib(nibNamed: "SampleCollectionSectionHeaderView", bundle: nil), forSupplementaryViewOfKind: NSCollectionView.elementKindSectionHeader, withIdentifier: .headerView)
        collectionViewLayout.sectionHeadersPinToVisibleBounds = true
    }
    
    //MARK: - NSCollectionViewDataSource
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return samples.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        let sample = samples[indexPath.item]
        
        let viewItem = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("CollectionViewItem"), for: indexPath) as! CollectionViewItem
        viewItem.titleTextField.stringValue = sample.name
        viewItem.descriptionTextField.stringValue = sample.description
        viewItem.thumbnailView.image = NSImage(named: sample.name)
        
        return viewItem
    }
    
    func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
        let headerView = collectionView.makeSupplementaryView(ofKind: kind, withIdentifier: .headerView, for: indexPath) as! SampleCollectionSectionHeaderView
        headerView.label.stringValue = {
            if !samples.isEmpty {
                return "\(samples.count) sample(s)"
            } else {
                return "No samples found"
            }
        }()
        return headerView
    }
    
    //MARK: - NSCollectionViewDelegate
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        delegate?.sampleCollectionViewController(self, didSelect: samples[indexPaths.first!.item])
    }
}

private extension NSUserInterfaceItemIdentifier {
    static let headerView = NSUserInterfaceItemIdentifier("HeaderView")
}
