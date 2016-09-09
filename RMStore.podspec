Pod::Spec.new do |s|
  s.name = 'RMStore'
  s.version = '0.8.0'
  s.license = 'Apache 2.0'
  s.summary = 'A lightweight iOS library for In-App Purchases that adds blocks and notifications to StoreKit, plus verification, persistence and downloads.'
  s.homepage = 'https://github.com/robotmedia/RMStore'
  s.author = 'Hermes Pique'
  s.social_media_url = 'https://twitter.com/hpique'
  s.source = { :git => 'https://github.com/robotmedia/RMStore.git', :tag => "v#{s.version}" }
  s.frameworks = 'StoreKit'
  s.requires_arc = true
  s.default_subspec = 'Core'
  
  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.7'

  s.subspec 'Core' do |core|
    core.source_files = 'RMStore/*.{h,m}'
  end

  s.subspec 'KeychainPersistence' do |kp|
    kp.dependency 'RMStore/Core'
    kp.source_files = 'RMStore/Optional/RMStoreKeychainPersistence.{h,m}'
    kp.frameworks = 'Security'
  end

  s.subspec 'NSUserDefaultsPersistence' do |nsudp|
    nsudp.dependency 'RMStore/Core'
    nsudp.source_files = 'RMStore/Optional/RMStoreUserDefaultsPersistence.{h,m}', 'RMStore/Optional/RMStoreTransaction.{h,m}'
  end

  s.subspec 'AppReceiptVerifier' do |arv|
    arv.dependency 'RMStore/Core'
    arv.source_files = 'RMStore/Optional/RMStoreAppReceiptVerifier.{h,m}', 'RMStore/Optional/RMAppReceipt.{h,m}'
    arv.dependency 'OpenSSL-Universal', '~> 1.0'
    arv.osx.frameworks = 'Security', 'IOKit'
    arv.resources = 'RMStore/Optional/AppleIncRootCertificate.cer'
  end

end
