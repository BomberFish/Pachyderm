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
    @State var visibility: MastoAPI.Visibility = .public
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
                                .offset(x: 4, y: 10)
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
                        .clipShape(Circle())
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(action: {
                            do {
                                throw "Not implemented yet"
                            } catch {
                                UIApplication.shared.alertError(error)
                            }
                        }) {
                            Image(systemName: "paperplane")
                        }
                        .clipShape(Circle())
                        .buttonStyle(.glassProminent)
                        .clipShape(Circle())
                    }
                    ToolbarItemGroup(placement: .keyboard) {
                        Button("Attach", systemImage: "paperclip") {}
                        Button("Emoji", systemImage: "smiley") {}
                        Button("Poll", systemImage: "chart.bar.yaxis") {}
                    }
                    ToolbarItem(placement: .keyboard) { Spacer() }
                    ToolbarItemGroup(placement: .keyboard) {
                        Button("Content Warning", systemImage: "eye.slash") {}
                        Picker(selection: $visibility, content: {
                            ForEach(MastoAPI.Visibility.allCases, id: \.rawValue) {type in
                                Label(type.description, systemImage: type.icon)
                                    .tag(type)
                            }
                        }, label: {
                            Image(systemName: visibility.icon)
                                .accessibilityLabel("Visibility: \(visibility.description)")
                        })
                    }
                    if text.count > 0 {
                        ToolbarItem(placement: .keyboard) { Spacer() }
                        ToolbarItem(placement: .keyboard) {
                            Button("Add to thread", systemImage: "plus") {}
                        }
                    }
                }
            }
        }
    }
}

//#Preview {
//    ComposeView()
//}
