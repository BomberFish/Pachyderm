//
//  MessagesView.swift
//  Pachyderm
//
//  Created by Hariz Shirazi on 2025-06-13.
//

import SwiftUI

struct MessagesView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            .toolbar {
                if #available(iOS 19.0, *) {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Text("Direct Messages")
                            .font(.title.weight(.semibold))
                            .fixedSize()
                            .padding(.leading, 4)
                    }
                    .sharedBackgroundVisibility(.hidden)
                } else {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Text("Direct Messages")
                            .font(.title.weight(.semibold))
                            .fixedSize()
                            .padding(.leading, 4)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    AccountMenu()
                        .frame(width: AvatarUIScale.regular.rawValue, height:  AvatarUIScale.regular.rawValue)
                }
            }
    }
}

#Preview {
    MessagesView()
}
