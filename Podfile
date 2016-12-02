source 'https://github.com/CocoaPods/Specs.git'

platform :ios, :deployment_target => '9.3'

inhibit_all_warnings!
use_frameworks!

project 'Wikipedia'

abstract_target 'Foundation' do
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
  	pod 'Appsee', :configurations => ['Alpha', 'AlphaDebug']
    
	# Utilities
    pod 'Tweaks', :git => 'https://github.com/facebook/Tweaks.git'
	   
    # Views
	pod 'TSMessages', :git => 'https://github.com/wikimedia/TSMessages.git', :commit => '8c66db6ce8ed8ffe8112b231e6edc71f8580a139'
    pod "SWStepSlider", :git => 'https://github.com/wikimedia/SWStepSlider.git'
    
	# Activities
    pod 'TUSafariActivity'
	
    target 'WikipediaUnitTests' do
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
