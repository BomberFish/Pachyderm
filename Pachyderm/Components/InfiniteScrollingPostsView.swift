import SwiftUI

struct InfiniteScrollingPostsView: View {
    @Binding var posts: [MastoAPI.Status]
    @Binding var isLoadingMore: Bool
    let onLastItemAppeared: () async -> Void
    
    init(
        posts: Binding<[MastoAPI.Status]>,
        isLoadingMore: Binding<Bool>,
        onLastItemAppeared: @escaping () async -> Void
    ) {
        _posts = posts
        _isLoadingMore = isLoadingMore
        self.onLastItemAppeared = onLastItemAppeared
    }
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(Array(posts.indices), id: \.self) { index in
                let postBinding = $posts[index]
//                NavigationLink(destination: PostDetailView(post: postBinding)) {
                    PostCell(post: postBinding)
//                        .onAppear {
//                            if posts[index].id == posts.last?.id && !isLoadingMore {
//                                Task {
//                                    await onLastItemAppeared()
//                                }
//                            }
//                        }
                    .task(priority: .userInitiated) {
                        if posts[index].id == posts.last?.id && !isLoadingMore {
                            await onLastItemAppeared()
                        }
                    }
//                }
                .padding(.vertical, 4)
                if index < posts.count - 1 {
                    Divider()
                }
            }
            
            if isLoadingMore {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding(.horizontal)
    }
}
