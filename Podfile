platform :ios, '10.0'
use_frameworks!

target "muthos" do
  pod 'KeychainAccess'
  pod 'SVProgressHUD'
  pod 'SwiftyJSON'
  pod 'HCSStarRatingView'
  pod 'iCarousel'
  pod 'DLRadioButton'
  pod 'Alamofire'
  pod 'RxAlamofire'
  pod 'RxSwift', '~> 3.0'
  pod 'RxCocoa', '~> 3.0'
  pod 'ObjectMapper'
  pod 'AlamofireObjectMapper'
  pod 'SMIconLabel'
  pod 'MMDrawerController'
  pod 'MGSwipeTableCell'
  pod 'SwiftAnimations', :git => 'https://github.com/sjkim0757/SwiftAnimations'
  pod 'SDWebImage'
  pod 'PopupDialog', '~> 0.5'
  pod 'ReachabilitySwift', '~> 3'
end

target "muthos-shining" do
  pod 'KeychainAccess'
  pod 'SVProgressHUD'
  pod 'SwiftyJSON'
  pod 'HCSStarRatingView'
  pod 'iCarousel'
  pod 'DLRadioButton'
  pod 'Alamofire'
  pod 'RxAlamofire'
  pod 'RxSwift', '~> 3.0'
  pod 'RxCocoa', '~> 3.0'
  pod 'ObjectMapper'
  pod 'AlamofireObjectMapper'
  pod 'SMIconLabel'
  pod 'MMDrawerController'
  pod 'MGSwipeTableCell'
  pod 'SwiftAnimations', :git => 'https://github.com/sjkim0757/SwiftAnimations'
  pod 'SDWebImage'
  pod 'PopupDialog', '~> 0.5'
  pod 'ReachabilitySwift', '~> 3'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.0'
            config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.10'
        end
    end
end
