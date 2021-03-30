//
//  WalletManagerFactory.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 06.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import stellarsdk
import BitcoinCore

public class WalletManagerFactory {
    private let config: BlockchainSdkConfig
    
    public init(config: BlockchainSdkConfig) {
        self.config = config
    }
    
    /// Base wallet manager constructor
    /// - Parameters:
    ///   - card: Tangem card
    ///   - blockchain: blockhain to create. If nil, card native blockchain will be used
    /// - Returns: WalletManager?
    public func makeWalletManager(from card: Card, blockchain: Blockchain? = nil) -> WalletManager? {
        guard let walletPublicKey = card.walletPublicKey,
              let cardId = card.cardId,
              let curve = card.curve,
              let selectedBlockchain = blockchain ?? card.blockchain else {
            return nil
        }
        
        var tokens: [Token] = .init()
        if selectedBlockchain == card.blockchain { //search for native tokens only for native blockchain
            if let cardToken = card.token {
                tokens.append(cardToken)
            }
        }
        
        return makeWalletManager(from: selectedBlockchain,
                                 walletPublicKey: walletPublicKey,
                                 cardId: cardId,
                                 cardCurve: curve,
                                 walletPairPublicKey: nil,
                                 tokens: tokens)
    }
    
    public func makeWalletManagers(from card: Card, blockchains: [Blockchain]) -> [WalletManager] {
        return blockchains.compactMap { makeWalletManager(from: card, blockchain: $0) }
    }
    
    public func makeEthereumWalletManager(from card: Card, erc20Tokens: [Token]) -> WalletManager? {
        guard let manager = makeWalletManager(from: card, blockchain: .ethereum(testnet: card.isTestnet)) else {
            return nil
        }
        
        let additionalTokens = erc20Tokens.filter { !manager.cardTokens.contains($0) }
        manager.cardTokens.append(contentsOf: additionalTokens)
        return manager
    }
    
    public func makeTwinWalletManager(from card: Card, pairKey: Data) -> WalletManager? {
        guard let walletPublicKey = card.walletPublicKey,
              let cardId = card.cardId,
              let curve = card.curve,
              let blockchain = card.blockchain else {
            return nil
        }
        
        return makeWalletManager(from: blockchain,
                                 walletPublicKey: walletPublicKey,
                                 cardId: cardId,
                                 cardCurve: curve,
                                 walletPairPublicKey: pairKey,
                                 tokens: [])
    }
    
    func makeWalletManager(from blockchain: Blockchain,
                           walletPublicKey: Data,
                           cardId: String,
                           cardCurve: EllipticCurve,
                           walletPairPublicKey: Data? = nil,
                           tokens: [Token] = []) -> WalletManager? {
        guard blockchain.curve == cardCurve else { return nil }
        
		let addresses = blockchain.makeAddresses(from: walletPublicKey, with: walletPairPublicKey)
		let wallet = Wallet(blockchain: blockchain,
                            addresses: addresses)
         
        switch blockchain {
        case .bitcoin(let testnet):
            return BitcoinWalletManager(cardId: cardId, wallet: wallet).then {
                let network: BitcoinNetwork = testnet ? .testnet : .mainnet
                let bitcoinManager = BitcoinManager(networkParams: network.networkParams,
                                                             walletPublicKey: walletPublicKey,
                                                             compressedWalletPublicKey: Secp256k1Utils.convertKeyToCompressed(walletPublicKey)!,
                                                             bip: walletPairPublicKey == nil ? .bip84 : .bip141)
                
                $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: addresses)
                
                var providers = [BitcoinNetworkApi:BitcoinNetworkProvider]()
                providers[.blockchair] = BlockchairNetworkProvider(endpoint: .bitcoin, apiKey: config.blockchairApiKey)
                providers[.blockcypher] = BlockcypherNetworkProvider(endpoint: BlockcypherEndpoint(coin: .btc, chain: testnet ? .test3: .main),
                                                              tokens: config.blockcypherTokens)
               // providers[.main] = BitcoinMainProvider()
                
                $0.networkService = BitcoinNetworkService(providers: providers, isTestNet: testnet, defaultApi: .blockchair)
            }
            
        case .litecoin:
            return LitecoinWalletManager(cardId: cardId, wallet: wallet).then {
                let bitcoinManager = BitcoinManager(networkParams: LitecoinNetworkParams(),
                                                    walletPublicKey: walletPublicKey,
                                                    compressedWalletPublicKey: Secp256k1Utils.convertKeyToCompressed(walletPublicKey)!,
                                                    bip: .bip44)
                
                $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: addresses)
                
                var providers = [BitcoinNetworkApi:BitcoinNetworkProvider]()
                providers[.blockcypher] = BlockcypherNetworkProvider(endpoint: BlockcypherEndpoint(coin: .ltc, chain: .main), tokens: config.blockcypherTokens)
                providers[.blockchair] = BlockchairNetworkProvider(endpoint: .litecoin, apiKey: config.blockchairApiKey)

                $0.networkService = BitcoinNetworkService(providers: providers, isTestNet: false, defaultApi: .blockchair)
            }
            
        case .ducatus:
            return DucatusWalletManager(cardId: cardId, wallet: wallet).then {
                let bitcoinManager = BitcoinManager(networkParams: DucatusNetworkParams(), walletPublicKey: walletPublicKey, compressedWalletPublicKey: Secp256k1Utils.convertKeyToCompressed(walletPublicKey)!, bip: .bip44)
                
                $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: addresses)
                $0.networkService = DucatusNetworkService()
            }
            
        case .stellar(let testnet):
            return StellarWalletManager(cardId: cardId, wallet: wallet, cardTokens: tokens).then {
                let url = testnet ? "https://horizon-testnet.stellar.org" : "https://horizon.stellar.org"
                let stellarSdk = StellarSDK(withHorizonUrl: url)
                $0.stellarSdk = stellarSdk
                $0.txBuilder = StellarTransactionBuilder(stellarSdk: stellarSdk, walletPublicKey: walletPublicKey, isTestnet: testnet)
                $0.networkService = StellarNetworkService(stellarSdk: stellarSdk)
            }
            
        case .ethereum(let testnet):
            return EthereumWalletManager(cardId: cardId, wallet: wallet, cardTokens: tokens).then {
                let ethereumNetwork = testnet ? EthereumNetwork.testnet(projectId: config.infuraProjectId) : EthereumNetwork.mainnet(projectId: config.infuraProjectId)
                $0.txBuilder = EthereumTransactionBuilder(walletPublicKey: walletPublicKey, network: ethereumNetwork)
                let provider = BlockcypherNetworkProvider(endpoint: .init(coin: .eth, chain: .main), tokens: config.blockcypherTokens)
                $0.networkService = EthereumNetworkService(network: ethereumNetwork, blockcypherProvider: provider)
            }
            
        case .rsk:
            return EthereumWalletManager(cardId: cardId, wallet: wallet, cardTokens: tokens).then {
                $0.txBuilder = EthereumTransactionBuilder(walletPublicKey: walletPublicKey, network: .rsk)
                $0.networkService = EthereumNetworkService(network: .rsk, blockcypherProvider: nil)
            }
            
        case .bitcoinCash(let testnet):
            return BitcoinCashWalletManager(cardId: cardId, wallet: wallet).then {
                let provider = BlockchairNetworkProvider(endpoint: .bitcoinCash, apiKey: config.blockchairApiKey)
                $0.txBuilder = BitcoinCashTransactionBuilder(walletPublicKey: walletPublicKey, isTestnet: testnet)
                $0.networkService = BitcoinCashNetworkService(provider: provider)
            }
            
        case .binance(let testnet):
            return BinanceWalletManager(cardId: cardId, wallet: wallet, cardTokens: tokens).then {
                $0.txBuilder = BinanceTransactionBuilder(walletPublicKey: walletPublicKey, isTestnet: testnet)
                $0.networkService = BinanceNetworkService(isTestNet: testnet)
            }
            
        case .cardano(let shelley):
            return CardanoWalletManager(cardId: cardId, wallet: wallet).then {
                $0.txBuilder = CardanoTransactionBuilder(walletPublicKey: walletPublicKey, shelleyCard: shelley)
                let service = CardanoNetworkService(providers: [
                    AdaliteNetworkProvider(baseUrl: .main),
                    RosettaNetworkProvider(baseUrl: .tangemRosetta)
                ])
                $0.networkService = service
            }
            
        case .xrp(let curve):
            return XRPWalletManager(cardId: cardId, wallet: wallet).then {
                $0.txBuilder = XRPTransactionBuilder(walletPublicKey: walletPublicKey, curve: curve)
                $0.networkService = XRPNetworkService()
            }
        case .tezos:
            return TezosWalletManager(cardId: cardId, wallet: wallet).then {
                $0.txBuilder = TezosTransactionBuilder(walletPublicKey: walletPublicKey)
                $0.networkService = TezosNetworkService()
            }
        }
    }
}
