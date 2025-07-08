//
//  ComposeView.swift
//  Pachyderm
//
//  Created by Hariz Shirazi on 2025-07-07.
//

import SwiftUI

struct ComposeView: View {
    @Environment(MastoAPI.self) var api
    @Environment(\.dismiss) var ds
    @State var text: String = ""
    @FocusState var isFocused: Bool
    var body: some View {
        ZStack {
            #if os(iOS)
            Color(UIColor.systemBackground).ignoresSafeArea(edges: .all)
            #endif
            NavigationStack {
                HStack(alignment: .top) {
                    if let me = api.me {
                        AvatarView(account: me)
                    }
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $text)
                            .focused($isFocused)
                            .onAppear {
                                isFocused = true
                            }
                        if text == "" {
                            Text("What's up?")
                                .allowsHitTesting(false)
                                .transition(.opacity)
                                .foregroundColor(.secondary)
                                .offset(y: 8)
                        }
                    }
                }
                .padding()
#if os(iOS)
                .background(Color(UIColor.systemBackground))
#endif
                .navigationTitle("New Post")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: ds.callAsFunction) {
                            Image(systemName: "xmark")
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(action: {
                            
                        }) {
                            Image(systemName: "paperplane")
                        }
                        .buttonStyle(.glassProminent)
                    }
                }
            }
        }
    }
}

//#Preview {
//    ComposeView()
//}
