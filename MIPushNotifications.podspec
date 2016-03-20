Pod::Spec.new do |s|
s.name     = 'MIPushNotifications'
s.version  = '1.0.0'
s.homepage = 'https://bitbucket.org/mobileidentity/mirateappcontroller.git'
s.license  = 'MIT'
s.platform = :ios
s.source   = { :git => 'https://bitbucket.org/mobileidentity/mipushnotifications.git', :tag => s.version.to_s }
s.source_files = 'MIPushNotifications/*.{h,m}'
s.requires_arc = true
end