//
//  PostCell.swift
//  Pachyderm
//
//  Created by Hariz Shirazi on 2025-06-13.
//

import SwiftUI
import AVKit

struct PostCell: View {
    @Binding var post: MastoAPI.Status
    let rebloggedAuthor: MastoAPI.Account?
    @Environment(MastoAPI.self) private var api: MastoAPI
    
    @State private var showFullContent = false
    
    init(post: Binding<MastoAPI.Status>) {
        if post.wrappedValue.reblog != nil {
            self._post = .init(get: {
                post.wrappedValue.reblog ?? post.wrappedValue
            }, set: {
                let updatedPost = post.wrappedValue
                updatedPost.reblog = $0
                post.wrappedValue = updatedPost
            })
            self.rebloggedAuthor = post.wrappedValue.account
        } else {
            self._post = post
            self.rebloggedAuthor = nil
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let rebloggedAuthor = rebloggedAuthor {
//                ZStack {
                    NavigationLink(destination: AccountView(initialAccount: rebloggedAuthor)) {
//                        EmptyView()
//                    }
//                    .opacity(0)
//                    .frame(width: 0, height: 0)
                    Label("\(rebloggedAuthor.displayName ?? rebloggedAuthor.acct) boosted", systemImage: "arrow.2.squarepath")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                }
            }
            
            PostHeader(account: post.account, reblogger: rebloggedAuthor)
            
            if post.sensitive {
                if let cw = post.spoilerText {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.slash")
                        Text(cw)
                    }
                    .foregroundStyle(.primary)
                    .font(.headline)
                }
                
                Button(action: {
                    withAnimation(.bouncy) {
                        showFullContent.toggle()
                    }
                }) {
                    Group {
                        Label("Show Content", systemImage: showFullContent ? "chevron.up" : "chevron.down")
                            .contentTransition(.symbolEffect(.automatic))
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.primary)
                }
                .glassButton()
                .controlSize(.large)
            }
            
            if showFullContent || !post.sensitive {
//                NavigationLink(destination: PostDetailView(post: $post)) {
                    RichContentView(content: post.content, emojis: post.emojis)
//                }
                if let mediaAttachments = post.mediaAttachments, !mediaAttachments.isEmpty {
                    if mediaAttachments.count == 1 {
                        Attachment(attachment: mediaAttachments[0])
                            .padding(.vertical, 4)
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                            ForEach(mediaAttachments) { attachment in
                                Attachment(attachment: attachment)
                                    .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            HStack(spacing: 18) {
                HStack(spacing: 2) {
                    Image(systemName: "arrowshape.turn.up.left")
                    if post.repliesCount > 0 {
                        Text("\(post.repliesCount)")
                    }
                }
                Button(action: {
                    Haptic.shared.play(.light)
                    Task {
                        do {
                            post = try await api.favourite(post)
                        } catch {
                            await UIApplication.shared.alertError(error)
                        }
                    }
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: post.favourited == true ? "heart.fill" : "heart")
                            .symbolEffect(.bounce, value: post.favourited)
                        if post.favouritesCount > 0 {
                            Text("\(post.favouritesCount)")
                                .contentTransition(.numericText())
                        }
                    }
                    .foregroundColor(post.favourited == true ? .red : .secondary)
                }
                Button(action: {
                    Haptic.shared.play(.light)
                    Task {
                        do {
                            post = try await api.reblog(post)
                        } catch {
                            await UIApplication.shared.alertError(error)
                        }
                    }
                }) {
                    HStack(spacing: 2) {
                        if #available(iOS 19.0, *) {
                            Image(systemName: "arrow.2.squarepath")
                                .symbolEffect(.rotate, value: post.reblogged)
                        } else {
                            Image(systemName: "arrow.2.squarepath")
                        }
                        if post.reblogsCount > 0 {
                            Text("\(post.reblogsCount)")
                                .contentTransition(.numericText())
                        }
                    }
                    .foregroundColor(post.reblogged == true ? .green : .secondary)
                    .animation(.default, value: post.reblogged)
                    
                }
                Spacer()
                Group {
                    ShareLink(item: .init(post.url ?? post.uri)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Menu(content: {Text("todo")}, label: {Image(systemName: "ellipsis")})
                }
                .onTapGesture {
                    Haptic.shared.play(.light)
                }
            }
            .foregroundStyle(.secondary)
            .padding(.top, 4)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 3)
        .padding(.vertical, 4)
        .id(post.id)
    }
}

struct Attachment: View {
    let attachment: MastoAPI.MediaAttachment
    var body: some View {
        Group {
            switch attachment.type {
            case "image":
                AsyncImage(url: URL(string: attachment.previewUrl ?? attachment.url)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .accessibilityLabel(attachment.description ?? "Image Attachment")
                } placeholder: {
                    ZStack {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                        ProgressView()
                    }
                }
            case "video":
                VideoPlayer(player: AVPlayer(url: URL(string: attachment.url) ?? URL(fileURLWithPath: "")))
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .accessibilityLabel(attachment.description ?? "Video Attachment")
            default:
                Link(destination: URL(string: attachment.url) ?? URL(fileURLWithPath: "")) {
                    Label(URL(string: attachment.url)?.lastPathComponent ?? "Attachment", systemImage: "link")
                }
                
            }
        }
        
        .cornerRadius(14)
    }
}



struct PostHeader: View {
    public let account: MastoAPI.Account
    public let reblogger: MastoAPI.Account?
    var body: some View {
        NavigationLink(destination: AccountView(initialAccount: account)) {
            HStack {
                ZStack {
                    //               NavigationLink(destination: AccountView(initialAccount: account)) {
                    //                   EmptyView()
                    //                }
                    //               .opacity(0)
                    //               .frame(width: 0, height: 0)
                    AvatarView(account: account, size: .small)
                    if let reblogger = reblogger {
                        AvatarView(account: reblogger, size: .xs)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: -1, y: -1)
                            .offset(x: 12, y: 12)
                    }
                }
                VStack(alignment: .leading) {
                    RichContentView(content: account.displayName ?? account.acct, emojis: account.emojis ?? [])
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("@\(account.acct)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
