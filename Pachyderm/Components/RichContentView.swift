//
//  PostContentView.swift
//  Pachyderm
//
//  Created by Hariz Shirazi on 2025-06-12.
//

import SwiftUI

struct AttributedText: UIViewRepresentable {
    let attributedString: NSAttributedString

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .natural
        
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {
        uiView.attributedText = attributedString
    }
}

struct EmojiMatch {
    let nsRange: NSRange
    let emoji: MastoAPI.Emoji
}


struct RichContentView: View {
    let content: String
    let emojis: [MastoAPI.Emoji]?
    
    @State private var attributedContent: NSAttributedString
    
    init(content: String, emojis: [MastoAPI.Emoji]?) {
        self.content = content
        self.emojis = emojis
        let plainContent = content.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
        let truncatedContent = plainContent.prefix(100) + (plainContent.count > 100 ? "..." : "")
        _attributedContent = State(initialValue: NSAttributedString(string: String(truncatedContent)))
    }
    
    var body: some View {
        AttributedText(attributedString: attributedContent)
            .task(priority: .medium) {
                self.attributedContent = await RichContentView.buildAttributedContent(content: content, emojis: emojis)
            }
    }
    
    static func buildAttributedContent(content: String, emojis: [MastoAPI.Emoji]?) async -> NSAttributedString {
        guard !content.isEmpty else { return NSAttributedString() }
        
        
        let baseFont = UIFont.preferredFont(forTextStyle: .body)
        guard let htmlData = content.data(using: .utf8) else {
            return NSAttributedString(string: content)
        }
        
        let attributedOptions: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        guard let mutableAttributedString = try? NSMutableAttributedString(data: htmlData, options: attributedOptions, documentAttributes: nil) else {
            return NSAttributedString(string: content)
        }
        
        mutableAttributedString.beginEditing()
        mutableAttributedString.enumerateAttributes(in: NSRange(location: 0, length: mutableAttributedString.length)) { attributes, range, _ in
            guard let currentFont = attributes[.font] as? UIFont else { return }
            
            let newDescriptor = baseFont.fontDescriptor.withSymbolicTraits(currentFont.fontDescriptor.symbolicTraits) ?? baseFont.fontDescriptor
            let newFont = UIFont(descriptor: newDescriptor, size: baseFont.pointSize)
            
            mutableAttributedString.addAttribute(.font, value: newFont, range: range)
        }
        mutableAttributedString.endEditing()
        
        if let emojis = emojis, !emojis.isEmpty {
            var allMatches: [EmojiMatch] = []
            let nsString = mutableAttributedString.string as NSString
            
            for emoji in emojis {
                let shortcode = ":\(emoji.shortcode):"
                var searchRange = NSRange(location: 0, length: nsString.length)
                
                while true {
                    let foundRange = nsString.range(of: shortcode, options: .literal, range: searchRange)
                    if foundRange.location == NSNotFound { break }
                    
                    allMatches.append(EmojiMatch(nsRange: foundRange, emoji: emoji))
                    
                    let newLocation = foundRange.location + foundRange.length
                    if newLocation >= nsString.length { break }
                    searchRange = NSRange(location: newLocation, length: nsString.length - newLocation)
                }
            }
            if !allMatches.isEmpty {
                let emojiAttachments = await fetchEmojiAttachments(for: allMatches)
                
                for match in allMatches.sorted(by: { $0.nsRange.location > $1.nsRange.location }) {
                    if let attachment = emojiAttachments[match.emoji.shortcode] {
                        mutableAttributedString.replaceCharacters(in: match.nsRange, with: attachment)
                    }
                }
            }
        }
        mutableAttributedString.beginEditing()
        mutableAttributedString.enumerateAttributes(in: NSRange(location: 0, length: mutableAttributedString.length)) { attributes, range, _ in
            
            if attributes[.link] != nil {
                mutableAttributedString.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: range)
                mutableAttributedString.addAttribute(.underlineStyle, value: 0, range: range)
            } else {
                mutableAttributedString.addAttribute(.foregroundColor, value: UIColor.label, range: range)
            }
        }
        mutableAttributedString.endEditing()
        
        return mutableAttributedString
    }
    
    private static func fetchEmojiAttachments(for matches: [EmojiMatch]) async -> [String: NSAttributedString] {
        await withTaskGroup(of: (String, NSAttributedString?).self, returning: [String: NSAttributedString].self) { group in
            var attachments = [String: NSAttributedString]()
            let uniqueEmojis = Set(matches.map { $0.emoji })
            
            for emoji in uniqueEmojis {
                group.addTask {
                    guard let imageUrl = URL(string: emoji.url) else { return (emoji.shortcode, nil) }
                    
                    if let (data, _) = try? await URLSession.shared.data(from: imageUrl),
                       let image = UIImage(data: data) {
                        let attachment = NSTextAttachment(image: image)
                        let fontHeight = UIFont.preferredFont(forTextStyle: .body).capHeight
                        attachment.bounds = CGRect(x: 0, y: -0.2 * fontHeight, width: 1.2 * fontHeight, height: 1.2 * fontHeight)
                        return (emoji.shortcode, NSAttributedString(attachment: attachment))
                    }
                    return (emoji.shortcode, nil)
                }
            }
            
            for await (shortcode, attachment) in group {
                if let attachment = attachment {
                    attachments[shortcode] = attachment
                }
            }
            return attachments
        }
    }
}

extension UIFont {
    func withSymbolicTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont? {
        guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else {
            return nil
        }
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}

#Preview {
    RichContentView(content: """
<p>tim time! :sweeney:</p>
<p><a href="https://epicgames.com">epic megajames</a></p>
""", emojis: [
        .init(shortcode: "sweeney", url: "https://media.wetdry.world/custom_emojis/images/000/078/110/original/b255b2bbf17e9629.png", staticUrl: "https://media.wetdry.world/custom_emojis/images/000/078/110/static/b255b2bbf17e9629.png", visibleInPicker: true)
    ])
}
