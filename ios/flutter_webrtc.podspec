#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flutter_webrtc'
  s.version          = '0.2.2'
  s.summary          = 'Flutter WebRTC plugin for iOS.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'https://github.com/cloudwebrtc/flutter-webrtc'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'CloudWebRTC' => 'duanweiwei1982@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'Libyuv', '1703'
  s.ios.deployment_target = '10.0'
  s.static_framework = true
  s.vendored_frameworks = ["Frameworks/frameworks/WebRTC.framework"]

  s.default_subspec = 'Core'

  s.subspec 'Core' do |core|
  end

  s.subspec 'BroadcastExtension' do |ext|
    ext.source_files = 'BroadcastClasses/**/*'
    ext.public_header_files = 'BroadcastClasses/**/*.h'
    ext.vendored_frameworks = ["Frameworks/frameworks/WebRTC.framework"]
    # For app extensions, disabling code paths using unavailable API
    ext.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'MYLIBRARY_APP_EXTENSIONS=1' }
  end
end
