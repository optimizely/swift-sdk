Pod::Spec.new do |s|
  s.name                    = "OptimizelySwiftSDK"
  s.module_name	            = "Optimizely"
  s.version                 = "3.1.0-beta"
  s.summary                 = "Optimizely server-side testing core framework."
  s.homepage                = "http://developers.optimizely.com/server/reference/index.html?language=objectivec"
  s.license                 = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  s.author                  = { "Optimizely" => "support@optimizely.com" }
  s.ios.deployment_target   = "9.0"
  s.tvos.deployment_target  = "9.0"
  s.source                  = {
    :git => "https://github.com/optimizely/swift-sdk.git",
    :tag => "v"+s.version.to_s
  }
  s.source_files            = "Sources/**/*.swift"
  s.public_header_files     = "Sources/**/*.h"
  s.swift_version           = "4.2"
  s.framework               = "Foundation"
  s.requires_arc            = true
  s.xcconfig                = { 'GCC_PREPROCESSOR_DEFINITIONS' => "OPTIMIZELY_SDK_VERSION=@\\\"#{s.version}\\\"" }
end

