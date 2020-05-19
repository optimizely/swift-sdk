Pod::Spec.new do |s|
  s.name                    = "OptimizelySwiftSDK"
  s.module_name	            = "Optimizely"
  s.version                 = "3.3.0"
  s.summary                 = "Optimizely experiment framework for iOS/tvOS"
  s.homepage                = "https://docs.developers.optimizely.com/full-stack/docs"
  s.license                 = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  s.author                  = { "Optimizely" => "support@optimizely.com" }
  s.ios.deployment_target   = "10.0"
  s.tvos.deployment_target  = "10.0"
  s.source                  = {
    :git => "https://github.com/optimizely/swift-sdk.git",
    :tag => "v"+s.version.to_s
  }
  s.source_files            = "Sources/**/*.swift"
  # OptimizelyDebugger log database
  s.resource_bundles        = {"Optimizely" => "Sources/OptimizelyDebugger/LogModel.xcdatamodeld"}
  
  s.swift_version           = ["5.0", "5.1"]
  s.framework               = "Foundation"
  s.requires_arc            = true
  s.xcconfig                = { 'GCC_PREPROCESSOR_DEFINITIONS' => "OPTIMIZELY_SDK_VERSION=@\\\"#{s.version}\\\"" }
end

