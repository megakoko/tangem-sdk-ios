//
//  ProgressView.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 23.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
struct MainView: View {
    var style: TangemSdkStyle = .default
    var viewState: SessionViewState = .scan
    
    var body: some View {
        mainView
            .transition(AnyTransition
                            .identity
                            .combined(with: .opacity))
            .environmentObject(style)
    }
    
    @ViewBuilder
    private var mainView: some View {
        switch viewState {
        case .scan:
            ReadView()
            
        case .requestCode(let type, cardId: let cardId, completion: let completion):
            EnterUserCodeView(title: type.enterCodeTitle,
                              cardId: cardId ?? "",
                              placeholder: type.name,
                              completion: completion)
            
        case .requestCodeChange(let type, cardId: let cardId, completion: let completion):
            ChangeUserCodeView(title: type.changeCodeTitle,
                               cardId: cardId ?? "",
                               placeholder: type.name,
                               confirmationPlaceholder: type.confirmCodeTitle,
                               completion: completion)
            
        default:
            indicatorView(self.viewState.indicatorState!)
        }
    }
    
    @ViewBuilder
    private func indicatorView(_ state: IndicatorView.ViewState) -> some View {
        GeometryReader { geo in
            
            let sheetHeight =  UIScreen.main.isZoomedMode && UIScreen.main.scale < 3 ? Constants.nfcSheetHeightZoomed : Constants.nfcSheetHeight
            let availableSpace = min(geo.size.width, geo.size.height - sheetHeight, Constants.indicatorMaxSize)
            let indicatorSize = availableSpace * 0.8

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    IndicatorView(state: state)
                        .frame(width: indicatorSize, height: indicatorSize)
                    Spacer()
                }
                Spacer()
            }
            .padding(.bottom, sheetHeight)
        }
    }
}

@available(iOS 13.0, *)
private extension MainView {
    enum Constants {
        static let indicatorMaxSize: CGFloat = 280
        static let nfcSheetHeightZoomed: CGFloat = 310 //iPhone 7
        static let nfcSheetHeight: CGFloat = 390
    }
}

@available(iOS 13.0, *)
struct MainView_Preview: PreviewProvider {
    static var previews: some View {
        MainView(viewState: .default)
        MainView(viewState: .scan)
    }
}

@available(iOS 13.0, *)
fileprivate extension SessionViewState {
    
    var isFullScreen: Bool {
        switch self {
        case .requestCode, .requestCodeChange:
            return true
        default:
            return false
        }
    }
    
    var indicatorState: IndicatorView.ViewState? {
        switch self {
        case .default:
            return .spinner
            
        case .delay(let remaining, let total):
            return .delay(currentValue: CGFloat(remaining),
                          totalValue: CGFloat(total))
            
        case .progress(let progress):
            return.progress(progress: progress)
        default:
            return nil
        }
    }
}
