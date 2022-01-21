//
//  SolanaResponse.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 18.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Solana_Swift

struct SolanaAccountInfoResponse {
    let balance: Decimal
    let accountExists: Bool
    let tokensByMint: [String: SolanaTokenAccountInfoResponse]
}

struct SolanaMainAccountInfoResponse {
    let balance: Lamports
    let accountExists: Bool
}

struct SolanaTokenAccountInfoResponse {
    let address: String
    let mint: String
    let balance: Decimal
}
