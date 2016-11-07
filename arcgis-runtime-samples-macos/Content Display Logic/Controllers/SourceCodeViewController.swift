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
import WebKit

class SourceCodeViewController: NSViewController, NSSearchFieldDelegate {

    @IBOutlet var popUpButton:NSPopUpButton!
    @IBOutlet var webView:WebView!
    @IBOutlet var searchField: NSSearchField!
    @IBOutlet var noResultLabel: NSTextField!
    
    var fileNames:[String]! {
        didSet {
            //load the source code
            if self.fileNames != nil && self.fileNames.count > 0 {
                self.loadHTMLPage(self.fileNames[0])
            }
            
            //populate popUpButton
            self.popUpButton.addItemsWithTitles(self.fileNames)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    //MARK: - HTML logic
    
    func loadHTMLPage(filename:String) {
        if let content = self.contentOfFile(filename) {
            let htmlString = self.htmlStringForContent(content)
            self.webView.mainFrame.loadHTMLString(htmlString, baseURL: NSURL(fileURLWithPath: NSBundle.mainBundle().bundlePath))
        }
    }
    
    func contentOfFile(name:String) -> String? {
        //find the path of the file
        if let path = NSBundle.mainBundle().pathForResource(name, ofType: ".swift") {
            //read the content of the file
            if let content = try? String(contentsOfFile: path, encoding: NSUTF8StringEncoding) {
                return content
            }
        }
        return nil
    }
    
    func htmlStringForContent(content:String) -> String {
        let cssPath = NSBundle.mainBundle().pathForResource("xcode", ofType: "css") ?? ""
        let jsPath = NSBundle.mainBundle().pathForResource("highlight.pack", ofType: "js") ?? ""
//        let scale  = UIDevice.currentDevice().userInterfaceIdiom == .Phone ? "0.5" : "1.0"
        let scale = "1.0"
        let stringForHTML = "<html> <head>" +
            "<meta name='viewport' content='width=device-width, initial-scale='\(scale)'/> " +
            "<link rel=\"stylesheet\" href=\"\(cssPath)\">" +
            "<script src=\"\(jsPath)\"></script>" +
            "<script>hljs.initHighlightingOnLoad();</script> </head> <body>" +
            "<pre><code class=\"Swift\"> \(content) </code></pre>" +
        "</body> </html>"
        //        println(stringForHTML)
        // style=\"white-space:initial;\"
        return stringForHTML
    }
    
    //MARK: - Actions
    
    @IBAction func popUpButtonAction(sender: AnyObject) {
        let filename = popUpButton.titleOfSelectedItem!
        self.loadHTMLPage(filename)
    }
    
    @IBAction func search(sender: AnyObject) {
        if self.searchField.stringValue.isEmpty {
            return
        }
        
        let success = self.webView.searchFor(self.searchField.stringValue, direction: true, caseSensitive: false, wrap: true)
        
        if !success {
            //show no result label
            self.noResultLabel.hidden = false
        }
    }
    
    //MARK: - NSSearchField delegate
    
    override func controlTextDidChange(notification: NSNotification) {
        if let sender = notification.object as? NSSearchField where sender == self.searchField {
            //hide no results label if visible
            self.noResultLabel.hidden = true
        }
    }
}
