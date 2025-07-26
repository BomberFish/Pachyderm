//
//  AccountView.swift
//  Pachyderm
//
//  Created by Hariz Shirazi on 2025-06-13.
//

import SwiftUI
import PerceptionCore

struct AccountView: View {
    @Environment(MastoAPI.self) private var api: MastoAPI
    public let initialAccount: MastoAPI.Account
    @State private var account: MastoAPI.Account
    @State var posts: [MastoAPI.Status] = []
    @State var view: MastoAPI.AccountViewType = .default
    @State private var isLoadingMore = false

    init(initialAccount: MastoAPI.Account) {
        self.initialAccount = initialAccount
        self._account = State(initialValue: initialAccount)
    }

    var body: some View {
        WithPerceptionTracking {
            ScrollView {
                VStack {
                    AccountHeaderView(account: $account)
                        .padding(.horizontal)
                    
                    Picker("View Type", selection: $view) {
                        Text("Posts").tag(MastoAPI.AccountViewType.default)
                        Text("Replies").tag(MastoAPI.AccountViewType.withReplies)
                        Text("Media").tag(MastoAPI.AccountViewType.onlyMedia)
                    }
                    .pickerStyle(.segmented)
                    .padding(.bottom, 8)
                    .padding(.horizontal)
                }
                
                InfiniteScrollingPostsView(posts: $posts, isLoadingMore: $isLoadingMore, onLastItemAppeared: loadMorePosts)
            }
            .navigationTitle(account.displayName ?? account.username)
            .task(priority: .userInitiated) {
                await loadInitialData()
            }
            .refreshable {
                await refreshPosts()
            }
            .onChange(of: view) {_ in
                Task {
                    await refreshPosts()
                }
            }
        }
    }

    func loadInitialData() async {
        isLoadingMore = true
        do {
            let fetchedAccountDetails = try await api.account(id: initialAccount.id)
            await MainActor.run {
                self.account = fetchedAccountDetails
            }

            let fetchedPosts = try await api.accountPosts(for: initialAccount, view: view, after: nil)
            await MainActor.run {
                self.posts = fetchedPosts
            }
        } catch {
            await UIApplication.shared.alertError(error)
        }
        isLoadingMore = false
    }

    func loadMorePosts() async {
        guard !isLoadingMore, let lastPostId = posts.last?.id else { return }

        isLoadingMore = true
        do {
            let newPosts = try await api.accountPosts(for: account, view: view, after: lastPostId)
            if !newPosts.isEmpty {
                await MainActor.run {
                    posts.append(contentsOf: newPosts)
                }
            }
        } catch {
            print("Error fetching more account posts: \(error)")
            await UIApplication.shared.alertError(error)
        }
        isLoadingMore = false
    }

    func refreshPosts() async {
        isLoadingMore = true
        do {

            let refreshedPosts = try await api.accountPosts(for: account, view: view, after: nil)
            await MainActor.run {
                self.posts = refreshedPosts
            }
        } catch {
            print("Error refreshing account posts: \(error)")
            await UIApplication.shared.alertError(error)
        }
        isLoadingMore = false
    }
}

struct AccountHeaderView: View {
    @Binding var account: MastoAPI.Account

    var body: some View {
        VStack(alignment: .leading) {
            CachedAsyncImage(url: URL(string: account.avatar)) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } placeholder: {
                ProgressView()
            }

            Text(account.displayName ?? account.username)
                .font(.headline)
                .padding(.top, 8)

            RichContentView(content: account.note, emojis: account.emojis ?? [])

            HStack {
                Text("Followers: \(account.followersCount)")
                Spacer()
                Text("Following: \(account.followingCount)")
            }
            .font(.footnote)
            .foregroundColor(.secondary)
            .padding(.top, 4)

        }
        .padding(.vertical)
    }
}

//#Preview {
//    AccountView()
//}
