Pod::Spec.new do |s|
  s.name         = "NDPHue"
  s.version      = "0.0.2"
  s.summary      = "Library for interacting with Philips Hue lighting systems."
  s.homepage     = "https://github.com/NickTrienens/mypodspec.git"
  s.license      = "public domain"
  s.author       = { "Dan Parsons" => "dparsons@nyip.net" }
  s.source       = { :git => "https://github.com/NickTrienens/DPHue", :commit => "29afeba56ba0ec202d9232ff55a127a359a206de" }
  s.source_files = 'DPHue/*.{h,m}'
  s.requires_arc = true

  s.dependency 'CocoaAsyncSocket', '~> 7.4.1'

  s.osx.deployment_target = '10.7'
  s.ios.deployment_target = '5.0'
end
