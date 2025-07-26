//
//  AvatarView.swift
//  Pachyderm
//
//  Created by Hariz Shirazi on 2025-06-13.
//

import SwiftUI

enum AvatarUIScale: CGFloat {
    case xs = 24
    case small = 44
    case regular = 36
    case large = 64
}

struct AvatarView: View {
    let account: MastoAPI.Account
    let size: AvatarUIScale
    
    init(account: MastoAPI.Account, size: AvatarUIScale = .small) {
        self.account = account
        self.size = size
    }
    
    var body: some View {
        CachedAsyncImage(url: URL(string: account.avatar)) { image in
            image
                .resizable()
                .accessibilityLabel("Avatar of \(account.displayName ?? account.acct)") // TODO: Add support for Chuckya's profile picture alt text feature
                .aspectRatio(contentMode: .fill)
                .frame(width: size.rawValue, height: size.rawValue)
                .clipShape(Circle())
//                .padding(size == .regular ? 4 : 0)
//                .glassEffect(isEnabled: size == .regular)
        } placeholder: {
            
            ZStack {
                Rectangle()
                    .fill(.clear)
                    .frame(width: size.rawValue, height: size.rawValue)
                    .controlSize(size == .xs ? .mini : .regular)
                    .glass(isEnabled: size != .regular)
                ProgressView()
            }
        }
    }
}


struct AccountMenu: View {
    @Environment(MastoAPI.self) private var api: MastoAPI
    var body: some View {
        Menu {
            Menu(content: {
                Text("todo: account switcher")
                Button("Log Out", systemImage: "rectangle.portrait.and.arrow.right") {
                    api.login(instanceDomain: "", accessToken: "")
//                    exitApp()
                }
            }, label: {
                if let me = api.me {
                    Label(title: {Text(me.displayName ?? String(me.acct.split(separator: "@").first ?? "Unknown"))}, icon: {
                        CachedAsyncImage(url: URL(string: me.avatar)) { image in
                            image
                                .resizable()
                                .frame(width: 10, height: 10)
                                .clipShape(Circle())
                        } placeholder: {
                            ProgressView()
                        }
                        .accessibilityLabel("Switch Account")
                    })
                } else {
                    Text("Loading")
                }
            })
            if let me = api.me {
                NavigationLink(destination: AccountView(initialAccount: me)) {
                    Label("My Profile", systemImage: "person.crop.circle")
                }
            }
            Button("Settings", systemImage: "gear") {}
        } label: {
            Group {
                if let me = api.me {
                    AvatarView(account: me, size: .regular)
                } else {
                    ZStack {
                        Rectangle()
                            .fill(.clear)
                            .frame(width: AvatarUIScale.regular.rawValue, height: AvatarUIScale.regular.rawValue)
                            .controlSize(.regular)
                            .glass()
                        ProgressView()
                    }
                }
            }
                .accessibilityLabel("Account Menu")
        }
    }
}
