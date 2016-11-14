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

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}

extension NSColor {
    class func primaryBlue() -> NSColor {
        return NSColor(red: 0, green: 0.475, blue: 0.757, alpha: 1)
    }
    
    class func secondaryBlue() -> NSColor {
        return NSColor(red: 0, green: 0.368, blue: 0.584, alpha: 1)
    }
    
    class func backgroundGray() -> NSColor {
        return NSColor(red: 0.973, green: 0.973, blue: 0.973, alpha: 1)
    }
}

