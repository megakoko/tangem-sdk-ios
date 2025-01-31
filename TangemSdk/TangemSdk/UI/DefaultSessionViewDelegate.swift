//
//  DefaultSessionViewDelegate.swift
//  TangemSdk
//
//  Created by Andrew Son on 02/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

@available(iOS 13.0, *)
final class DefaultSessionViewDelegate {
    private let reader: CardReader
    private let engine: HapticsEngine
    private var pinnedMessage: String?
    private var infoScreen: UIViewController
    private let viewModel: MainViewModel = .init(viewState: .scan)
    
    init(reader: CardReader, style: TangemSdkStyle) {
        self.reader = reader
        self.engine = HapticsEngine()
        let view = MainView()
            .environmentObject(viewModel)
            .environmentObject(style)
        
        self.infoScreen = UIHostingController(rootView: view)
        self.infoScreen.modalPresentationStyle = .overFullScreen
        self.infoScreen.modalTransitionStyle = .crossDissolve
        engine.create()
    }
    
    deinit {
        Log.debug("DefaultSessionViewDelegate deinit")
    }
    
    private func presentInfoScreenIfNeeded() {
        guard !self.infoScreen.isBeingPresented, self.infoScreen.presentingViewController == nil,
              let topmostViewController = UIApplication.shared.topMostViewController
        else { return }
        
        topmostViewController.present(self.infoScreen, animated: true, completion: nil)
    }
    
    private func dismissInfoScreen(completion: (() -> Void)?) {
        if infoScreen.isBeingDismissed || infoScreen.presentingViewController == nil {
            completion?()
            return
        }
        
        if self.infoScreen.isBeingPresented {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.infoScreen.dismiss(animated: false, completion: completion)
            }
            return
        }
        
        self.infoScreen.presentingViewController?.dismiss(animated: true, completion: completion)
    }
    
    private func runInMainThread(_ block: @autoclosure @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}

@available(iOS 13.0, *)
extension DefaultSessionViewDelegate: SessionViewDelegate {
    func setState(_ state: SessionViewState) {
        Log.view("Set state: \(state)")
        if state.shouldPlayHaptics {
            engine.playTick()
        }
        
        let setStateAction = { self.viewModel.viewState = state }
        runInMainThread (setStateAction())
        runInMainThread(self.presentInfoScreenIfNeeded())
    }
    
    func showAlertMessage(_ text: String) {
        Log.view("Show alert message: \(text)")
        reader.alertMessage = text
    }
    
    func tagConnected() {
        Log.view("Tag connected")
        if let pinnedMessage = pinnedMessage {
            showAlertMessage(pinnedMessage)
            self.pinnedMessage = nil
        }
        engine.playSuccess()
    }
    
    func tagLost() {
        Log.view("Tag lost")
        if pinnedMessage == nil {
            pinnedMessage = reader.alertMessage
        }
        showAlertMessage(Localization.nfcAlertDefault)
    }
    
    func wrongCard(message: String) {
        Log.view("Wrong card detected")
        engine.playError()
        if pinnedMessage == nil {
            pinnedMessage = reader.alertMessage
        }
        showAlertMessage(message)
    }
    
    func sessionStarted() {
        Log.view("Session started")
        runInMainThread(self.presentInfoScreenIfNeeded())
        engine.start()
    }
    
    func sessionStopped(completion: (() -> Void)?) {
        Log.view("Session stopped")
        pinnedMessage = nil
        engine.stop()
        runInMainThread(self.dismissInfoScreen(completion: completion))
    }
    
    //TODO: Refactor UI
    func attestationDidFail(isDevelopmentCard: Bool, onContinue: @escaping () -> Void, onCancel: @escaping () -> Void) {
        let title = TangemSdkError.cardVerificationFailed.localizedDescription
        let message = isDevelopmentCard ? "This is a development card. You can continue at your own risk"
            : "This card may be production sample or conterfeit. You can continue at your own risk"
        
        runInMainThread(UIAlertController.showShouldContinue(from: self.infoScreen,
                                                             title: title,
                                                             message: message,
                                                             onContinue: onContinue,
                                                             onCancel: onCancel))
    }
    
    //TODO: Refactor UI
    func attestationCompletedOffline(onContinue: @escaping () -> Void, onCancel: @escaping () -> Void, onRetry: @escaping () -> Void) {
        let title =  "Online attestation failed"
        let message = "We cannot finish card's online attestation at this time. You can continue at your own risk and try again later, retry now or cancel the operation"
        
        runInMainThread(UIAlertController.showShouldContinue(from: self.infoScreen,
                                                             title: title,
                                                             message: message,
                                                             onContinue: onContinue,
                                                             onCancel: onCancel,
                                                             onRetry: onRetry))
    }
    
    //TODO: Refactor UI
    func attestationCompletedWithWarnings(onContinue: @escaping () -> Void) {
        let title = "Warning"
        let message = "Too large runs count of Attest Wallet or Sign looks suspicious."
        runInMainThread(UIAlertController.showAlert(from: self.infoScreen,
                                                    title: title,
                                                    message: message,
                                                    onContinue: onContinue))
    }
}

//TODO: Localize
fileprivate extension UIAlertController {
    static func showShouldContinue(from controller: UIViewController, title: String, message: String, onContinue: @escaping () -> Void, onCancel: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "I understand", style: .destructive) { _ in onContinue() })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in onCancel() } )
        controller.present(alert, animated: true)
    }
    
    static func showShouldContinue(from controller: UIViewController, title: String, message: String, onContinue: @escaping () -> Void, onCancel: @escaping () -> Void, onRetry: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "I understand", style: .destructive) { _ in onContinue() })
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in onRetry() })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in onCancel() } )
        controller.present(alert, animated: true)
    }
    
    static func showAlert(from controller: UIViewController, title: String, message: String, onContinue: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default) { _ in onContinue() })
        controller.present(alert, animated: true)
    }
}
