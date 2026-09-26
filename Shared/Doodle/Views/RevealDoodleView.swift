//
//  RevealDoodleView.swift
//  HeadDraw-iOS
//
//  Created by Pawandeep Sekhon on 26/9/26.
//
// A sheet to view the completed doodle
import SwiftUI

struct RevealDoodleView: View {
    // share handler
    let onDoodleShare: () -> Void
    // new doodle <- basically clear everything, and restart again
    let onNewDoodle: () -> Void
    // save doodle
    let onDoodleSave: () -> Void
    
    var body: some View {
        ZStack {
            VStack {
                    // Prompt
                HStack {
                    Text("Your doodle is ready!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.bottom, 10)
                }
                
                    // image
                    // Todo: allow play/pause in future for playback
                RoundedRectangle(cornerRadius: 14)
                    .frame(height: 350)
                
                    // Button
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Button {
                                // Share
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(
                            MinimalButtonStyle(
                                backgroundColor: .clear,
                                foregroundColor: .primary,
                                borderColor: Color.primary.opacity(0.2)
                            )
                        )
                        
                        Button {
                                // New Doodle
                        } label: {
                            Label("New Doodle", systemImage: "plus")
                        }
                        .buttonStyle(
                            MinimalButtonStyle(
                                backgroundColor: .clear,
                                foregroundColor: .primary,
                                borderColor: Color.primary.opacity(0.2)
                            )
                        )
                    }
                    
                    Button {
                            // Save
                        //TODO: pass the data
                        onDoodleSave()
                    } label: {
                        Label("Save", systemImage: "checkmark")
                    }
                    .buttonStyle(
                        MinimalButtonStyle(
                            backgroundColor: .primary,
                            foregroundColor: Color(.systemBackground),
                            borderColor: .primary
                        )
                    )
                }
                .padding()
            }
            .padding()
            
            // Confetti
            ConfettiView()
                .ignoresSafeArea()
                .allowsHitTesting(false) // Allows tapping buttons underneath
        }
    }
}

#Preview {
    RevealDoodleView {
        //
    } onNewDoodle: {
        //
    } onDoodleSave: {
        //
    }

}
