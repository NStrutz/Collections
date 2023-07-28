//
//
//Developed by Nic-Alexander Strutz for a Computer Science IA
//Many thanks to ChatGPT
// Version: 28 July 2023
//I am defeated


import SwiftUI
import Foundation
import PhotosUI

//Global Variables
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
    var incImage: Bool //Standing for inc Image, i.e. does the collection include images
    
    init(title:String, description:String, items:[Item], incImage: Bool){
        self.title = title
        self.description = description
        self.items = items
        self.incImage = incImage
    }
    func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(title, forKey: .title)
            try container.encode(description, forKey: .description)
            try container.encode(items, forKey: .items)
            try container.encode(incImage, forKey: .incImage)
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

var Storage: [Collection] = []

func saveCollections(){
    do {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml // or .binary for binary format

        let data = try encoder.encode(Storage)
        let fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                    .appendingPathComponent("Collections.plist")
        try data.write(to: fileURL)
        } catch {
        print("Error saving collections to property list: \(error)")
                }
}
func loadCollections() {
        do {
            let fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                .appendingPathComponent("Collections.plist")
            let data = try Data(contentsOf: fileURL)
            let decoder = PropertyListDecoder()
            Storage = try decoder.decode([Collection].self, from: data)
        } catch {
            print("Error loading collections from property list: \(error)")
            Storage = []
        }
    }
func addSampleCollection() {
        let sampleCollection = Collection(title: "Sample Collection", description: "This is a sample collection", items: [
            Item(title: "Item 1"),
            Item(title: "Item 2"),
            Item(title: "Item 3")],
            incImage: false)

        Storage.append(sampleCollection)
}


struct ContentView: View {
  @State private var newItemTitle = ""
  @State private var isAddingCollection = false
  @State private var isAddingItem = false
  @State private var AddCollectionError = false
  @State private var updater = false

    var body: some View {
        ZStack {
            NavigationView {
                List {
                    ForEach(Storage, id: \.self) { collection in
                        NavigationLink(destination: DetailView(collectionTitle: collection.title,collectionDescription: collection.description,list: collection.items, updater: $updater, incImage: collection.incImage)) {
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
                    NewCollectionView(isAddingCollection: $isAddingCollection,AddCollectionError: $AddCollectionError)
                }
                .sheet(isPresented:$isAddingItem){
                    NewItemView(isAddingItem:$isAddingItem, newItemTitle: $newItemTitle, updater: $updater)
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
            loadCollections()
            if Storage.isEmpty {
                addSampleCollection()
            }
        }
        .onDisappear {
            saveCollections()
                }
        
    }
  func delete(at offsets: IndexSet) {
    Storage.remove(atOffsets: offsets)
  }
}

struct DetailView: View {
  var collectionTitle: String
  var collectionDescription: String
  @Binding var list: [Item]
  @Binding var updater: Bool
  @State private var showingPopover = false
  @State private var photoData = Data()
  var incImage: Bool

    var body: some View {
        ZStack{
            List {
                ForEach(list, id: \.self)  { item in
                        NavigationLink(destination:ItemView(ItemTitle: item.title, ItemPhoto: item.photo ?? Data())) {
                            HStack{
                                if let photoData = item.photo {
                                    if let image = UIImage(data: photoData){
                                        Image(uiImage:image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 50, height: 50)
                                            .clipped()
                                    }
                                }
                                Text(item.title)
                            }
                        }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("\(collectionTitle)")
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
                    if collectionDescription.trimmingCharacters(in: .whitespacesAndNewlines) != ""{
                        Text(collectionDescription)
                    }
                    else {
                        Text("No Description")
                    }
                    Text("Includes Images: " + String(incImage).capitalized)
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
    var ItemPhoto: Data?
    
    var body: some View{
        NavigationView {
            VStack{
                Text("HIII")
                if let ItemPhoto = ItemPhoto {
                    if let image = UIImage(data: ItemPhoto){
                        Image(uiImage:image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipped()
                    }
                }
            }
        }
        .navigationTitle(Text("\(ItemTitle)"))
    }
}


struct NewCollectionView: View {
  @Binding var isAddingCollection: Bool
  @Binding var AddCollectionError: Bool
  @State private var newCollectionTitle = ""
  @State private var newDescription = ""
  @State private var newItems = [Item(title:"Sample")]
  @State private var incImage = false

  var body: some View {
    NavigationView {
      VStack {
        Divider()
        TextField("Collection title", text: $newCollectionTitle)
          .padding(.horizontal)
        TextField("Description", text: $newDescription)
            .padding(.horizontal)
          Divider()
          Toggle("hi", isOn: $incImage)
              .tint(.blue)
        Spacer()
        Button(action: {
            if self.newCollectionTitle != ""{
                Storage.append(Collection(title:self.newCollectionTitle, description:self.newDescription, items:self.newItems, incImage:self.incImage))
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
                      ForEach(Storage, id: \.self) { name in
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
                  if (selectedCollection?.incImage == true) {
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
