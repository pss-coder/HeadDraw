//
//  HomeView.swift
//  HeadDraw
//
//  Created by Pawandeep Sekhon on 19/9/26.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("Gallery")
                    .font(.title)
                    .fontWeight(.bold)
                
                Button {
                        //on tapped
                } label: {
                    HStack {
                        Image(systemName: "pencil.line")
                        Text("Start Drawing")
                    }
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .buttonSizing(.flexible)
                .buttonBorderShape(.roundedRectangle(radius: 8))
                
                // Have a list here
                List {
                    
                    NavigationLink("Drawing 1") {
                        
                        Text("Drawing 1 Detail")
                        
                    }
                    
                    NavigationLink("Drawing 2") {
                        
                        Text("Drawing 2 Detail")
                        
                    }
                    
                    NavigationLink("Drawing 3") {
                        
                        Text("Drawing 3 Detail")
                        
                    }
                    
                }
                
                .listStyle(.plain)
                
                .frame(maxHeight: .infinity)
            }
            .padding()
        }
    }
}

#Preview {
    HomeView()
}
