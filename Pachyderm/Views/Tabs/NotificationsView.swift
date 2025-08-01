//
//  NotificationsView.swift
//  Pachyderm
//
//  Created by Hariz Shirazi on 2025-06-13.
//

import SwiftUI
import PerceptionCore

struct NotificationsView: View {
    @State var notifications: [MastoAPI.Notification] = []
    @Environment(MastoAPI.self) private var api: MastoAPI
    var body: some View {
        WithPerceptionTracking {
            ScrollView {
                LazyVStack {
                    ForEach(notifications, id: \.self) { notification in
                        VStack {
                            NotificationItem(notification: notification)
                            if notification != notifications.last {
                                Divider()
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .toolbar {
                if #available(iOS 19.0, *) {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Text("Notifications")
                            .font(.title.weight(.semibold))
                            .fixedSize()
                            .padding(.leading, 4)
                    }
                    .sharedBackgroundVisibility(.hidden)
                } else {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Text("Notifications")
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
            .task {
                do {
                    notifications = try await api.notifications()
                } catch {
                    await UIApplication.shared.alertError(error)
                }
            }
        }
    }
}

struct NotificationItem: View {
    public var notification: MastoAPI.Notification
    var body: some View {
        if let st = notification.status {
            NavigationLink(destination: PostDetailView(post: .constant(st))) {
                VStack(alignment: .leading) {
                    Text(notification.type.capitalized + " from @" + notification.account.username)
                    PostCell(post: .constant(st))
                        .allowsHitTesting(false)
                }
            }
        } else {
            VStack(alignment: .leading) {
                Text(notification.type.capitalized + " from @" + notification.account.username)
            }
        }
    }
}

#Preview {
    NotificationsView()
}
