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

import ArcGIS

extension AGSAnalysisOverlay {
    /// Creates an analysis overlay with the given analyses.
    ///
    /// - Parameter analyses: A sequence of `AGSAnalysis` objects.
    convenience init<S: Sequence>(analyses: S) where S.Element == AGSAnalysis {
        self.init()
        self.analyses.addObjects(from: Array(analyses))
    }
}
