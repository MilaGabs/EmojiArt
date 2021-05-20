//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Gabriel Teixeira on 29/03/21.
//  Este é nosso viewModel, chamamos de document, porque em nossa aplicacao vamos poder ter mais de um documento salvo... vamos poder ter varios

import SwiftUI
import Combine

class EmojiArtDocument: ObservableObject, Hashable, Identifiable {
    
    static func == (lhs: EmojiArtDocument, rhs: EmojiArtDocument) -> Bool {
        lhs.id == rhs.id
    }
    
    let id: UUID
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Aqui vamos criar nossos emojis q vao no topo da nossa aplicacao, como podemos ter varios documentos e cada um utilizando um viewModel
    // entao n vamos usar uma variavel q eh uma instancia e sim uma static var
    static let pallete: String = "⭐️🌧🌎🥨🍎⚾️"
    
    @Published private var emojiArt: EmojiArt
    
    // Aqui criamos esta var para encapsular o .sink q esta acontecendo no init, pois assim que o init finalizar,
    // o .synk sera descartado e nos n queremos isso
    private var autosaveCancellable: AnyCancellable?
    
    init(id: UUID? = nil) {
        self.id = id ?? UUID()
        let defaultsKey = "EmojiArtDocument.\(self.id.uuid)"
        emojiArt = EmojiArt(json: UserDefaults.standard.data(forKey: defaultsKey)) ?? EmojiArt()
        // Abaixo estamos utilizando o valor projetado do nosso Publisher, para que seja possivel salvar o nosso document
        // Aqui usamos da mesma forma que esta esplicado nas nossas anotaçoes
        autosaveCancellable = $emojiArt.sink { emojiArt in
            UserDefaults.standard.set(emojiArt.json, forKey: defaultsKey)
        }
        
        fetchBackgroundImageData()
    }
    
    @Published private(set) var backgroundImage: UIImage?
    
    // É um state pq vai afetar a nossa view
    // Nos gestos n discretos precisamos ter dois tipos de estado ... um estacionario, onde o valor nao vai se alterar
    // enquanto um gesto esta acontecendo
    @Published var steadyStateZoomScale: CGFloat = 1.0
    @Published var steadyStatePanOffset: CGSize = .zero
    
    var emojis: [EmojiArt.Emoji] { emojiArt.emojis }
    
    // MARK: - Intent(s)
    
    func addEmoji(_ emoji: String, at location: CGPoint, size: CGFloat) {
        emojiArt.addEmoji(emoji, x: Int(location.x), y: Int(location.y), size: Int(size))
    }
    
    func moveEmoji(_ emoji: EmojiArt.Emoji, by offset: CGSize) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArt.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrEven))
        }
    }
    
    var backgroundURL: URL? {
        get {
            emojiArt.backgroundURL
        }
        set {
            emojiArt.backgroundURL = newValue?.imageURL
            fetchBackgroundImageData()
        }
    }
    
    private var fetchImageCancellable: AnyCancellable?
    private func fetchBackgroundImageData() {
        backgroundImage = nil
        if let url = self.emojiArt.backgroundURL {
            // Coloco a pesquisa da minha imagem na internet dentro de uma thread para n travar a execucao da minha thread principal
            // Utilizo a prioridade como userInitiated pois foi o usuario q iniciou essa ação no momento em q ele arrastou a imagem na tela
            //DispatchQueue.global(qos: .userInitiated).async {
                // Verifico se é possivel acessar minha url ou se ela existe na internet, se der timeOut retorno um nil por conta do meu Try
                //if let imageData = try? Data(contentsOf: url) {
                    // Sincronizando minha threde global com a minha Main Thread para poder "retornar minha imagem para minha view"
                   // DispatchQueue.main.async {
                       // if url == self.emojiArt.backgroundURL {
                          //  self.backgroundImage = UIImage(data: imageData)
                       // }
                    //}
                //}
            //}
            // Deixamos de usar o metodo acima pois ele n é tao inteligente e nem é configuravel
            // O codigo abaixo é bem melhor, usaremos um publisher para ele
            
            // Isso cancela a solicitacao anterior caso tenha alguma pendente, e impede que uma solicitacao passada q ainda n retornou
            // retorne e pule na frente de nossa tela
            fetchImageCancellable?.cancel()
            fetchImageCancellable = URLSession.shared.dataTaskPublisher(for: url)
                .map { data, urlResponse in UIImage(data: data) } // Convertemos a tupla que recebemos do publisher para image
                .receive(on: DispatchQueue.main ) // Como o URLSession nao é executado na fila principal, utilizamos o receive
                // para fazer com que nosso publisher publique nossa imagem na main
                .replaceError(with: nil) // Ira nos retornar uma imagem nula caso aconteça um erro
                .assign(to: \.backgroundImage, on: self) // Isso nos permite atribuir a saida do nosso publisher para uma variavel especifica
            
        }
    }
}

extension EmojiArt.Emoji {
    var fontSize: CGFloat { CGFloat(self.size) }
    var location: CGPoint { CGPoint(x: CGFloat(x), y: CGFloat(y)) }
}
