//
//  TronTarget.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 24.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

enum TronTarget: TargetType {
    case getAccount(address: String, network: TronNetwork)
    case createTransaction(source: String, destination: String, amount: UInt64, network: TronNetwork)
    case broadcastTransaction(transaction: TronTransactionRequest, network: TronNetwork)
    case tokenBalance(address: String, contractAddress: String, network: TronNetwork)
    
    var baseURL: URL {
        switch self {
        case .getAccount(_, let network):
            return network.url
        case .createTransaction(_, _, _, let network):
            return network.url
        case .broadcastTransaction(_, let network):
            return network.url
        case .tokenBalance(_, _, let network):
            return network.url
        }
    }
    
    var path: String {
        switch self {
        case .getAccount:
            return "/wallet/getaccount"
        case .createTransaction:
            return "/wallet/createtransaction"
        case .broadcastTransaction:
            return "/wallet/broadcasttransaction"
        case .tokenBalance:
            return "/wallet/triggersmartcontract"
        }
    }
    
    var method: Moya.Method {
        return .post
    }
    
    var task: Task {
        let encoder = JSONEncoder()
        let requestData: Data?
        
        do {
            switch self {
            case .getAccount(let address, _):
                let request = TronGetAccountRequest(address: address, visible: true)
                requestData = try encoder.encode(request)
            case .createTransaction(let source, let destination, let amount, _):
                let request = TronCreateTransactionRequest(owner_address: source, to_address: destination, amount: amount, visible: true)
                requestData = try encoder.encode(request)
            case .broadcastTransaction(let transaction, _):
                requestData = try encoder.encode(transaction)
            case .tokenBalance(let address, let contractAddress, _):
                let hexAddress = TronAddressService.toHexForm(address, length: 64) ?? ""
                
                let request = TronTriggerSmartContractRequest(
                    owner_address: address,
                    contract_address: contractAddress,
                    function_selector: "balanceOf(address)",
                    parameter: hexAddress,
                    visible: true
                )
                requestData = try encoder.encode(request)
            }
        } catch {
            print("Failed to encode Tron request data:", error)
            return .requestPlain
        }

        return .requestData(requestData ?? Data())
    }
    
    var headers: [String : String]? {
        return [
            "Accept": "application/json",
            "Content-Type": "application/json",
        ]
    }
}
