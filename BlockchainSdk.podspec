#
# Be sure to run `pod lib lint BlockchainSdk.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'BlockchainSdk'
  s.version          = '0.0.1'
  s.summary          = 'Use BlockchainSdk for Tangem wallet integration'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Use BlockchainSdk for Tangem wallet integration
                       DESC

  s.homepage         = 'https://github.com/TangemCash/tangem-sdk-ios'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  # s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Tangem AG' => '' }
  s.source           = { :git => 'https://github.com/TangemCash/tangem-sdk-ios.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '13.0'

  s.source_files = 'BlockchainSdk/**/*'


  s.resource_bundles = { 'BlockchainSdk' => ['BlockchainSdk/Common/Localizations/*.lproj/*.strings']}

  s.exclude_files = 'BlockchainSdk/WalletManagers/XRP/XRPKit/README.md', 
		    'BlockchainSdk/WalletManagers/XRP/XRPKit/LICENSE',
		    'BlockchainSdk/WalletManagers/Tron/protobuf/Tron Protobuf.md',
		    'BlockchainSdk/WalletManagers/Tron/protobuf/Contracts.proto',
		    'BlockchainSdk/WalletManagers/Tron/protobuf/Tron.proto'


  s.dependency 'BigInt'
  s.dependency 'SwiftyJSON'
  s.dependency 'Moya'
  s.dependency 'Sodium' 
  s.dependency 'SwiftCBOR', '0.4.5'
  s.dependency 'stellar-ios-mac-sdk', '2.2.5'
  s.dependency 'BinanceChain'
  s.dependency 'HDWalletKit'
  s.dependency 'web3swift'
  s.dependency 'TangemSdk'
  s.dependency 'AnyCodable-FlightSchool'
  s.dependency 'BitcoinCore.swift'
  s.dependency 'Solana.Swift'
  s.dependency 'ScaleCodec'
end
