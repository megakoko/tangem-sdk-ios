//
//  HDWalletError.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

enum HDWalletError: String, Error, LocalizedError {
    case hardenedNotSupported
    case derivationFailed
    case wrongPath
    
    var errorDescription: String? {
        return rawValue
    }
}
