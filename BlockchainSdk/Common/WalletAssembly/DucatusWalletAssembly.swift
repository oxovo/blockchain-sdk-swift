//
//  DucatusWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

struct DucatusWalletAssembly: WalletAssemblyProtocol {
    
    static func make(with input: BlockchainAssemblyInput) throws -> AssemblyWallet {
        return try DucatusWalletManager(wallet: input.wallet).then {
            let bitcoinManager = BitcoinManager(networkParams: DucatusNetworkParams(), walletPublicKey: input.wallet.publicKey.blockchainKey, compressedWalletPublicKey: try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress(), bip: .bip44)
            
            $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: input.wallet.addresses)
            $0.networkService = DucatusNetworkService(configuration: input.networkConfig)
        }
    }
    
}