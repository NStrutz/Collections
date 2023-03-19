import SwiftUI

//Gloabl Variables
var isOnItemView = false
struct ContentView: View {
  @State private var buttons = ["Button 1", "Button 2"]
  @State private var newButtonTitle = ""
  @State private var isAddingButton = false
  @State private var AddButtonError = false


  var body: some View {
    ZStack {
      NavigationView {
        List {
          ForEach(buttons, id: \.self) { button in
            NavigationLink(destination: DetailView(buttonTitle: button)) {
              Text(button)
            }
          }
          .onDelete(perform: delete)
        }
        .navigationTitle(Text("Collections"))
        .sheet(isPresented: $isAddingButton) {
          NewButtonView(isAddingButton: $isAddingButton,AddButtonError: $AddButtonError, buttons: $buttons, newButtonTitle: $newButtonTitle)
        }
      }
      
      VStack {
        Spacer()
        HStack {
          Spacer()
          AddButtonView(isAddingButton: $isAddingButton, AddButtonError: $AddButtonError)
        }
      }
    }
  }

  func delete(at offsets: IndexSet) {
    buttons.remove(atOffsets: offsets)
  }
}

struct DetailView: View {
  var buttonTitle: String
  @State private var list = ["Hi", "Hello"]

    var body: some View {
        Spacer(minLength: 1) /// Adds and removes the top white line when clicking on a collection
        ZStack{
            NavigationView {
                List {
                    ForEach(list, id: \.self) { ListItem in
                        NavigationLink(destination:ItemView(ItemTitle: ListItem)) {
                            Text(ListItem)
                        }
                    }
                    .onDelete(perform: delete)
                }
                .navigationTitle("\(buttonTitle)")
            }
            .if(isOnItemView == true){view in view.toolbar(.hidden)} //figure out how this works
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
        Text("HIII")
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
struct NewButtonView: View {
  @Binding var isAddingButton: Bool
  @Binding var AddButtonError: Bool
  @Binding var buttons: [String]
  @Binding var newButtonTitle: String

  var body: some View {
    NavigationView {
      VStack {
        TextField("Button title", text: $newButtonTitle)
          .padding(.horizontal)
        Spacer()
        Button(action: {
            if self.newButtonTitle != ""{
                self.buttons.append(self.newButtonTitle)
                self.newButtonTitle = ""
                self.isAddingButton = false
                self.AddButtonError = false
            }
            else {
                    self.AddButtonError = true
                }
        }) {
          Text("Add Button")
        }
        .padding()
        .foregroundColor(.white)
        .background(Color.blue)
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.bottom)
        if self.AddButtonError{
                  Text("Missing Button Name")
                .foregroundColor(.red)
                .font(.system(size: 10))
              }
        if !self.AddButtonError{
                    Spacer()
                .frame(height: 18)
                }
      }
      .navigationBarTitle(Text("Add New Button"))
    }
  }
}

struct AddButtonView: View {
  @Binding var isAddingButton: Bool
  @Binding var AddButtonError: Bool

  var body: some View {
    Button(action: {
      self.isAddingButton = true
      self.AddButtonError = false
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
