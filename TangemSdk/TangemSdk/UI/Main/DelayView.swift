//
//  DelayView.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 23.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
struct DelayView: View {
    let currentValue: CGFloat
    let totalValue: CGFloat
    let labelValue: CGFloat
    
    @EnvironmentObject var style: TangemSdkStyle

    private var targetDelay: CGFloat {
        1.0 - (totalValue - currentValue)/totalValue
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(style.colors.indicatorBackground, lineWidth: 15)
            
            Circle()
                .trim(from: 0, to: targetDelay)
                .stroke(style.colors.tint, lineWidth: 15)
                .rotationEffect(Angle(degrees: -90))
                .animation(.linear(duration: 0.9))
            
            CounterView(currentDelay: Int(labelValue),
                        totalDelay: Int(totalValue))
        }
    }
}

@available(iOS 13.0, *)
struct DelayView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DelayView(currentValue: 3, totalValue: 5, labelValue: 4)
                .frame(width: 200, height: 200)
            DelayView(currentValue: 3, totalValue: 5, labelValue: 4)
                .preferredColorScheme(.dark)
                .frame(width: 200, height: 200)
        }
        .environmentObject(TangemSdkStyle())
    }
}