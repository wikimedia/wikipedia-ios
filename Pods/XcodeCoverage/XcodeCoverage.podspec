Pod::Spec.new do |s|
  s.name        = 'XcodeCoverage'
  s.version     = '1.2.2'
  s.summary     = 'Code coverage for Xcode projects'
  s.description = <<-DESC
                      XcodeCoverage provides a simple way to generate reports of the code coverage
                      of your Xcode project. Generated reports include HTML and Cobertura XML.

                      Coverage data excludes Apple's SDKs, and the exclusion rules can be customized.
                  DESC
  s.homepage    = 'https://github.com/jonreid/XcodeCoverage'
  s.license     = 'MIT'
  s.author      = {'Jon Reid' => 'jon@qualitycoding.org'}
  s.social_media_url = 'https://twitter.com/qcoding'

  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.8'
  s.source = {:git => 'https://github.com/jonreid/XcodeCoverage.git', :tag => 'v1.2.2'}
  
  # XcodeCoverage files will be brought into the filesystem, but not added to your .xcodeproj. 
  s.preserve_paths = '*', '**'
end
