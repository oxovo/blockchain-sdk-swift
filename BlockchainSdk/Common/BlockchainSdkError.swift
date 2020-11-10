//
//  BlockchainSdkError.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 11/9/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public enum BlockchainSdkError: Int, LocalizedError {
	case signatureCountNotMatched = 0
	
	public var errorDescription: String? {
		switch self {
		case .signatureCountNotMatched:
			// TODO: Replace with proper error message. Android sending instead of message just code, and client app decide what message to show to user
			return "\(rawValue)"
		}
	}
}
