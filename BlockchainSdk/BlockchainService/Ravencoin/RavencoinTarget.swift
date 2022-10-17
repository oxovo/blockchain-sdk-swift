//
//  RavencoinTarget.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 16.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine

// https://testnet.ravencoin.network/api/addr/mgs9F1oLUAnwLRTJrg2HEVZ4nW3kxWrVns
// https://ravencoin.network/api/addr/RRjP4a6i7e1oX1mZq1rdQpNMHEyDdSQVNi

struct RavencoinTarget {
    let isTestnet: Bool
    let target: RavencoinTargetType
}

extension RavencoinTarget: TargetType {
    var headers: [String : String]? {
        /// Hack that api is work
        ["User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"]
    }

    var baseURL: URL {
        if isTestnet {
            return URL(string: "https://testnet.ravencoin.network/api/")!
        } else {
            /// May be use https://api.ravencoin.org/api/
            return URL(string: "https://ravencoin.network/api/")!
        }
    }
    
    var path: String {
        switch target {
        case let .addressInfo(address):
            return "addr/\(address)"
        }
    }
    
    var method: Moya.Method {
        switch target {
        case .addressInfo:
            return .get
        }
    }
    
    var task: Moya.Task {
        switch target {
        case .addressInfo:
            return .requestParameters(parameters: ["noTxList" : "1"], encoding: URLEncoding.default)
        }
    }
}

extension RavencoinTarget {
    enum RavencoinTargetType {
        case addressInfo(_ address: String)
    }
}