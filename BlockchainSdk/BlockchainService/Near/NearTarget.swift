//
//  NearTarget.swift
//  BlockchainSdk
//
//  Created by Pavel Grechikhin on 06.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct NearTarget: TargetType {
    let endpoint: TargetEndpoints
    
    var baseURL: URL {
        return endpoint.baseURL
    }
    
    var path: String {
        return endpoint.path
    }
    
    var method: Moya.Method {
        return endpoint.method
    }
    
    var task: Moya.Task {
        return endpoint.task
    }
    
    var headers: [String : String]? {
        return endpoint.headers
    }
    
    private var jsonEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
    
    enum TargetEndpoints: TargetType {
        case accessKey(nearPublicKey: NearPublicKey, isTestnet: Bool = false)
        case accessKeyList(accountID: String, isTestnet: Bool = false)
        case accountInfo(accountID: String, isTestnet: Bool = false)
        case accountHistory(accountID: String, isTestnet: Bool = false)
        case gasPrice(isTestnet: Bool = false)
        case sendTransaction(signedTransactionBase64: String, isTestnet: Bool = false)
        case sendAndAwaitTransaction(signedTransactionBase64: String, isTestnet: Bool = false)
        case lastBlock(isTestnet: Bool = false)
        
        var encoder: JSONEncoder {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            return encoder
        }
        
        var baseURL: URL {
            switch self {
            case .accessKey(_, let isTestnet):
                if isTestnet {
                    return URL(string: "https://rpc.testnet.near.org")!
                }
                return URL(string: "https://rpc.mainnet.near.org")!
            case .accessKeyList(_, let isTestnet):
                if isTestnet {
                    return URL(string: "https://rpc.testnet.near.org")!
                }
                return URL(string: "https://rpc.mainnet.near.org")!
            case .accountInfo(_, let isTestnet):
                if isTestnet {
                    return URL(string: "https://rpc.testnet.near.org")!
                }
                return URL(string: "https://rpc.mainnet.near.org")!
            case .accountHistory(_, let isTestnet):
                if isTestnet {
                    return URL(string: "https://rpc.testnet.near.org")!
                }
                return URL(string: "https://rpc.mainnet.near.org")!
            case .gasPrice(let isTestnet):
                if isTestnet {
                    return URL(string: "https://rpc.testnet.near.org")!
                }
                return URL(string: "https://rpc.mainnet.near.org")!
            case .sendTransaction(_, let isTestnet):
                if isTestnet {
                    return URL(string: "https://rpc.testnet.near.org")!
                }
                return URL(string: "https://rpc.mainnet.near.org")!
            case .sendAndAwaitTransaction(_, let isTestnet):
                if isTestnet {
                    return URL(string: "https://rpc.testnet.near.org")!
                }
                return URL(string: "https://rpc.mainnet.near.org")!
            case .lastBlock(let isTestnet):
                if isTestnet {
                    return URL(string: "https://rpc.testnet.near.org")!
                }
                return URL(string: "https://rpc.mainnet.near.org")!
            }
        }
        
        var path: String { "" }
        
        var method: Moya.Method { Moya.Method.post }
        
        var task: Moya.Task {
            switch self {
            case .accessKey(let nearPublicKey, _):
                return .requestCustomJSONEncodable(NearRequestAccessViewBodyObject(params: .init(accountId: nearPublicKey.address(), publicKey: nearPublicKey.txPublicKey())), encoder: encoder)
            case .accessKeyList(let accountID, _):
                return .requestCustomJSONEncodable(NearRequestAccessViewListBodyObject(params: .init(accountId: accountID)), encoder: encoder)
            case .accountInfo(let accountID, _):
                return .requestCustomJSONEncodable(NearAccountInfoBodyObject(params: .init(accountId: accountID)), encoder: encoder)
            case .accountHistory(let accountID, _):
                return .requestCustomJSONEncodable(NearAccountHistoryBodyObject(params: .init(accountIds: [accountID])), encoder: encoder)
            case .gasPrice:
                return .requestCustomJSONEncodable(NearGasPriceBodyObject(), encoder: encoder)
            case .sendTransaction(let signedTransactionBase64, _):
                return .requestCustomJSONEncodable(NearSendTransactionBodyObject(params: [signedTransactionBase64]), encoder: encoder)
            case .sendAndAwaitTransaction(let signedTransactionBase64, _):
                return .requestCustomJSONEncodable(NearSendTransactionBodyObject(params: [signedTransactionBase64]), encoder: encoder)
            case .lastBlock:
                return .requestCustomJSONEncodable(NearLastBlockBodyObject(), encoder: encoder)
            }
        }
        
        var headers: [String : String]? {
            return ["Content-Type": "application/json"]
        }
    }
}

struct NearAPIMethod {
    static let viewAccessKey = "view_access_key"
    static let viewAccessKeyList = "view_access_key_list"
    static let viewAccount = "view_account"
    static let experimentalChanges = "EXPERIMENTAL_changes"
    static let gasPrice = "gas_price"
    static let sendTransactionAsync = "broadcast_tx_async"
    static let sendAndAwaitTransaction = "broadcast_tx_commit"
    static let lastBlock = "block"
}
