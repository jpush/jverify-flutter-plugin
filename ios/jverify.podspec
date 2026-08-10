#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'jverify'
  s.version          = '0.0.1'
  s.summary          = 'A new flutter plugin project.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'https://www.jiguang.cn'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'xudong.rao' => 'xudong.rao@outlook.com' }
  s.source           = { :path => '.' }
  s.source_files = 'jverify/Sources/jverify/**/*.{h,m}'
  s.public_header_files = 'jverify/Sources/jverify/include/jverify/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'JCore', '>= 5.4.0'
  s.dependency 'JVerification', '3.4.7'
  s.frameworks = 'AdSupport'
  s.ios.deployment_target = '11.0'
  s.static_framework = true
end
