//
//  ContentView.swift
//  Pachyderm
//
//  Created by Hariz Shirazi on 2025-06-12.
//

import SwiftUI

struct RootView: View {
    @AppStorage("baseURL") private var instanceDomain: String = ""
    @AppStorage("accessToken") private var accessToken: String = ""
    
    @State private var api = MastoAPI(
        instanceDomain: UserDefaults.standard.string(forKey: "baseURL") ?? "mastodon.social",
        accessToken: UserDefaults.standard.string(forKey: "accessToken") ?? ""
    )
    
    var body: some View {
        Group {
            if accessToken.isEmpty {
                SetupView(baseURL: $instanceDomain, accessToken: $accessToken)
            } else {
               MainView()
            }
        }
        .environment(api)
    }
}

struct MainView: View {
    @Environment(MastoAPI.self) private var api: MastoAPI
    @State private var searchQuery: String = ""
    var body: some View {
        Group {
            if #available(iOS 18.0, *) {
                if #available(iOS 19.0, *) {
                    TabView {
                        Tab("Home", systemImage: "square.stack.fill") {
                            NavigationStack {
                                TimelineView()
                            }
                        }
                        Tab("Notifications", systemImage: "bell") {
                            NavigationStack {
                                NotificationsView()
                            }
                        }
                        Tab("Messages", systemImage: "bubble.left.and.bubble.right") {
                            NavigationStack {
                                MessagesView()
                            }
                        }
                        Tab(role: .search) {
                            NavigationStack {
                                SearchView(query: $searchQuery)
                            }
                        }
                    }
                    .searchable(text: $searchQuery, prompt: "Search posts, users, hashtags")
                    .tabBarMinimizeBehavior(.onScrollDown)
                    .navigationBarTitleDisplayMode(.large)
                } else {
                    TabView {
                        Tab("Home", systemImage: "square.stack.fill") {
                            NavigationStack {
                                TimelineView()
                            }
                        }
                        Tab("Notifications", systemImage: "bell") {
                            NavigationStack {
                                NotificationsView()
                            }
                        }
                        Tab("Messages", systemImage: "bubble.left.and.bubble.right") {
                            NavigationStack {
                                MessagesView()
                            }
                        }
                        Tab(role: .search) {
                            NavigationStack {
                                SearchView(query: $searchQuery)
                            }
                        }
                    }
                    .searchable(text: $searchQuery, prompt: "Search posts, users, hashtags")
                    .navigationBarTitleDisplayMode(.large)
                }
            } else {
                
            }
        }
        .environment(api)
    }
}

#Preview {
    RootView()
}
