//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Gabriel Teixeira on 29/03/21.
// Este é nossa view

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    @State private var chosenPallete: String = ""
    
    // init usado para iniciar o nosso State chosenPallet
    init(document: EmojiArtDocument) {
        self.document = document
        _chosenPallete = State(wrappedValue: self.document.defaultPalette)
    }
    
    var body: some View {
        VStack {
            HStack {
                PalleteChooser(document: document, choosenPallete: $chosenPallete)
                ScrollView(.horizontal) {
                    HStack {
                        // A funcao map é utilizada para transforma uma string em um array... basicamente cada caracter da string sera uma posicao do array
                        // O $0 representa cada posicao do meu array de string, sendo uma posicao por vez eh logico
                        // O id logo abaixo torna nossa string q n eh identificavel, em algo exclusivamente identificavel, isso porque nosso ForEach so aceita
                        // elementos identificaveis. Ja o \.self é um caminho de chave no swift, usamos para especificar uma var em outro objeto
                        // logo estamos especificando a nossa var string
                        ForEach(chosenPallete.map { String($0) }, id: \.self ) { emoji in
                            Text(emoji)
                                .font(Font.system(size: self.defaultEmojiSize))
                                .onDrag { return NSItemProvider(object: emoji as NSString)}
                        }
                    }
                }
            }
            GeometryReader { geometry in
                ZStack {
                    // Abaixo um exemplo que podemos utilizar o Color. algumacoisa para como se fosse um Rectangle...
                    // Ali usamos a função overlay para que quando exista realmente uma imagem ela sobreponha meu grande retangulo branco
                    Color.white.overlay(
                        OptionalImage(uiImage: self.document.backgroundImage)
                        //Para o nosso codigo ficar melhor de entender e mais facil de se ler, criamos uma struct para tirar
                        // toda a parte semantica diretamente da nossa view... (boas praticas de swift)
                            .scaleEffect(self.zoomScale)
                            .offset(self.panOffset)
                    )
                        .gesture(self.doubleTapToZoom(in: geometry.size)) // Passo para o meu gesture alguma function q retorne uma gesture
                    if self.isLoading {
                        Image(systemName: "hourglass").imageScale(.large).spinning()
                    } else {
                        ForEach(self.document.emojis) { emoji in
                            Text(emoji.text)
                                .font(animatableWithSize: emoji.fontSize * zoomScale)
                                .position(self.position(for: emoji, in: geometry.size))
                        }
                    }
                }
                .clipped() // Isso ira manter nossa imagem dentro dos limites da nossa view
                .gesture(self.panGesture())
                .gesture(self.zoomGesture())
                .edgesIgnoringSafeArea([.horizontal, .bottom]) // Ignora a safe zone... q eh o entalhe do iphone ou a barra de apps do IPad
                .onReceive(self.document.$backgroundImage) { image in
                    self.zoomToFit(image, in: geometry.size)
                }
                // Esta funcao é a que torna possivel arrastar algo para dentro do nosso app e soltar
                // Primeiro argumento eh basicamente o q vamos aceitar q seja solto e o segundo é o q nos permite saber se estao arrastando sobre nós
                // O terceiro argumento provider, é basicamente o q esta sendo descartado do q eu soltei ali, por exemplo arrastei uma imagem e extrai
                // somente a URL dela, entao a imagem em si esta sendo descartada
                // E o ultimo argumento é sobre o local em q foi solto
                .onDrop(of: ["public.image", "public.text"], isTargeted: nil) { providers, location in
                    // aqui dentro basicamente temos q falar se a queda foi bem sussedida e tambem fazemos a conversão das coordenadas
                    // caso o q tenha sido solto aqui seja um emoji
                    var location = geometry.convert(location, from: .global)
                    location = CGPoint(x: location.x - geometry.size.width/2, y: location.y - geometry.size.height/2)
                    location = CGPoint(x: location.x - self.panOffset.width, y: location.y - self.panOffset.height)
                    location = CGPoint(x: location.x / self.zoomScale, y: location.y / self.zoomScale)
                    return self.drop(providers: providers, at: location)
                }
                .navigationBarItems(trailing: Button(action: {
                    if let url = UIPasteboard.general.url, url != self.document.backgroundURL {
                        self.confirmBackgroundPaste = true
                    } else {
                        self.explainBackgroundPaste = true
                    }
                }, label: {
                    Image(systemName: "doc.on.clipboard").imageScale(.large)
                        // Este tipo de alerta pula na tela sempre q essa variavel state muda para true
                        .alert(isPresented: $explainBackgroundPaste) {
                            return Alert(
                                title: Text("Paste Background"),
                                message: Text("Copy the URL of an image to the clip board and touch this button to make if the background of your document."),
                                dismissButton: .default(Text("OK"))
                            )
                        }
                }))
            }
            .zIndex(-1) // Isso altera a prioridade de vizualizacao... quem vem e fica a frente da tela
        }
        .alert(isPresented: $confirmBackgroundPaste) {
            Alert(
                title: Text("Paste Background"),
                message: Text("Replace your background with \(UIPasteboard.general.url?.absoluteString ?? "nothing")?"),
                primaryButton: .default(Text("OK")) {
                    self.document.backgroundURL = UIPasteboard.general.url
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    @State private var explainBackgroundPaste = false
    @State private var confirmBackgroundPaste = false
    
    var isLoading: Bool {
        document.backgroundURL != nil && document.backgroundImage == nil
    }
    
    
    // E outro state que vamos usar para enquanto meu gesto estiver acontecendo
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    
    private var zoomScale: CGFloat {
        document.steadyStateZoomScale * gestureZoomScale
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latesGestureScale, gestureZoomScale, transaction in
                // Basicamente quando passamos nossa variavel @GestureState, ela se torna propriedade desta funcao q sera chamada
                // constantemente enquanto o gesto estiver acontecendo, por esse motivo renomeamos a segunda variavel dessa funcao
                // para o mesmo nome do nosso @GestureState, essa variavel vai se encarregar de modificala para a gnt
                // aqui no caso estamos passando para ela o ultimo valor lido ...
                gestureZoomScale = latesGestureScale
            }
            .onEnded { finalGesture in
                self.document.steadyStateZoomScale *= finalGesture
            }
    }
    
    // Aqui a implementacao do clicar e arrastar para movimentar a imagem quando esta com o zoom puxado
    
    @GestureState private var gesturePanOffset: CGSize = .zero
    
    private var panOffset: CGSize {
        (document.steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, transaction in
                gesturePanOffset = latestDragGestureValue.translation / self.zoomScale
            }
            .onEnded { finalDragGestureValue in
                self.document.steadyStatePanOffset = self.document.steadyStatePanOffset + (finalDragGestureValue.translation / self.zoomScale)
            }
    }
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2) // Gesture ideal para double tap
            .onEnded {
                withAnimation {
                    zoomToFit(self.document.backgroundImage, in: size)
                }
            }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0, size.height > 0, size.width > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            self.document.steadyStatePanOffset = .zero
            self.document.steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location
        location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
        location = CGPoint(x: location.x + panOffset.width/2, y: location.y + panOffset.height/2)
        location = CGPoint(x: emoji.location.x + size.width/2, y: emoji.location.y + size.height/2)
        return location
    }

    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        // aqui verifico se o q foi solto na tela é uma URL, se sim coloco essa URL dentro do meu documento
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            self.document.backgroundURL = url
        }
        if !found {
            // aqui verifico se o q foi solto na tela é do tipo string(nosso emoji no caso), se sim adiciono o emoji ao nosso
            // document
            found = providers.loadObjects(ofType: String.self) { string in
                self.document.addEmoji(string, at: location, size: self.defaultEmojiSize)
            }
        }
        return found
    }
    
    private let defaultEmojiSize: CGFloat = 40
}
