# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Entropy' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  pod 'SwiftFormat/CLI'

  # Pods for Entropy
  pod 'OLMKit', :inhibit_warnings => true # silence the warnings
  pod 'EntropyKit', :git => 'https://github.com/Kodeshack/EntropyKit.git', :branch => 'master'

  target 'EntropyTests' do
    inherit! :search_paths
    # Pods for testing
  end

end
