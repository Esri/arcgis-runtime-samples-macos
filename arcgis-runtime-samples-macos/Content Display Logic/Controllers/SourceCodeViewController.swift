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

class SourceCodeViewController: NSViewController {
    @IBOutlet var popUpButton: NSPopUpButton!
    @IBOutlet var webView: WKWebView!
    
    var fileNames = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //load the source code
        if let fileName = fileNames.first {
            loadHTMLPage(fileName)
        }
        
        //populate popUpButton
        popUpButton.addItems(withTitles: fileNames)
    }
    
    //MARK: - HTML logic
    
    func loadHTMLPage(_ filename:String) {
        if let content = self.contentOfFile(filename) {
            let htmlString = self.htmlStringForContent(content)
            webView?.loadHTMLString(htmlString, baseURL: Bundle.main.bundleURL)
        }
    }
    
    func contentOfFile(_ name:String) -> String? {
        //find the path of the file
        if let path = Bundle.main.path(forResource: name, ofType: ".swift") {
            //read the content of the file
            if let content = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
                return content
            }
        }
        return nil
    }
    
    func htmlStringForContent(_ content:String) -> String {
        let cssPath = Bundle.main.path(forResource: "xcode", ofType: "css") ?? ""
        let jsPath = Bundle.main.path(forResource: "highlight.pack", ofType: "js") ?? ""
        let scale = "1.0"
        let stringForHTML = """
            <html>
            <head>
                <meta name='viewport' content='width=device-width, initial-scale='\(scale)'/>
                <link rel="stylesheet" href="\(cssPath)">
                <script src="\(jsPath)"></script>
                <script>hljs.initHighlightingOnLoad();</script>
            </head>
            <body>
                <pre><code class="Swift">\(content)</code></pre>
            </body>
            </html>
            """
        return stringForHTML
    }
    
    //MARK: - Actions
    
    @IBAction func popUpButtonAction(_ sender: AnyObject) {
        let filename = popUpButton.titleOfSelectedItem!
        self.loadHTMLPage(filename)
    }
}
