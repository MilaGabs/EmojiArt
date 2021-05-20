//
//  EmojiArtDocumentChooser.swift
//  EmojiArt
//
//  Created by Gabriel Teixeira on 29/04/21.
//

import SwiftUI

struct EmojiArtDocumentChooser: View {
    @EnvironmentObject var store: EmojiArtDocumentStore
    
    @State private var editMode: EditMode = .inactive // Esta eh um state que vamos usar pra saber quando nosso form vai estar em edicao e quando n estara
    
    var body: some View {
        NavigationView { // Isso ira nos possibilitar algumas vantagens, assim como a navegacao entre views
            List {
                ForEach(store.documents) { document in
                    NavigationLink(destination: EmojiArtDocumentView(document: document)
                                    .navigationBarTitle(self.store.name(for: document))
                    ) {
                        EditableText(self.store.name(for: document), isEditing: self.editMode.isEditing) { name in
                            self.store.setName(name, for: document)
                        }
                    }
                }
                .onDelete { IndexSet in // fechamento usado para deletar um item da nossa lista
                    // aqui mapeio os index para que assim possa obter quem o usuario esta querendo deletar
                    IndexSet.map { self.store.documents[$0] }.forEach { document in
                        self.store.removeDocument(document)
                    }
                }
            }
            .navigationTitle(self.store.name)
            .navigationBarItems(
                leading: Button(action: {
                    self.store.addDocument()
                }, label: {
                    Image(systemName:  "plus").imageScale(.large)
                }),
                trailing: EditButton() // este botao coloca automaticamente nosso formulario em ediçao e nos permite excluir os itens de uma lista
            )
            .environment(\.editMode, $editMode) // Desta forma sempre saberemos quando nosso form estara em edicao e qunado n estara
            // O editMode nos da isso automaticamente, este eh um recurso nativo do swift
        }
    }
}

struct EmojiArtDocumentChooser_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentChooser()
    }
}
