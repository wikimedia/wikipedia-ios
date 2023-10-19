import Foundation
import WKData

struct SEATTaskItem: Codable, Equatable {
    let imageURL: URL
    let commonsURL: URL
    let articleTitle: String
    let articleDescription: String?
    let articleURL: URL
    let articleSummary: String

    var imageFilename: String {
        return imageURL.lastPathComponent
    }
}
final class SEATSampleData {
    
    static var shared: SEATSampleData {
        SEATSampleData(languageCode: languageCode)
    }
    
    static var languageCode: String = "en"
    
    private let languageCode: String
    private let allTasks: [String: [SEATTaskItem]] = {
        return ["en": [
                    SEATTaskItem(
                        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/3/3b/Cumberland_Basin_looking_North.jpg")!,
                        commonsURL: URL(string: "https://commons.wikimedia.org/wiki/File:Cumberland_Basin_looking_North.jpg")!,
                        articleTitle: "Chesapeake and Ohio Canal National Historical Park",
                        articleDescription: "Historic site in Maryland and Washington, D.C.",
                        articleURL: URL(string: "https://en.wikipedia.org/wiki/Chesapeake_and_Ohio_Canal_National_Historical_Park")!,
                        articleSummary: "The Chesapeake and Ohio Canal National Historical Park is located in the District of Columbia and the state of Maryland. The park was established in 1961 as a National Monument by President Dwight D. Eisenhower to preserve the neglected remains of the Chesapeake and Ohio Canal and many of its original structures."),
                    SEATTaskItem(
                        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/f/f3/Kingkongposter.jpg")!,
                        commonsURL: URL(string: "https://commons.wikimedia.org/wiki/File:Kingkongposter.jpg")!,
                        articleTitle: "The Yale Record",
                        articleDescription: nil,
                        articleURL: URL(string: "https://en.wikipedia.org/wiki/The_Yale_Record")!,
                        articleSummary: "The Yale Record is the campus humor magazine of Yale University. Founded in 1872, it became the oldest humor magazine in the world when Punch folded in 2002."),
                    SEATTaskItem(
                        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/1/16/Ichthyosaurus_anningae_trio_NT_small.jpg")!,
                        commonsURL: URL(string: "https://commons.wikimedia.org/wiki/File:Ichthyosaurus_anningae_trio_NT_small.jpg")!,
                        articleTitle: "Ichthyosauridae",
                        articleDescription: "Extinct family of reptiles",
                        articleURL: URL(string: "https://en.wikipedia.org/wiki/Ichthyosauridae")!,
                        articleSummary: "Ichthyosauridae is an extinct family of thunnosaur ichthyosaurs from the latest Triassic and Early Jurassic of Europe, and possibly also from the middle Early Cretaceous of Iraq. Named by Charles Lucien Bonaparte, in 1841, it is usually thought to contain a single genus, Ichthyosaurus, which is known from several species from the Early Jurassic. In 2013, Fischer et al. named and described Malawania anachronus from the middle Early Cretaceous of Iraq. It was found to share several synapomorphies with the type species of this family, Ichthyosaurus communis, and a large phylogenetic analysis recovered these species as sister taxa. Despite its geologically younger age, M. anachronus was also assigned to Ichthyosauridae.")
                    ],
                "es": [
                    SEATTaskItem(
                        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/b/b5/El_Valle_de_Tenza_visto_desde_el_cerro_de_Somondoco.jpg")!,
                        commonsURL: URL(string: "https://commons.wikimedia.org/wiki/File:El_Valle_de_Tenza_visto_desde_el_cerro_de_Somondoco.jpg")!,
                        articleTitle: "Valle de Tenza",
                        articleDescription: "Valle interandino en Colombia",
                        articleURL: URL(string: "https://es.wikipedia.org/wiki/Valle_de_Tenza")!,
                        articleSummary: "El Valle de Tenza es una región geográfica y cultural ubicada al sur del departamento colombiano de Boyacá y al oriente del departamento de Cundinamarca. El Valle de Tenza es atravesado por la Cordillera Oriental y por esa razón tiene un terreno muy quebrado y una gran variedad de climas que van desde el frío páramo hasta el cálido llano. Es una zona rica en fauna y flora. Sus principales actividades comerciales se basan en la agricultura y la minería, con producción de café, extracción de esmeraldas y presencia de canteras como ejemplos de estas actividades. La región es recorrida por muchos ríos y quebradas tales como el río Machetá, el Súnuba, el Garagoa o el Batá. En el lugar donde el río Súnuba se une con el río Garagoa se considera el inicio del Embalse la Esmeralda. Este embalse artificial es aprovechado para la producción de energía eléctrica en la Central Hidroeléctrica de Chivor, una de las más importantes productoras de electricidad que abastecen a gran parte del país. Las principales cabeceras municipales son Garagoa y Guateque. El Valle de Tenza tiene una población aproximada de más de 80.000 habitantes."),
                    SEATTaskItem(
                        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/1/14/Equip_de_B%C3%A0squet_de_Club_Femen%C3%AD_i_d%27Esports_de_Barcelona%2C_1930.jpg")!,
                        commonsURL: URL(string: "https://commons.wikimedia.org/wiki/File:Equip_de_B%C3%A0squet_de_Club_Femen%C3%AD_i_d%27Esports_de_Barcelona,_1930.jpg")!,
                        articleTitle: "Club Femenino y de Deportes de Barcelona",
                        articleDescription: nil,
                        articleURL: URL(string: "https://es.wikipedia.org/wiki/Club_Femenino_y_de_Deportes_de_Barcelona")!,
                        articleSummary: "El Club Femenino y de Deportes de Barcelona fue uno de los espacios de mujeres y feminista más importantes de la Barcelona de la preguerra, vinculado a propuestas políticas progresistas y catalanistas. El Club Femenino de Deportes se fundó, a iniciativa de Teresa Torrens y Enriqueta Sèculi en 1928, unos años antes del otro importante espacio de cultura de mujeres de la ciudad durante la década de los años 30, el Lyceum Club. Este último siguió un modelo europeo y fue frecuentado por las intelectuales, en cambio, el Club Femenino, fue la primera entidad deportiva exclusivamente femenina de todo el Estado español y quería tener un carácter más popular y ser asequible económicamente a más mujeres."),
                    SEATTaskItem(
                        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/0/0a/Thermite_mix.jpg")!,
                        commonsURL: URL(string: "https://commons.wikimedia.org/wiki/File:Thermite_mix.jpg")!,
                        articleTitle: "Termita (mezcla reactante)",
                        articleDescription: nil,
                        articleURL: URL(string: "https://es.wikipedia.org/wiki/Termita_(mezcla_reactante)")!,
                        articleSummary: "Termita es un tipo de composición pirotécnica de aluminio y un óxido metálico, el cual produce una reacción aluminotérmica conocida como reacción termita.")
                    ],
                "pt": [
                    SEATTaskItem(
                        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/2/21/Tempestade_de_inverno_de_1941_na_Marinha_Grande%2C_e_no_Pinhal_do_Rei.jpg")!,
                        commonsURL: URL(string: "https://commons.wikimedia.org/wiki/File:Tempestade_de_inverno_de_1941_na_Marinha_Grande,_e_no_Pinhal_do_Rei.jpg")!,
                        articleTitle: "Caminho de Ferro do Pinhal de Leiria",
                        articleDescription: nil,
                        articleURL: URL(string: "https://pt.wikipedia.org/wiki/Caminho_de_Ferro_do_Pinhal_de_Leiria")!,
                        articleSummary: "O Caminho de Ferro do Pinhal de Leiria, igualmente conhecido como Comboio de Lata, foi uma rede ferroviária no concelho de Marinha Grande, que servia o Pinhal de Leiria, em Portugal."),
                    SEATTaskItem(
                        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/4/43/Calendula_arvensis_MHNT.BOT.2007.40.81.jpg")!,
                        commonsURL: URL(string: "https://commons.wikimedia.org/wiki/File:Calendula_arvensis_MHNT.BOT.2007.40.81.jpg")!,
                        articleTitle: "Calendula arvensis",
                        articleDescription: nil,
                        articleURL: URL(string: "https://pt.wikipedia.org/wiki/Calendula_arvensis")!,
                        articleSummary: "Calendula arvensis, comummente conhecida como malmequer-dos-campos, é uma espécie de planta com flor pertencente à família das Asteráceas e ao tipo fisionómico dos terófitos."),
                    SEATTaskItem(
                        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/c/c4/Howling_wolf_02.jpg")!,
                        commonsURL: URL(string: "https://commons.wikimedia.org/wiki/File:Howling_wolf_02.jpg")!,
                        articleTitle: "Uivo",
                        articleDescription: nil,
                        articleURL: URL(string: "https://pt.wikipedia.org/wiki/Uivo")!,
                        articleSummary: "O uivo é o meio através do qual os lobos mantêm contato entre si, já que trabalham em grupo e usam deste meio de comunicação para se encontrarem quando se vêem. Os uivos são um ruído básico e desagradável aos ouvidos humanos. Usualmente, esse som é emitido por caninos solitários e, provavelmente, trata-se de um ruído para manifestar o desejo de uma companhia. Trata-se também de um ruído que contagia o grupo todo e, dessa forma, funciona como um meio de comunicação a longa distância entre grupos distintos. Também nos cães, o uivo permite uma comunicação a longa distância e a localização de membros da espécie. Entre os cães, geralmente os que costumam viver presos, o uivo é usado à noite ou durante as primeiras horas do dia, quando há pouco movimento. O uivo também é um som com algumas conotações sexuais. Machos mantidos isolados de fêmeas no cio, podem uivar continuamente. Em outros canídeos como os chacais e coiotes os uivos são como determinação de território ou mesmo pra avisar que está na área,o uivo de um lobo alcança 1 km.")
                ]
            ]
        }()
    
    private init(languageCode: String) {
        self.languageCode = languageCode
    }

    // Populate with sample data
    var availableTasks: [SEATTaskItem] {
        return allTasks[languageCode] ?? []
    }

    // Visited tasks in this session
    var visitedTasks: [SEATTaskItem] = []

    /// Give the user a task they haven't visited yet, if possible
    func nextTask() -> SEATTaskItem {
        guard !(visitedTasks.count == availableTasks.count) else {
            visitedTasks = []
            return nextTask()
        }

        guard let task = availableTasks.shuffled().randomElement() else {
            fatalError()
        }

        guard !visitedTasks.contains(where: { $0 == task }) else {
            return nextTask()
        }

        visitedTasks.append(task)
        return task
    }

}
