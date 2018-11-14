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

import XCTest
@testable import ArcGIS_Runtime_SDK_Samples

private let sample1 = Sample(name: "Sample 1", description: "", storyboardName: "", sourceFilenames: [])
private let sample2 = Sample(name: "Sample 2", description: "", storyboardName: "", sourceFilenames: [])
private let sample3 = Sample(name: "Sample 3", description: "", storyboardName: "", sourceFilenames: [])
private let sample4 = Sample(name: "Sample 4", description: "", storyboardName: "", sourceFilenames: [])
private let sample5 = Sample(name: "Sample 5", description: "", storyboardName: "", sourceFilenames: [])
private let sample6 = Sample(name: "Sample 6", description: "", storyboardName: "", sourceFilenames: [])

private let category1 = ArcGIS_Runtime_SDK_Samples.Category(name: "Category 1", samples: [sample1, sample2])
private let category2 = ArcGIS_Runtime_SDK_Samples.Category(name: "Category 2", samples: [sample3])
private let category3 = ArcGIS_Runtime_SDK_Samples.Category(name: "Category 3", samples: [sample4, sample5, sample6])

class SampleListViewControllerTests: XCTestCase {
    func testInit() {
        let sampleListVC = makeViewController()
        XCTAssertEqual(sampleListVC.categories, [])
        XCTAssertNil(sampleListVC.selectedCategory)
        XCTAssertNil(sampleListVC.selectedSample)
    }
    
    func testSettingCategoriesSelectsFirstCategory() {
        let sampleListVC = makeViewController()
        _ = sampleListVC.view
        
        sampleListVC.categories = [category1, category2, category3]
        
        XCTAssertEqual(sampleListVC.selectedCategory, category1)
        XCTAssertFalse(sampleListVC.isExpanded(category1))
    }
    
    func testSelectCategory() {
        let sampleListVC = makeViewController()
        _ = sampleListVC.view
        
        XCTAssertNil(sampleListVC.selectedCategory)
        
        sampleListVC.categories = [category1, category2, category3]
        sampleListVC.select(category3)
        
        XCTAssertEqual(sampleListVC.selectedCategory, category3)
        XCTAssertFalse(sampleListVC.isExpanded(category1))
    }
    
    func testSelectSample() {
        let sampleListVC = makeViewController()
        _ = sampleListVC.view
        
        XCTAssertNil(sampleListVC.selectedSample)
        
        sampleListVC.categories = [category1, category2, category3]
        sampleListVC.select(sample2)
        
        XCTAssertEqual(sampleListVC.selectedSample, sample2)
        XCTAssertTrue(sampleListVC.isExpanded(category1))
        
        sampleListVC.select(sample3)
        
        XCTAssertEqual(sampleListVC.selectedSample, sample3)
        XCTAssertTrue(sampleListVC.isExpanded(category2))
        // Test that the previously expanded category is still expanded.
        XCTAssertTrue(sampleListVC.isExpanded(category1))
        
        sampleListVC.select(sample6)
        
        XCTAssertEqual(sampleListVC.selectedSample, sample6)
        XCTAssertTrue(sampleListVC.isExpanded(category3))
        
        sampleListVC.select(sample4)
        
        XCTAssertEqual(sampleListVC.selectedSample, sample4)
        XCTAssertTrue(sampleListVC.isExpanded(category3))
    }
    
    func makeViewController() -> SampleListViewController {
        return NSStoryboard.main!.instantiateController(withIdentifier: "SampleListViewController") as! SampleListViewController
    }
}
