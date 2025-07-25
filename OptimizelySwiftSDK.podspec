Pod::Spec.new do |s|
  s.name                    = "OptimizelySwiftSDK"
  s.module_name	            = "Optimizely"
  s.version                 = "5.1.1"
  s.summary                 = "Optimizely experiment framework for iOS/tvOS/watchOS"
  s.homepage                = "https://docs.developers.optimizely.com/experimentation/v4.0.0-full-stack/docs"
  s.license                 = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  s.author                  = { "Optimizely" => "support@optimizely.com" }
  s.ios.deployment_target   = "10.0"
  s.tvos.deployment_target  = "10.0"
  s.osx.deployment_target  = "10.14"
  s.watchos.deployment_target = "3.0"
  s.source                  = {
    :git => "https://github.com/optimizely/swift-sdk.git",
    :tag => "v"+s.version.to_s
  }
  s.source_files            = "Sources/**/*.swift"
  s.resource_bundles        = { 'OptimizelySwiftSDK' => ['Sources/Supporting Files/PrivacyInfo.xcprivacy'] }
  s.swift_version           = ["5.0", "5.1"]
  s.framework               = "Foundation"
  s.requires_arc            = true
  s.xcconfig                = { 'GCC_PREPROCESSOR_DEFINITIONS' => "OPTIMIZELY_SDK_VERSION=@\\\"#{s.version}\\\"" }
end
