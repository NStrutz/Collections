import SwiftUI
import Foundation

//Global Variables
var isOnItemView = false
class Item: Identifiable, Codable {
    var id = UUID()
    var title:String
    
    init(title:String){
        self.title = title
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
    }
}
class Collection: Codable, Identifiable {
    var id = UUID()
    var title:String
    var description:String
    var items:[Item]
    
    init(title:String, description:String, items:[Item]){
        self.title = title
        self.description = description
        self.items = items
    }
    func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(title, forKey: .title)
            try container.encode(description, forKey: .description)
            try container.encode(items, forKey: .items)
        }
}
extension Collection: Hashable {
    static func == (lhs: Collection, rhs: Collection) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Item: Hashable {
    static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ContentView: View {
  @State private var collections = [ //Sample Text used for testing
    Collection(title:"Collection 1", description: "Sample 1", items:[Item(title:"Item A"),Item(title:"Item B")]),
    Collection(title:"Collection 2", description: "Sample 2",items:[Item(title: "Item C")])
               ]
  @State private var newCollectionTitle = ""
  @State private var newDescription = ""
  @State private var newItems = [Item(title:" ")]
  @State private var isAddingCollection = false
  @State private var AddCollectionError = false


    var body: some View {
        ZStack {
            NavigationView {
                List {
                    ForEach($collections, id: \.self) { $collection in
                        NavigationLink(destination: DetailView(collectionTitle: collection.title,collectionDescription: collection.description,list:$collection.items)) {
                            Text(collection.title)
                        }
                    }
                    .onDelete(perform: delete)
                }
                .navigationTitle(Text("Collections"))
                .sheet(isPresented: $isAddingCollection) {
                    NewCollectionView(isAddingCollection: $isAddingCollection,AddCollectionError: $AddCollectionError, collections: $collections, newCollectionTitle: $newCollectionTitle, newDescription: $newDescription, newItems: $newItems)
                }
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    AddCollectionView(isAddingCollection: $isAddingCollection, AddCollectionError: $AddCollectionError)
                }
            }
        }
        .onAppear {
            collections = loadCollections()
            if collections.isEmpty {
                addSampleCollection()
            }
        }
        .onDisappear {
            saveCollections(collections: collections)
                }
    }
  func delete(at offsets: IndexSet) {
    collections.remove(atOffsets: offsets)
  }
    func saveCollections(collections:[Collection]){
        do {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .xml // or .binary for binary format

            let data = try encoder.encode(collections)
            let fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                        .appendingPathComponent("Collections.plist")
            try data.write(to: fileURL)
           } catch {
            print("Error saving collections to property list: \(error)")
                   }
    }
    func loadCollections() -> [Collection] {
            do {
                let fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                    .appendingPathComponent("Collections.plist")
                let data = try Data(contentsOf: fileURL)
                let decoder = PropertyListDecoder()
                return try decoder.decode([Collection].self, from: data)
            } catch {
                print("Error loading collections from property list: \(error)")
                return []
            }
        }
    func addSampleCollection() {
            let sampleCollection = Collection(title: "Sample Collection", description: "This is a sample collection", items: [
                Item(title: "Item 1"),
                Item(title: "Item 2"),
                Item(title: "Item 3")
            ])

            collections.append(sampleCollection)
        }
}

struct DetailView: View {
  var collectionTitle: String
  var collectionDescription: String
  @Binding var list: [Item]
  @State private var showingPopover = false

    var body: some View {
        ZStack{
                List {
                    ForEach(list, id: \.self) { item in
                        NavigationLink(destination:ItemView(ItemTitle: item.title)) {
                            Text(item.title)
                        }
                    }
                    .onDelete(perform: delete)
                }
                .navigationTitle("\(collectionTitle)")
            .if(isOnItemView == true){view in view.toolbar(.hidden)} //figure out how this works
            .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                      Button(action: {
                        showingPopover = true
                      }){
                        Image(systemName: "info.circle")
                          .imageScale(.large)
                      }
                    }
                  }
            .popover(isPresented: $showingPopover){
                VStack{
                    Text(collectionDescription)
                }
            }
        }
    }
    func delete(at offsets: IndexSet) {
      list.remove(atOffsets: offsets)
    }
  }

struct ItemView: View {
    var ItemTitle: String
    var isOnItemView = true
    var body: some View{
        NavigationView {
            Text("HIII")
        }
        .navigationTitle(Text("\(ItemTitle)"))
    }
}
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
            if condition {
                transform(self)
            } else {
                self
            }
        }
}
struct NewCollectionView: View {
  @Binding var isAddingCollection: Bool
  @Binding var AddCollectionError: Bool
  @Binding var collections: [Collection]
  @Binding var newCollectionTitle: String
  @Binding var newDescription: String
  @Binding var newItems: [Item]

  var body: some View {
    NavigationView {
      VStack {
        Divider()
        TextField("Collection title", text: $newCollectionTitle)
          .padding(.horizontal)
        TextField("Description", text: $newDescription)
            .padding(.horizontal)
        Spacer()
        Button(action: {
            if self.newCollectionTitle != ""{
                self.collections.append(Collection(title:self.newCollectionTitle, description:self.newDescription, items:self.newItems))
                self.newCollectionTitle = ""
                self.newDescription = ""
                self.isAddingCollection = false
                self.AddCollectionError = false
            }
            else {
                    self.AddCollectionError = true
                }
        }) {
          Text("Add Collection")
        }
        .padding()
        .foregroundColor(.white)
        .background(Color.blue)
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.bottom)
        if self.AddCollectionError{
                  Text("Missing Collection Name")
                .foregroundColor(.red)
                .font(.system(size: 10))
              }
        if !self.AddCollectionError{
                    Spacer()
                .frame(height: 18)
                }
      }
      .navigationBarTitle(Text("Add New Collection"))
    }
  }
}

struct AddCollectionView: View {
  @Binding var isAddingCollection: Bool
  @Binding var AddCollectionError: Bool

  var body: some View {
    Button(action: {
      self.isAddingCollection = true
      self.AddCollectionError = false
    }) {
      Image(systemName: "plus.circle.fill")
        .font(.largeTitle)
        .foregroundColor(.blue)
        .padding()
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

// Add different colors for light and dark mode
