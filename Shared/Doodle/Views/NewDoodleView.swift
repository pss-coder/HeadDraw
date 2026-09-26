//
//  NewDoodleView.swift
//  HeadDraw-iOS
//
//  Created by Pawandeep Sekhon on 26/9/26.
//

import SwiftUI
import Combine

struct NewDoodleView: View {
    let onDoodleCompleted: () -> Void
    @Environment(\.dismiss) private var dismiss


    @State private var timeRemaining: TimeInterval = 3
    @State private var hasFinished = false


    
    private let timer = Timer
        .publish(every: 1, on: .main, in: .common)
        .autoconnect()

    var body: some View {
        VStack {
            
            prompt
           
            //TODO: Canvas here
            RoundedRectangle(cornerRadius: 14)
                .foregroundStyle(.blue)
                .padding(.horizontal)
                .foregroundStyle(.gray)
                
            
            statusInfo
        }
        .toolbar(content: {
            ToolbarItem(placement: .destructiveAction) {
                Button {
                    //
                } label: {
                    Image(systemName: "stop.fill")
                }
                .foregroundStyle(Color.red)

            }
        })
        .onReceive(timer) { _ in
            guard !hasFinished else { return }

            if timeRemaining > 0 {
                timeRemaining -= 1
            }
            if timeRemaining <= 0 {
                hasFinished = true
                //TODO: Pass the data
                // Instead: show a modal, for user to view, and save,
                // otherwise dismiss
                //onDoodleFinished()
                onDoodleCompleted()
            }
        }
        
    }
    
    private var statusInfo: some View {
        HStack {
            Label {
                Text("Status")
            } icon: {
                Image(systemName: "eye")
            }
            Spacer()
                // timer text with circular progress
            
            HStack {
                Text(formatTime(timeRemaining))
                    .font(.system(.subheadline, design: .monospaced))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 24) // Vertical spacing inside the card
        .padding(.horizontal)
    }
    
    private var prompt: some View {
        VStack {
            Text("Doodle: Cat")
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16) // Vertical spacing inside the card
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    Color(.gray).opacity(0.3)
                ) // Adapts to Dark Mode automatically
        )
        .padding(.horizontal) // Spacing outside the card from screen edges
    }
    
    
    private func formatTime(_ time: TimeInterval) -> String {
        let seconds = max(0, Int(time))
        return String(format: "00:%02d", seconds)
    }
}

#Preview {
    NewDoodleView(onDoodleCompleted: {})
}
