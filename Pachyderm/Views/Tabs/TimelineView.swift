//
//  TimelineView.swift
//  Pachyderm
//
//  Created by Hariz Shirazi on 2025-06-12.
//

import SwiftUI
import AVKit

struct TimelineView: View {
    @State var type = MastoAPI.TimelineType.home
    @State var posts: [MastoAPI.Post] = []
    @Environment(MastoAPI.self) private var api: MastoAPI
    @State private var isLoadingMore = false

    var body: some View {
        ScrollView {
            InfiniteScrollingPostsView(posts: $posts, isLoadingMore: $isLoadingMore, onLastItemAppeared: loadMorePosts)
        }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button("Home", systemImage: type == .home ? "checkmark" : "house") { type = .home }
                        Button("Local", systemImage: type == .local ? "checkmark" : "server.rack") { type = .local }
                        Button("Federated", systemImage: type == .federated ? "checkmark" : "network") { type = .federated }
                    } label: {
                        HStack(spacing: 4) {
                            Text(type.description)
                                .font(.title.weight(.semibold))
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                                .font(.headline)
                        }
                        .padding(.leading, 4)
                        .padding(.trailing, 2)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        
                    }) {
                        Image(systemName: "square.and.pencil")
                            .font(.title3)
                            .padding(5)
                            .offset(y:-2)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accent)
                    .frame(width: AvatarUIScale.regular.rawValue, height: AvatarUIScale.regular.rawValue)
                    .clipShape(Circle())
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    AccountMenu()
                        .frame(width: AvatarUIScale.regular.rawValue, height:  AvatarUIScale.regular.rawValue)
                }
            }
        
        .task(priority: .userInitiated) {
            await loadInitialPosts()
        }
        .refreshable {
            await refreshPosts()
        }
        .onChange(of: type) {
            Task {
                await refreshPosts()
            }
        }
    }

    func loadInitialPosts() async {
        do {
            isLoadingMore = true
            let fetchedPosts = try await api.fetchTimeline(type: type, after: nil)
            posts = fetchedPosts
            isLoadingMore = false
        } catch {
            await UIApplication.shared.alertError(error)
            isLoadingMore = false
        }
    }

    func loadMorePosts() async {
        guard !isLoadingMore, let currentLastPostId = posts.last?.id else { return }
        
        await MainActor.run {
            self.isLoadingMore = true
        }

        do {
            let newPosts = try await api.fetchTimeline(type: type, after: currentLastPostId)
            if !newPosts.isEmpty {
                posts.append(contentsOf: newPosts)
            }
        } catch {
            await UIApplication.shared.alertError(error)
        }
        
        await MainActor.run {
            self.isLoadingMore = false
        }
    }

    func refreshPosts() async {
        do {
            await MainActor.run {
                 self.isLoadingMore = true
            }
            let refreshedPosts = try await api.fetchTimeline(type: type, after: nil)
            posts = refreshedPosts
        } catch {
            await UIApplication.shared.alertError(error)
        }
        await MainActor.run {
            self.isLoadingMore = false
        }
    }
}

#Preview {
    TimelineView()
}
