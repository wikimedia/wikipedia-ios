source 'https://github.com/CocoaPods/Specs.git'

# Configurations which are not compiled for release on the App Store
# NOT_APP_STORE_CONFIGS = ['Debug', 'Alpha', 'Beta', 'AdHoc'].freeze

platform :ios, :deployment_target => '8.0'

use_frameworks!
inhibit_all_warnings!

xcodeproj 'Wikipedia'

# HTML
pod 'hpple', '~> 0.2'

# Networking / Parsing
pod 'AFNetworking/NSURLConnection', '~> 2.6.0'
pod 'Mantle', '~> 2.0.0'

# Images
pod 'SDWebImage', :path => './vendor/SDWebImage'
pod 'AnimatedGIFImageSerialization'

# Utilities
pod 'libextobjc/EXTScope', '~> 0.4.1'
pod 'BlocksKit/Core', '~> 2.2.0'
pod 'BlocksKit/UIKit', '~> 2.2.0'
pod 'PromiseKit', :git => 'https://github.com/mxcl/PromiseKit.git', :branch => 'swift-2.0-beta5'
pod 'PromiseKit/SystemConfiguration', :git => 'https://github.com/mxcl/PromiseKit.git', :branch => 'swift-2.0-beta5'

pod 'Tweaks', :head

# KVO
pod 'KVOController'

# Datasources
pod 'SSDataSources', '~> 0.8.0'

# Autolayout
pod 'Masonry', '0.6.2'

# Views
pod 'OAStackView', :git => 'git@github.com:wikimedia/OAStackView.git'
pod 'MGSwipeTableCell', :git => 'git@github.com:wikimedia/MGSwipeTableCell.git'
pod 'TSMessages', :git => 'https://github.com/wikimedia/TSMessages.git'

# Diagnostics
pod 'PiwikTracker', :head
pod 'CocoaLumberjack/Swift', '~> 2.2'
pod 'HockeySDK', '~> 3.8.2'

target 'WikipediaUnitTests', :exclusive => true do
  pod 'OCMockito', '~> 1.4.0'
  pod 'OCHamcrest', '~> 4.2.0'
  pod 'Nocilla'
  pod 'FBSnapshotTestCase', :git => 'https://github.com/facebook/ios-snapshot-test-case', :commit => 'e42af8bbc032a61f93fa9b6ed748052272e522ec'
  pod 'Quick', '~> 0.8.0'
  pod 'Nimble', '~> 3.1.0'
end

pod 'SVWebViewController', '~> 1.0'

post_install do |installer|
  plist_buddy = "/usr/libexec/PlistBuddy"
  version = `#{plist_buddy} -c "Print CFBundleShortVersionString" Wikipedia/Wikipedia-Info.plist`.strip

  def enable_tweaks(target)
    target.build_configurations.each { |c|
      c.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)', 'FB_TWEAK_ENABLED=1'] unless c.name == "Release"
    }
  end

  installer.pods_project.targets.each { |target|
    enable_tweaks(target) if target.name == "Tweaks"
    puts "Updating #{target} version number to #{version}"
    `#{plist_buddy} -c "Set CFBundleShortVersionString #{version}" "Pods/Target Support Files/#{target}/Info.plist"`
  }
end
