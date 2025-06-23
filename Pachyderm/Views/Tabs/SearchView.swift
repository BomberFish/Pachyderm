//
//  SearchView.swift
//  Pachyderm
//
//  Created by Hariz Shirazi on 2025-06-13.
//

import SwiftUI

struct SearchView: View {
    @Binding var query: String
    var body: some View {
        Text(query)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                        Text("Search")
                            .font(.title.weight(.semibold))
                            .fixedSize()
                }
                .sharedBackgroundVisibility(.hidden)
                ToolbarItem(placement: .navigationBarTrailing) {
                    AccountMenu()
                        .frame(width: AvatarUIScale.regular.rawValue, height:  AvatarUIScale.regular.rawValue)
                }
            }
    }
}

//#Preview {
//    SearchView()
//}
