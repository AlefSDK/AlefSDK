Pod::Spec.new do |spec|

  spec.name         = "AlefSDK"
  spec.version      = "0.1.0"
  spec.summary      = "A short description of AlefSDK."
  spec.homepage     = "https://alefedge.com"

  spec.license      = "MIT"
  spec.author       = { "Lam Ngo" => "lam.ngo@alefedge.com" }
  spec.source       = { :git => 'https://github.com/AlefSDK/AlefSDK.git', :tag => spec.version.to_s }

  spec.static_framework = true
  spec.source_files  = "AlefSDK/**/*.swift"

  spec.platform = :ios, "10.0"
  spec.ios.dependency 'Firebase/Messaging'
  spec.ios.dependency 'AWSSNS'
  spec.ios.dependency 'AWSCognitoIdentityProvider'
  spec.ios.dependency 'NotificationBannerSwift', '~> 3.0.0'
end
