//
//  EmojiArt.swift
//  EmojiArt
//
//  Created by Gabriel Teixeira on 31/03/21.
//  Este é nosso model, ele ira representar basicamente o background do nosso documento

import Foundation
// Vamos tornar nossa struct Encodable para q possamos transformala em um JSON, com isso temos q transformala em Decodable
// Para q assim possamos transformar o JSON em nossa struct novamente.
// Onde no caso para fazer os dois temos um protocol q ja herda delas e podemos usa-lo --> Codable
struct EmojiArt: Codable {
    var backgroundURL: URL? // Sera do tipo optional pois quando criarmos nosso documento ele vira com o fundo em branco
    var emojis = [Emoji]()
    
    struct Emoji: Identifiable, Codable {
        let text: String
        var x: Int
        var y: Int
        var size: Int
        var id: Int
        
        // Olhando esse INIT aqui abaixo, vc deve estar pensando ué mais esse init eu obtenho gratuitamente por padrao
        // teoricamente só estou reescrevendo algo q ja existe
        // porem aqui eu defino ele como fileprivate, o que me garante q um Emoji só vai ser criado de dentro do meu model
        // impossibilitanto de outras pessoas criarem isso com qualquer id ou pior com um id repetido... garanto q meu id
        // vai ser unico e vai ser criado usando minha funcao addEmoji
        // O fileprivate torna isso privado para qualquer pessoa fora desse arquivo, porem funcoes daqui de dentro
        // podem chama-lo sem problema nenhum 
        fileprivate init(text: String, x: Int, y: Int, size: Int, id: Int) {
            self.text = text
            self.x = x
            self.y = y
            self.size = size
            self.id = id
        }
    }
    
    // Aqui é a unica coisa q precisamos fazer para tornar nosso EmojiArt em um JSON
    // E com isso vamos poder persistir esse documento em algum lugar
    var json: Data? {
        return try? JSONEncoder().encode(self)
    }
    
    // Para decodificarmos um json q vamos receber, usaremos o init para criarmos um novo EmojiArt
    // Para garantirmos q se o nosso json for nulo sera retornado um valor nulo para que esta tentando utilizar o init
    // transformamos ele em um optional, caso contrario ele voltaria um emojiArt em branco
    init?(json: Data?) {
        // Aqui verificamos se o json recebino no criador n eh nulo, caso n seja verificamos se é possivel decodificalo para o tipo
        // EmojiArt
        if json != nil, let newEmojiArt = try? JSONDecoder().decode(EmojiArt.self, from: json!) {
            self = newEmojiArt
        } else {
            return nil
        }
    }
    
    // Ja q com o init criado acima ... perdemos nosso init padrao que o swift nos da, para que possamos iniciar todas as variaveis
    // automaticamente com seus valores padrao, nos precisamos especificar ele novamente
    init() { }
    
    private var uniqueEmojiId = 0
    
    mutating func addEmoji(_ text: String, x: Int, y: Int, size: Int) {
        uniqueEmojiId += 1
        emojis.append(Emoji(text: text, x: x, y: y, size: size, id: uniqueEmojiId))
    }
    
}
