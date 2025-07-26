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
                if #available(iOS 19.0, *) {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Text("Search")
                            .font(.title.weight(.semibold))
                            .fixedSize()
                            .padding(.leading, 4)
                    }
                    .sharedBackgroundVisibility(.hidden)
                } else {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Text("Search")
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
//            .if(!is26) {
//                $0.searchable(text: $query)
//            }
    }
}

//#Preview {
//    SearchView()
//}
