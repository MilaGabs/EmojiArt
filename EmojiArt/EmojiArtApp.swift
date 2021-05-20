//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Gabriel Teixeira on 29/03/21.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    let store = EmojiArtDocumentStore(named: "Emoji Art")
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentChooser().environmentObject(store)
        }
    }
}
