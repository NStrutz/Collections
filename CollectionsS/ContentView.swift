//
//  ContentView.swift
//  CollectionsS
//
//  Created by Nic-Alexander Strutz on 25.01.23.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    var body: some View {
        HStack(alignment: .bottom) {
            Text("Monster Cans")
                .font(.title)
            Spacer()
            Text("Num:3")
                
        }
        .padding()
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
