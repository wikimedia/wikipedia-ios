source 'https://github.com/CocoaPods/Specs.git'

# Configurations which are not compiled for release on the App Store
# NOT_APP_STORE_CONFIGS = ['Debug', 'Alpha', 'Beta', 'AdHoc'].freeze

platform :ios, :deployment_target => '8.0'

inhibit_all_warnings!

xcodeproj 'Wikipedia'

# HTML
pod 'hpple', '~> 0.2'

# Networking / Parsing
pod 'AFNetworking', '~> 3.1.0'
pod 'Mantle', '~> 2.0.0'
pod 'GCDWebServer', '~> 3.3'

# Images
pod 'SDWebImage', :git => 'https://github.com/wikimedia/SDWebImage.git', :commit => 'bb49df83e72f2231a191e9477a85f0effe13430a'
pod 'AnimatedGIFImageSerialization', :git => 'https://github.com/wikimedia/AnimatedGIFImageSerialization.git'

# Utilities
pod 'libextobjc/EXTScope', '~> 0.4.1'
pod 'BlocksKit/Core', '~> 2.2.0'
pod 'BlocksKit/UIKit', '~> 2.2.0'
pod 'KVOController'

# Dates
pod 'NSDate-Extensions', :git => 'git@github.com:wikimedia/NSDate-Extensions.git'

# Datasources
pod 'SSDataSources', '~> 0.8.0'

# Autolayout
pod 'Masonry', '0.6.2'

# Views
pod 'OAStackView', :git => 'git@github.com:wikimedia/OAStackView.git'
pod 'TSMessages', :git => 'https://github.com/wikimedia/TSMessages.git'
pod 'SVWebViewController', '~> 1.0'
# pod "SWStepSlider", :git => 'https://github.com/wikimedia/SWStepSlider.git'

# Activities
pod 'TUSafariActivity'

# Licenses
pod 'VTAcknowledgementsViewController'

# Photo Gallery
pod 'NYTPhotoViewer'

# Diagnostics
pod 'PiwikTracker', :head
pod 'HockeySDK', '~> 3.8.2'
pod 'Tweaks', :head

target 'WikipediaUnitTests', :exclusive => true do
  pod 'OCMockito', '~> 1.4.0'
  pod 'OCHamcrest', '~> 4.2.0'
  pod 'Nocilla'
  # pod 'FBSnapshotTestCase', :head
  # pod 'Quick', '~> 0.9.0'
  # pod 'Nimble', '~> 4.0.0'
end


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
