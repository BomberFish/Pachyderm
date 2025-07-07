//
//  NotificationsView.swift
//  Pachyderm
//
//  Created by Hariz Shirazi on 2025-06-13.
//

import SwiftUI

struct NotificationsView: View {
    @State var notifications: [MastoAPI.Notification] = []
    @Environment(MastoAPI.self) private var api: MastoAPI
    var body: some View {
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
            ToolbarItem(placement: .navigationBarLeading) {
                Text("Notifications")
                    .font(.title.weight(.semibold))
                    .fixedSize()
                    .padding(.leading, 4)
            }
            .sharedBackgroundVisibility(.hidden)
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

struct NotificationItem: View {
    public var notification: MastoAPI.Notification
    var body: some View {
        NavigationLink(destination: PostDetailView(post: .constant(notification.status))) {
            VStack(alignment: .leading) {
                Text(notification.type.capitalized + " from @" + notification.account.username)
                PostCell(post: .constant(notification.status))
                    .allowsHitTesting(false)
            }
        }
    }
}

#Preview {
    NotificationsView()
}
