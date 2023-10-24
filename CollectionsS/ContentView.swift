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
    var description: String
    
    init(title:String, description:String){
        self.title = title
        self.description = description
    }
    init(title:String, photo:Data, description:String){
        self.title = title
        self.photo = photo
        self.description = description
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(photo, forKey: .photo)
        try container.encode(description, forKey: .description)
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
    Collection(title:"", description: "", items:[Item(title:"", description:"")])]
  @State private var newCollectionTitle = ""
  @State private var newItemTitle = ""
  @State private var newItemDescription = ""
  @State private var newDescription = ""
  @State private var newItems = [Item(title:"Sample", description: "Sample Description")]
  @State private var isAddingCollection = false
  @State private var isAddingItem = false
  @State private var AddCollectionError = false
  @State private var AddItemError = false
  @State private var updater = false


    var body: some View {
        ZStack {
            NavigationView {
                List {
                    ForEach($collections, id: \.self) { $collection in
                        NavigationLink(destination: DetailView(collectionTitle: collection.title,collectionDescription: collection.description,list:$collection.items, updater: $updater)) {
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
                .background(Color(.systemGroupedBackground))
                .navigationTitle(Text("Collections"))
                .sheet(isPresented: $isAddingCollection) {
                    NewCollectionView(isAddingCollection: $isAddingCollection,AddCollectionError: $AddCollectionError, collections: $collections, newCollectionTitle: $newCollectionTitle, newDescription: $newDescription, newItems: $newItems)
                        .onDisappear() {
                            newCollectionTitle = ""
                            newDescription = ""
                        }
                }
                .sheet(isPresented:$isAddingItem){
                    NewItemView(isAddingItem:$isAddingItem, collections: $collections, newItemTitle: $newItemTitle, updater: $updater, newItemDescription: $newItemDescription, AddItemError: $AddItemError)
                        .onDisappear(){
                            newItemTitle = ""
                        }
                }
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    AddView(isAddingCollection: $isAddingCollection, AddCollectionError: $AddCollectionError, isAddingItem: $isAddingItem, AddItemError: $AddItemError)
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
                Item(title: "Item 1", description: "This is a sample item"),
                Item(title: "Item 2", description: "This is a sample item"),
                Item(title: "Item 3", description: "This is a sample item")
            ])

            collections.append(sampleCollection)
        }
}

struct DetailView: View {
  @State private var listStyleDisplay = "TextImg"
  var collectionTitle: String
  var collectionDescription: String
  @Binding var list: [Item]
  @Binding var updater: Bool
  @State private var showingPopover = false
  @State private var photoData = Data()
  @State private var emptyData = Data()

    var body: some View {
        ZStack{
            if listStyleDisplay == "Img" {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 0), GridItem(.flexible(), spacing: 0)], spacing: 0) {
                        ForEach(list, id: \.self) { item in
                            NavigationLink(destination:ItemView(ItemTitle: item.title, ItemDescription: item.description, ItemPhoto: item.photo ?? Data(), list: $list)) {
                                ZStack {
                                    if item.photo != nil && item.photo != emptyData{
                                        if let photoData = item.photo {
                                            if let image = UIImage(data: photoData){
                                                Image(uiImage:image)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: UIScreen.main.bounds.width / 2, height: UIScreen.main.bounds.width / 2)
                                                    .clipped()
                                            }
                                        }
                                    } else {
                                        Text(item.title)
                                            .foregroundColor(Color.black)
                                    }
                                }
                                .frame(width: UIScreen.main.bounds.width / 2, height: UIScreen.main.bounds.width / 2)
                                .background(Color.white)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.black.opacity(0.2), lineWidth: 2))
                            }
                            .contextMenu {
                                Button(role: .destructive)  {
                                    if let index = list.firstIndex(of: item){
                                        list.remove(at: index)
                                        updater = !updater
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("\(collectionTitle)")
            .if(isOnItemView == true){view in view.toolbar(.hidden)}
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Picker("Display", selection: $listStyleDisplay) {
                        Image(systemName: "text.justify").tag("Text")
                        Image(systemName: "list.dash").tag("TextImg")
                        Image(systemName: "squareshape.split.2x2").tag("Img")
                    }
                    .pickerStyle(.segmented)
                }
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
            } else {
                List {
                    ForEach(list, id: \.self) { item in
                        NavigationLink(destination:ItemView(ItemTitle: item.title, ItemDescription: item.description, ItemPhoto: item.photo ?? Data(), list: $list)) {
                            if listStyleDisplay == "TextImg"{
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
                            else if listStyleDisplay == "Text" {
                                HStack{
                                    Text(item.title)
                                }
                            }
                        }
                    }
                    .onDelete(perform: delete)
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("\(collectionTitle)")
            .if(isOnItemView == true){view in view.toolbar(.hidden)}
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Picker("Display", selection: $listStyleDisplay) {
                        Image(systemName: "text.justify").tag("Text")
                        Image(systemName: "list.dash").tag("TextImg")
                        Image(systemName: "squareshape.split.2x2").tag("Img")
                    }
                    .pickerStyle(.segmented)
                }
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
    }
    func delete(at offsets: IndexSet) {
      list.remove(atOffsets: offsets)
      updater = !updater
    }
  }

struct ItemView: View {
    var ItemTitle: String
    var ItemDescription: String
    var isOnItemView = true
    var ItemPhoto = Data()
    @Binding var list: [Item]
    var body: some View{
        NavigationView {
            VStack{
                if ItemDescription.replacingOccurrences(of: " ", with: "") != "" {
                    Text("\(ItemDescription)")
                } else {
                    Text("No Description provided")
                        .foregroundColor(Color.gray.opacity(0.7))
                }
                if let photoData = ItemPhoto {
                    if let image = UIImage(data: photoData){
                        Image(uiImage:image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 200)
                            .clipped()
                    }
                }
                Spacer()
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
            if self.newCollectionTitle.replacingOccurrences(of: " ", with: "") != ""{
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

struct NewItemView: View {
    @Binding var isAddingItem: Bool
    @Binding var collections: [Collection]
    @Binding var newItemTitle: String
    @Binding var updater: Bool
    @Binding var newItemDescription: String
    @State private var selectedCollection: Collection? = nil
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @Binding var AddItemError: Bool

    var body: some View {
      NavigationView {
          if selectedCollection == nil {
              VStack{
                  if !collections.isEmpty{ //consider greying out the add items button
                      List{
                          ForEach(collections, id: \.self) { name in
                              Button(action: {
                                  selectedCollection = name
                              }){
                                  Text(name.title)
                              }
                          }
                      }
                  } else {
                      Text("No Available Collections")
                  }
              }
              .navigationBarTitle(Text("Select Collection"))
          }
          else {
              VStack {
                  Divider()
                  TextField("Item Title", text: $newItemTitle)
                      .padding(.horizontal)
                  TextField("Item Description", text: $newItemDescription)
                      .padding(.horizontal)
                  Divider()
                  HStack{
                      if let selectedPhotoData,
                         let image = UIImage(data: selectedPhotoData){
                          Image(uiImage:image)
                              .resizable()
                              .aspectRatio(contentMode: .fill)
                              .frame(width: 100, height: 100, alignment: .leading)
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
                      if self.newItemTitle.replacingOccurrences(of: " ", with: "") != ""{
                          if let selectedCollection = selectedCollection {
                              selectedCollection.items.append(Item(title:newItemTitle, photo:selectedPhotoData ?? Data(), description: newItemDescription))
                              updater = !updater
                          }
                          self.isAddingItem = false
                          self.newItemTitle = ""
                          self.AddItemError = false
                      } else {
                          self.AddItemError = true
                      }
                  }){
                      Text("Add Item")
                  }
                  .padding()
                  .foregroundColor(.white)
                  .background(Color.blue)
                  .cornerRadius(10)
                  .padding(.horizontal)
                  .padding(.bottom)
                  if self.AddItemError{
                            Text("Missing Item Name")
                          .foregroundColor(.red)
                          .font(.system(size: 10))
                        }
                  if !self.AddItemError{
                              Spacer()
                          .frame(height: 18)
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
  @Binding var AddItemError: Bool

    var body: some View {
        Menu{
            Button("Add Collection"){
                self.isAddingCollection = true
                self.AddCollectionError = false
            }
            Button("Add Item"){
                self.isAddingItem = true
                self.AddItemError = false
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


//Add rewards system??
//Add favorites
// maintain the type of view being shown when leaving collections
