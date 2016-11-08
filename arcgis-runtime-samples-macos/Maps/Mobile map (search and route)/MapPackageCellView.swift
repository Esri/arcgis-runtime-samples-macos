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
import ArcGIS

protocol MapPackageCellDelegate:class {
    
    func mapPackageCellView(mapPackageCellView:MapPackageCellView, didSelectMap map:AGSMap)
}

class MapPackageCellView: NSTableCellView, NSCollectionViewDataSource, NSCollectionViewDelegate {

    @IBOutlet var label:NSTextField!
    @IBOutlet var collectionView:NSCollectionView!
    @IBOutlet var collectionViewHeightConstraint:NSLayoutConstraint!
    
    weak var delegate: MapPackageCellDelegate?
    
    var cellOriginalHeight:CGFloat = 0
    
    var mapPackage:AGSMobileMapPackage! {
        didSet {
            self.loadMapPackage()
        }
    }
    
    func loadMapPackage() {
        
        //show progress indicator
        self.window?.showProgressIndicator()
        
        self.mapPackage.loadWithCompletion({ [weak self] (error:NSError?) in
            
            //hide progress indicator
            self?.window?.hideProgressIndicator()
            
            if let error = error {
                //error
                self?.showAlert("Error", informativeText: error.localizedDescription)
            }
            else {
                //update title label
                if let title = self?.mapPackage.item?.title {
                    self?.label.stringValue = title
                }
                
                self?.collectionView.reloadData()
            }
        })
    }
    
    //MARK: - NSCollectionViewDataSource
    
    func collectionView(collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.mapPackage?.maps.count ?? 0
    }
    
    func collectionView(collectionView: NSCollectionView, itemForRepresentedObjectAtIndexPath indexPath: NSIndexPath) -> NSCollectionViewItem {
        
        let item = collectionView.makeItemWithIdentifier("MobileMapViewItem", forIndexPath: indexPath) as! MobileMapViewItem
        
        let map = self.mapPackage.maps[indexPath.item]
        //label
        item.label.stringValue = "Map \(indexPath.item + 1)"
        
        //thumbnail
        item.thumbnailView.image = map.item?.thumbnail?.image
        
        //search image view
        item.searchImageView.hidden = (self.mapPackage.locatorTask == nil)
        
        //route image view
        item.routeImageView.hidden = (map.transportationNetworks.count == 0)
        
        return item
    }
    
    //MARK: - NSCollectionViewDelegate
    
    func collectionView(collectionView: NSCollectionView, didSelectItemsAtIndexPaths indexPaths: Set<NSIndexPath>) {
        let indexPath = indexPaths.first!
        let map = self.mapPackage.maps[indexPath.item]
        
        self.delegate?.mapPackageCellView(self, didSelectMap: map)
    }
    
    
    //MARK: - Helper methods
    
    private func showAlert(messageText:String, informativeText:String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.beginSheetModalForWindow(self.window!, completionHandler: nil)
    }
}
