source 'https://github.com/CocoaPods/Specs.git'

platform :ios, :deployment_target => '7.0'

inhibit_all_warnings!

xcodeproj 'Wikipedia'

# HTML
pod 'DTCoreText', '~> 1.6.16'
pod 'hpple', '~> 0.2'

# Networking / Parsing
pod 'AFNetworking/NSURLConnection', '~> 2.5'
pod 'Mantle'

# Images
pod 'SDWebImage', :path => './vendor/SDWebImage'
pod 'AnimatedGIFImageSerialization'

# Utilities
pod 'libextobjc/EXTScope', '~> 0.4.1'
pod 'BlocksKit/Core', '~> 2.2'
pod 'BlocksKit/UIKit', '~> 2.2'

# KVO
pod 'KVOController'

# Autolayout
pod 'Masonry', '0.6.2'

# Diagnostics
pod 'CocoaLumberjack', '~> 2.0.0'
pod 'HockeySDK', '3.6.2'

target 'WikipediaUnitTests', :exclusive => false do
  pod 'OCMockito', '~> 1.4'
  pod 'OCHamcrest', '~> 4.1'
  pod 'Nocilla'
  pod 'FBSnapshotTestCase/Core', '~> 2.0.3'
end
