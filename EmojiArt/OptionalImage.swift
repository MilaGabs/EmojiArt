//
//  OptionalImage.swift
//  EmojiArt
//
//  Created by Gabriel Teixeira on 13/04/21.
//

import SwiftUI

struct OptionalImage: View {
    var uiImage: UIImage?
    
    var body: some View {
        Group { // Utilizamos um Group aqui pois n podemos retornar um nulo para o overlay... nesse caso se n retornarmos uma imagem vamos retornar um group vazio
            if uiImage != nil {
                Image(uiImage: uiImage!)
            }
        }
    }
}
