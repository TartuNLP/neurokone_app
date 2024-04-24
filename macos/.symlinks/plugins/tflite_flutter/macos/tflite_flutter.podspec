#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint tflite_flutter_plugin.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'tflite_flutter'
  s.version          = '0.1.0'
  s.summary          = 'TensorFlow Lite plugin for Flutter apps.'
  s.description      = <<-DESC
TensorFlow Lite plugin for Flutter apps.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.osx.dependency 'FlutterMacOS'
  s.osx.deployment_target = '10.15'
  s.platform = :osx, '10.15'
  
  s.dependency 'TensorFlowLiteSwift'
  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
