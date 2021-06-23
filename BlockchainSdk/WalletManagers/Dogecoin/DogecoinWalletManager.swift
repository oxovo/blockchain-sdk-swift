//
//  DogecoinWalletManager.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 25/05/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

class DogecoinWalletManager: BitcoinWalletManager {
    override var minimalFee: Decimal { 1.0 }
    override var minimalFeePerByte: Decimal { 1 }
}

extension DogecoinWalletManager: DustRestrictable {
    var dustValue: Amount {
        .init(with: wallet.blockchain, value: minimalFee)
    }
}
