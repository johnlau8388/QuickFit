# Uncomment the next line to define a global platform for your project
platform :ios, '16.0'

target 'QuickFit' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for QuickFit

  # 微信SDK
  pod 'WechatOpenSDK-XCFramework'

  # 网络请求（可选，使用原生URLSession也可以）
  # pod 'Alamofire', '~> 5.8'

  # 图片加载缓存（可选）
  # pod 'Kingfisher', '~> 7.0'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    end
  end
end
