//
//  BitcoinNetworkService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 10.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import TangemSdk
import Alamofire

class BitcoinNetworkService: MultiNetworkProvider, BitcoinNetworkProvider {
    let providers: [AnyBitcoinNetworkProvider]
    var currentProviderIndex: Int = 0
    
    init(providers: [AnyBitcoinNetworkProvider]) {
        self.providers = providers
    }
    
    var supportsTransactionPush: Bool { !providers.filter { $0.supportsTransactionPush }.isEmpty }
    
    var supportsAddressPrefix: Bool { providers[currentProviderIndex].supportsAddressPrefix }
    
    func getInfo(addresses: [String]) -> AnyPublisher<[BitcoinResponse], Error> {
        providerPublisher {
            $0.getInfo(addresses: addresses.map($0.removePrefixIfNeeded(from:)))
                .retry(2)
                .eraseToAnyPublisher()
        }
    }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        providerPublisher{
            $0.getInfo(address: $0.removePrefixIfNeeded(from: address))
                .retry(2)
                .eraseToAnyPublisher()
        }
    }
    
    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        Publishers.MergeMany(providers.map {
            $0.getFee()
                .retry(2)
                .replaceError(with: BitcoinFee(minimalSatoshiPerByte: 0, normalSatoshiPerByte: 0, prioritySatoshiPerByte: 0))
                .eraseToAnyPublisher()
        })
        .collect()
        .tryMap { feeList -> BitcoinFee in
            var min: Decimal = 0
            var norm: Decimal = 0
            var priority: Decimal = 0
            
            if feeList.count > 2 {
                let divider = Decimal(feeList.count - 1)
                min = feeList.map { $0.minimalSatoshiPerByte }.sorted().dropFirst().reduce(0, +) / divider
                norm = feeList.map { $0.normalSatoshiPerByte }.sorted().dropFirst().reduce(0, +) / divider
                priority = feeList.map { $0.prioritySatoshiPerByte }.sorted().dropFirst().reduce(0, +) / divider
            } else {
                feeList.forEach {
                    min = max($0.minimalSatoshiPerByte, min)
                    norm = max($0.normalSatoshiPerByte, norm)
                    priority = max($0.prioritySatoshiPerByte, priority)
                }
            }
            
            guard min >= 0, norm >= 0, priority >= 0 else {
                throw BlockchainSdkError.failedToLoadFee
            }
            return BitcoinFee(minimalSatoshiPerByte: min, normalSatoshiPerByte: norm, prioritySatoshiPerByte: priority)
        }
        .eraseToAnyPublisher()
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        providerPublisher {
            $0.send(transaction: transaction)
        }
    }
    
    func push(transaction: String) -> AnyPublisher<String, Error> {
        providers.first(where: { $0.supportsTransactionPush })?
            .push(transaction: transaction) ?? .anyFail(error: BlockchainSdkError.networkProvidersNotSupportsRbf)
    }
    
    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        providerPublisher {
            $0.getSignatureCount(address: $0.removePrefixIfNeeded(from: address))
        }
    }
    
}

fileprivate extension AnyBitcoinNetworkProvider {
    func removePrefixIfNeeded(from address: String) -> String {
        if supportsAddressPrefix {
            return address
        } else {
            return address.removeAddressPrefix()
        }
    }
}
