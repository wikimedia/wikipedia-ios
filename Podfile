source 'https://github.com/CocoaPods/Specs.git'

# Configurations which are not compiled for release on the App Store
# NOT_APP_STORE_CONFIGS = ['Debug', 'Alpha', 'Beta', 'AdHoc'].freeze

platform :ios, :deployment_target => '9.0'

inhibit_all_warnings!
use_frameworks!

project 'Wikipedia'

abstract_target 'Foundation' do
  # Networking / Parsing
  pod 'AFNetworking', :git => 'https://github.com/wikimedia/AFNetworking.git', :branch => 'release/3.1.1'
  pod 'Mantle', '~> 2.0.0'

  # Images
  pod 'SDWebImage', :git => 'https://github.com/wikimedia/SDWebImage.git', :commit => 'bb49df83e72f2231a191e9477a85f0effe13430a'
  pod 'AnimatedGIFImageSerialization', :git => 'https://github.com/wikimedia/AnimatedGIFImageSerialization.git'

  # Utilities
  pod 'libextobjc/EXTScope', '~> 0.4.1'
  pod 'BlocksKit/Core', '~> 2.2.0'
  pod 'KVOController', '= 1.1.0'

  pod 'CocoaLumberjack/Swift'

  # Dates
  pod 'NSDate-Extensions', :git => 'git@github.com:wikimedia/NSDate-Extensions.git'

  # Database
  pod 'YapDatabase', :git => 'git@github.com:wikimedia/YapDatabase.git'

  # Promises
  pod 'PromiseKit', '~> 3.4'

  # Datasources
  pod 'SSDataSources', '~> 0.8.0'

  # Autolayout
  pod 'Masonry', '~> 1.0'

  # Diagnostics
  pod 'PiwikTracker', :git => 'https://github.com/wikimedia/piwik-sdk-ios.git'
  pod 'HockeySDK', '~> 4.1.0'

  pod 'hpple', '~> 0.2'

  target 'InTheNewsNotification' do
  end

  target 'ContinueReadingWidget' do
  end

  target 'TopReadWidget' do
  end

  target 'WMFUtilities' do
  end

  target 'WMFModel' do
  end

  target 'WMFUI' do
  end

  target 'Wikipedia' do
    # Utilities
    pod 'Tweaks', :git => 'https://github.com/facebook/Tweaks.git'

    # HTML
    pod 'GCDWebServer', '~> 3.3'

    # Views
    pod 'TSMessages', :git => 'https://github.com/wikimedia/TSMessages.git', :commit => '8c66db6ce8ed8ffe8112b231e6edc71f8580a139'
    pod "SWStepSlider", :git => 'https://github.com/wikimedia/SWStepSlider.git'

    # Activities
    pod 'TUSafariActivity'

    # Licenses
    pod 'VTAcknowledgementsViewController'

    # Photo Gallery
    pod 'NYTPhotoViewer'

    target 'WikipediaUnitTests' do
      pod 'OCMockito', '~> 1.4.0'
      pod 'OCHamcrest', '~> 4.2.0'
      pod 'Nocilla'
      pod 'FBSnapshotTestCase'
      pod 'Quick', '~> 0.9.0'
      pod 'Nimble', '~> 4.0.0'
    end

  end

end

post_install do |installer|
  plist_buddy = "/usr/libexec/PlistBuddy"
  version = `#{plist_buddy} -c "Print CFBundleShortVersionString" Wikipedia/Wikipedia-Info.plist`.strip

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '2.3'
    end
  end

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
