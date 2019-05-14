#!/bin/bash
TEST_VAR=":blush:"
oldName="$1"
newName="$2"
swift_code() {
cat<<EOF
import Foundation

  let fs = FileManager.default
        
  let data = fs.contents(atPath: "../OptimizelySDK/Utils/OptimizelySDKVersion.swift")
        
  let str = String(data: data!, encoding: .utf8)
        
  let newStr = str!.replacingOccurrences(of: "$oldName", with: "$newName")

  try newStr.write(to: URL(fileURLWithPath: "../OptimizelySDK/Utils/OptimizelySDKVersion.swift"), atomically: true, encoding: .utf8)
 
EOF
}
echo "$(swift_code)" | swift -
