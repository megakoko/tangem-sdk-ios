//
//  CreateWalletTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 22.10.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/**
 * This task will create a new wallet on the card
 * A key pair WalletPublicKey / WalletPrivateKey is generated and securely stored in the card.
 * App will need to obtain Wallet_PublicKey from the response of `CreateWalletTask`or `ScanTask`
 * and then transform it into an address of corresponding blockchain wallet
 * according to a specific blockchain algorithm.
 * WalletPrivateKey is never revealed by the card and will be used by `SignHash` or `SignHashes` and `AttestWalletKeyCommand`.
 * RemainingSignature is set to MaxSignatures.
 */
@available(iOS 13.0, *)
public class CreateWalletTask: CardSessionRunnable {
    private let curve: EllipticCurve

    /// Default initializer
    /// - Parameter curve: Elliptic curve of the wallet.  `Card.supportedCurves` contains all curves supported by the card
    public init(curve: EllipticCurve) {
        self.curve = curve
    }
    
    deinit {
        Log.debug("CreateWalletTask deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<CreateWalletResponse>) {
        let command = CreateWalletCommand(curve: curve)
        command.run(in: session) { result in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                if case .invalidState = error { //Wallet already created but we didn't get the proper response from the card. Rescan and retrieve the wallet
                    print("test: start scan")
                    self.scanAndRetrieveCreatedWallet(at: command.walletIndex, in: session, completion: completion)
                } else {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func scanAndRetrieveCreatedWallet(at index: Int, in session: CardSession, completion: @escaping CompletionResult<CreateWalletResponse>) {
        let readCommand = ReadWalletsListCommand()
        readCommand.run(in: session) { result in
            switch result {
            case .success(let response):
                print("test: success scan")
                session.environment.card?.wallets = response.wallets.sorted(by: { $0.index < $1.index })
                let createdWallet = response.wallets[index]
                print("test: success wallet: \(createdWallet)")
                completion(.success(CreateWalletResponse(cardId: response.cardId, wallet: createdWallet)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
