#!/usr/bin/env ruby

require 'xcodeproj'

OGVKit = 'Carthage/Checkouts/OGVKit/Example'

project_path = "#{OGVKit}/Pods/Pods.xcodeproj"

def ppp(cmd)
    IO.popen(cmd) do |io|
        while (line = io.gets) do
            puts line
        end
    end
end

ppp 'carthage bootstrap --no-build OGVKit'

ppp "cd #{OGVKit};pod install --verbose"

schemes_dir  = Xcodeproj::XCScheme.user_data_dir(project_path)
schemes = Dir[File.join(schemes_dir,'*.xcscheme')].map do |scheme|
    File.basename(scheme, '.xcscheme')
end
schemes.each do |scheme|
    Xcodeproj::XCScheme.share_scheme(project_path,scheme)
end

# ppp 'carthage build --platform iOS --verbose OGVKit'

