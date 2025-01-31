//
//  ReadView.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 20.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
struct ReadView: View {
    @State private var cardOffset: CGSize = .init(width: -220, height: -160)
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                NFCFieldView(isAnimationOn: true)
                    .frame(width: 240, height: 240)
                    .offset(y: -160)
                
                CardView()
                    .frame(width: 210, height: 130)
                    .offset(cardOffset)
                    .animation(Animation
                                .easeInOut(duration: 1)
                                .delay(1)
                                .repeatForever())
                
                PhoneView()
                    .frame(width: 180, height: 360)
            }
            .frame(width: geo.size.width,
                   height: geo.size.height)
        }
        .onAppear {
            cardOffset.width = 0
        }
    }
}

@available(iOS 13.0, *)
struct ReadView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ReadView()
            ReadView()
                .preferredColorScheme(.dark)
        }
        .environmentObject(TangemSdkStyle())
    }
}
