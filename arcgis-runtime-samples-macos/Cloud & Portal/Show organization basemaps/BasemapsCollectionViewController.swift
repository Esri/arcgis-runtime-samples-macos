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

protocol BasemapsCollectionVCDelegate:class {
    
    func basemapsCollectionViewController(_ basemapsCollectionViewController:BasemapsCollectionViewController, didSelectBasemap basemap:AGSBasemap)
}

class BasemapsCollectionViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate {

    @IBOutlet private var collectionView:NSCollectionView!
    
    var portal:AGSPortal!
    weak var delegate:BasemapsCollectionVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.fetchBasemaps()
    }
    
    private func fetchBasemaps() {
        
        //show progress indicator
        NSApplication.shared().keyWindow?.showProgressIndicator()
        
        BasemapHelper.shared.fetchBasemaps(from: self.portal) { [weak self] (error:Error?) in
            
            //hide progress indicator
            NSApplication.shared().keyWindow?.hideProgressIndicator()
            
            if let error = error {
                print(error)
            }
            else {
                self?.collectionView.reloadData()
            }
        }
    }
    
    //MARK: - NSCollectionViewDataSource
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        
        //if there are more basemaps available to download, keep an extra cell
        if let _ = BasemapHelper.shared.resultSet?.nextQueryParameters {
            return BasemapHelper.shared.basemaps.count + 1
        }
        else {
            return BasemapHelper.shared.basemaps?.count ?? 0
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        //special cell to provide feedback that more basemaps are available
        if indexPath.item == BasemapHelper.shared.basemaps.count {
            
            let item = collectionView.makeItem(withIdentifier: "BasemapCollectionViewItem", for: indexPath) as! BasemapCollectionViewItem
            
            item.label.stringValue = "More basemaps"
            item.thumbnail.image = nil
            
            return item
        }
        else {
            let item = collectionView.makeItem(withIdentifier: "BasemapCollectionViewItem", for: indexPath) as! BasemapCollectionViewItem
            
            item.portalItem = BasemapHelper.shared.basemaps[indexPath.item]
            
            return item
        }
    }
    
    //MARK: - NSCollectionViewDelegate
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        
        let indexPath = indexPaths.first!
        
        //if the special plus cell is selected, fetch more basemaps from the portal
        if indexPath.item == BasemapHelper.shared.basemaps.count {
            
            //show progress indicator
            NSApplication.shared().keyWindow?.showProgressIndicator()
            
            BasemapHelper.shared.fetchMoreBasemaps { [weak self] (error: Error?) in
                
                //hide progress indicator
                NSApplication.shared().keyWindow?.hideProgressIndicator()
                
                if let error = error {
                    print(error)
                }
                else {
                    self?.collectionView.reloadData()
                }
            }
        }
        else {
            
            let portalItem = BasemapHelper.shared.basemaps[indexPath.item]
            let basemap = AGSBasemap(item: portalItem)
            
            self.delegate?.basemapsCollectionViewController(self, didSelectBasemap: basemap)
        }
    }
}
