Pod::Spec.new do |s|
  s.name             = 'image_compress_plus_ios'
  s.version          = '1.0.6'
  s.summary          = 'Compress image with native Objective-C with faster speed.'
  s.description      = <<-DESC
Compress image with native Objective-C with faster speed.
                       DESC
  s.homepage         = 'http://github.com/fluttercandies/image_compress_plus'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'fluttercandies' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'

  s.source_files = 'Classes/**/*.swift'

  s.dependency 'Flutter'
  s.dependency 'SDWebImage'
  s.dependency 'SDWebImageWebPCoder'
end
