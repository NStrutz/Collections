//
//  Screen2.swift
//  CollectionsS
//
//  Created by Nic-Alexander Strutz on 25.01.23.
//

import SwiftUI
import PhotosUI

struct Screen2: View {
    @State private var Item1: PhotosPickerItem?
    @State private var Image1: Image?
    var body: some View {
        HStack {
            PhotosPicker("Select", selection: $Item1, matching: .images)
            
            if let Image1 {
                Image1
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50,height:50)
            }
        }
        .onChange(of: Item1){ _ in Task {
            if let data = try? await Item1?.loadTransferable(type: Data.self){
                if let uiImage = UIImage(data: data){
                    Image1 = Image(uiImage: uiImage)
                    return
                }
            }
        }
            
        }
        
            
    }
}

struct Screen2_Previews: PreviewProvider {
    static var previews: some View {
        Screen2()
    }
}
