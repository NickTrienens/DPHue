Pod::Spec.new do |s|
  s.name         = "DPHue"
  s.version      = "0.0.1"
  s.summary      = "Library for interacting with Philips Hue lighting systems."
  s.homepage     = "https://github.com/danparsons/DPHue"
  s.license      = "public domain"
  s.author       = { "Dan Parsons" => "dparsons@nyip.net" }
  s.source       = { :git => "https://github.com/danparsons/DPHue.git", :commit => "8b85a281f19ee89b8741daacf3093ca4e00a3007" }
  s.source_files = 'DPHue/*.{h,m}'
  s.framework = 'CommonCrypto'
  s.requires_arc = true
  s.dependency 'CocoaAsyncSocket', '~> 0.0.1'
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
end
