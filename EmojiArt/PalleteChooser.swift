//
//  PalleteChooser.swift
//  EmojiArt
//
//  Created by Gabriel Teixeira on 21/04/21.
//

import SwiftUI

struct PalleteChooser: View {
    @ObservedObject var document: EmojiArtDocument
    
    @Binding var choosenPallete: String
    @State var showPalleteEditor: Bool = false
    
    var body: some View {
        HStack {
            // Este é um pequeno botao de mais e menos
            Stepper(onIncrement: {
                self.choosenPallete = self.document.palette(before: self.choosenPallete)
            }, onDecrement: {
                self.choosenPallete = self.document.palette(after: self.choosenPallete)
            }, label: { EmptyView() })
            Text(self.document.paletteNames[self.choosenPallete] ?? "")
        }
        .fixedSize(horizontal: true, vertical: false)
        Image(systemName: "keyboard").imageScale(.large)  // Icone do teclado
            .onTapGesture {
                self.showPalleteEditor = true // muda o valor do nosso state para q seja possivel abrir nosso popover
            }
            // O popover serve para abrir uma caixa... um balao, como se fosse um balao de conversa dos quadrinhos. Nele podemos colocar qualquer tipo de view, ele vai ser aberto ou fechado sempre que o nosso state boolean alterar seu valor
            // Nessa situacao podemos usar tanto um popover quanto um sheet, porem em algumas solucoes o popover funciona melhor para o ipad
            .popover(isPresented: $showPalleteEditor) { // O sheet é como se fosse um modal
                PalleteEditor(chosenPallete: self.$choosenPallete, isShowing: $showPalleteEditor)
                    .environmentObject(self.document) // ler sobre o environmentObject nas nossas anotacoes, basicamente estamos passando nosso viewModel aqui
                    .frame(minWidth: 300, minHeight: 500)
            }
    }
}
// Basicamente estamos usando esta funcao para trocar o nome das nossas palletes e adicionar novos emojis a elas
struct PalleteEditor: View {
    @EnvironmentObject var document: EmojiArtDocument
    
    @Binding var chosenPallete: String
    @Binding var isShowing: Bool
    @State var palleteName: String = ""
    @State var emojisToAdd: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack{
                Text("Pallete Editor").font(.headline).padding()
                HStack {
                    Spacer()
                    Button(action: {
                        self.isShowing = false
                    }, label: { Text("Done")}).padding()
                }
            }
            Divider()
            // Com o form obtemos um srollable spacer automatico e dispensamos o uso do spacer para deixar as coisa no topo da tela
            Form{
                // E tbm ganhamos o poder de usar as section, onde podemos dividir nossa view por seçoes e ainda nomealas com titulos
                Section {
                    TextField("Pallete Name", text: $palleteName, onEditingChanged: { began in
                        if !began {
                            self.document.renamePalette(self.chosenPallete, to: self.palleteName)
                        }
                    })
                    TextField("Add Emoji", text: $emojisToAdd, onEditingChanged: { began in
                        if !began {
                            self.chosenPallete = self.document.addEmoji(self.emojisToAdd, toPalette: self.chosenPallete)
                            self.emojisToAdd = ""
                        }
                    })
                }
                Section(header: Text("Remove Emoji")) {
                    VStack {
                        Grid(chosenPallete.map { String($0) }, id: \.self) { emoji in
                            Text(emoji)
                                .font(Font.system(size: self.fontSize))
                                .onTapGesture {
                                    self.chosenPallete = self.document.removeEmoji(emoji, fromPalette: self.chosenPallete)
                                
                                }
                        }
                        .frame(height: self.height)
                    }
                }
            }
        }
        .onAppear { self.palleteName = self.document.paletteNames[self.chosenPallete] ?? "" } // Usando para iniciar nosso State palleteName
    }
    
    // MARK: - Drawing Constants
    var height: CGFloat {
        CGFloat((chosenPallete.count - 1) / 6) * 70 + 70
    }
    
    let fontSize: CGFloat = 40
}

struct PalleteChooser_Previews: PreviewProvider {
    static var previews: some View {
        PalleteChooser(document: EmojiArtDocument(), choosenPallete: Binding.constant(""))
    }
}
