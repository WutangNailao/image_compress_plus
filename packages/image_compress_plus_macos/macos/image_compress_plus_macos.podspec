#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint image_compress_plus_macos.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'image_compress_plus_macos'
  s.version          = '1.0.3'
  s.summary          = 'Flutter image compress for macOS'
  s.description      = <<-DESC
  Flutter image compress for macOS
                       DESC
  s.homepage         = 'https://github.com/WuTangNaiLao/image_compress_plus'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Caijinglong' => 'cjl_spy@163.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.15'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
