//
//
//Developed by Nic-Alexander Strutz for a Computer Science IA
//
// Version: 18 September 2023


import SwiftUI
import Foundation
import PhotosUI

//Global Variables
var isOnItemView = false
class Item: Identifiable, Codable {
    var id = UUID()
    var title:String
    var photo: Data?
    
    init(title:String){
        self.title = title
    }
    init(title:String, photo:Data){
        self.title = title
        self.photo = photo
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(photo, forKey: .photo)
    }
}
class Collection: Codable, Identifiable {
    var id = UUID()
    var title:String
    var description:String
    var items:[Item]
    var showingImage: Bool
    
    init(title:String, description:String, items:[Item], showingImage: Bool){
        self.title = title
        self.description = description
        self.items = items
        self.showingImage = showingImage
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
    Collection(title:"", description: "", items:[Item(title:"")], showingImage: false)]
  @State private var newCollectionTitle = ""
  @State private var newItemTitle = ""
  @State private var newDescription = ""
  @State private var newItems = [Item(title:"Sample")]
  @State private var isAddingCollection = false
  @State private var isAddingItem = false
  @State private var AddCollectionError = false
  @State private var updater = false


    var body: some View {
        ZStack {
            NavigationView {
                List {
                    ForEach($collections, id: \.self) { $collection in
                        NavigationLink(destination: DetailView(collectionTitle: collection.title,collectionDescription: collection.description,list:$collection.items, updater: $updater, showingImage: $collection.showingImage)) {
                            HStack{
                                Text(collection.title)
                                Spacer()
                                Text(String(updater))
                                    .hidden()
                                Text(String(collection.items.count) + " Items")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .onDelete(perform: delete)
                }
                .navigationTitle(Text("Collections"))
                .sheet(isPresented: $isAddingCollection) {
                    NewCollectionView(isAddingCollection: $isAddingCollection,AddCollectionError: $AddCollectionError, collections: $collections, newCollectionTitle: $newCollectionTitle, newDescription: $newDescription, newItems: $newItems)
                }
                .sheet(isPresented:$isAddingItem){
                    NewItemView(isAddingItem:$isAddingItem, collections: $collections, newItemTitle: $newItemTitle, updater: $updater)
                }
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    AddView(isAddingCollection: $isAddingCollection, AddCollectionError: $AddCollectionError, isAddingItem: $isAddingItem)
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
            ], showingImage: false)

            collections.append(sampleCollection)
        }
}

struct DetailView: View {
  @State private var listStyleDisplay = true
  var collectionTitle: String
  var collectionDescription: String
  @Binding var list: [Item]
  @Binding var updater: Bool
  @State private var showingPopover = false
  @State private var photoData = Data()
  @Binding var showingImage: Bool

    var body: some View {
        ZStack{
                List {
                    ForEach(list, id: \.self) { item in
                        NavigationLink(destination:ItemView(ItemTitle: item.title, ItemPhoto: item.photo ?? Data())) {
                            if listStyleDisplay {
                                HStack{
                                    if showingImage == true {
                                        if let photoData = item.photo {
                                            if let image = UIImage(data: photoData){
                                                Image(uiImage:image)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 50, height: 50)
                                                    .clipped()
                                            }
                                        }
                                    }
                                    Text(item.title)
                                }
                            } else {
                                HStack {
                                    if showingImage == true {
                                        if item.photo != nil {
                                            if let photoData = item.photo {
                                                if let image = UIImage(data: photoData){
                                                    Image(uiImage:image)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 50, height: 50)
                                                        .clipped()
                                                }
                                            }
                                        } else {
                                            Text(item.title)
                                        }
                                    }
                                }
                            }
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
                    HStack{
                        Toggle("Display images: ",isOn: $showingImage)
                            .onChange(of: showingImage) { _ in
                                if !showingImage {
                                    listStyleDisplay = true
                                }
                            }
                            //.disabled(true) in case you want to disable control
                        Spacer()
                    }
                    List {
                        Picker("Display", selection: $listStyleDisplay) {
                            Image(systemName: "list.dash").tag(true)
                            Image(systemName: "squareshape.split.2x2").tag(false)
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
        }
    }
    func delete(at offsets: IndexSet) {
      list.remove(atOffsets: offsets)
      updater = !updater
    }
  }

struct ItemView: View {
    var ItemTitle: String
    var isOnItemView = true
    var ItemPhoto = Data()
    var body: some View{
        NavigationView {
            VStack{
                Text("HIII")
                if let photoData = ItemPhoto {
                    if let image = UIImage(data: photoData){
                        Image(uiImage:image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 200)
                            .clipped()
                    }
                }
            }
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
                self.collections.append(Collection(title:self.newCollectionTitle, description:self.newDescription, items:self.newItems, showingImage: false))
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

struct NewItemView: View {
    @Binding var isAddingItem: Bool
    @Binding var collections: [Collection]
    @Binding var newItemTitle: String
    @Binding var updater: Bool
    @State private var selectedCollection: Collection? = nil
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?

    var body: some View {
      NavigationView {
          if selectedCollection == nil {
              VStack{
                  List{
                      ForEach(collections, id: \.self) { name in
                          Button(action: {
                              selectedCollection = name
                          }){
                              Text(name.title)
                          }
                      }
                  }
              }
              .navigationBarTitle(Text("Select Collection"))
          }
          else {
              VStack {
                  Divider()
                  TextField("Item title", text: $newItemTitle)
                      .padding(.horizontal)
                  HStack{
                      if let selectedPhotoData,
                         let image = UIImage(data: selectedPhotoData){
                          Image(uiImage:image)
                              .resizable()
                              .aspectRatio(contentMode: .fill)
                              .frame(width: 50, height: 50, alignment: .leading)
                      }
                      Spacer()
                          .frame(width: 100)
                      PhotosPicker(selection: $selectedItem, matching: .any(of: [.images, .not(.livePhotos)])){
                          Text("Select a Photo")
                      }
                      .onChange(of: selectedItem) { newImage in
                          Task {
                              if let data = try? await newImage?.loadTransferable(type: Data.self) {
                                  selectedPhotoData = data
                              }
                          }
                      }
                  }
                  Spacer()
                  Button(action: {
                      if let selectedCollection = selectedCollection {
                          selectedCollection.items.append(Item(title:newItemTitle, photo:selectedPhotoData ?? Data())) // could add what to do if no image is added
                          updater = !updater
                      }
                      self.isAddingItem = false
                      self.newItemTitle = ""
                  }){
                      Text("Add Item")
                  }
              }
              .navigationBarTitle(Text("Add New Item"))
          }
      }
    }
  }

struct AddView: View {
  @Binding var isAddingCollection: Bool
  @Binding var AddCollectionError: Bool
  @Binding var isAddingItem: Bool

    var body: some View {
        Menu{
            Button("Add Collection"){
                self.isAddingCollection = true
                self.AddCollectionError = false
            }
            Button("Add Item"){
                self.isAddingItem = true
            }
        } label:{
            Label("", systemImage: "plus.circle.fill")
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

//Add a message to add item screen when there is no collection
//Delete data when closing add screen
//Add rewards system??
//find a way to do all the error handeling
