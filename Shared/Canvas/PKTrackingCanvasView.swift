//
//  PKTrackingCanvasView.swift
//  HeadDraw
//
//  Created by Pawandeep Sekhon on 23/9/26.
//
import PencilKit
// Include custom callbacks on touches
final class PKTrackingCanvasView: PKCanvasView {
    
    var onTouchBegan: ((CGPoint) -> Void)?
    var onTouchMoved: ((CGPoint) -> Void)?
    var onTouchEnded: (() -> Void)?
    
    override func touchesBegan(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        super.touchesBegan(touches, with: event)
        
        //guard let touch = touches.first else { return }
        
//        let location = touch.location(in: self)
//        onTouchBegan?(location)
    }
    
    override func touchesMoved(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        super.touchesMoved(touches, with: event)
        
        //guard let touch = touches.first else { return }
//        let location = touch.location(in: self)
//        onTouchMoved?(location)
    }
    
    override func touchesEnded(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        super.touchesEnded(touches, with: event)
        
        onTouchEnded?()
    }
    
    override func touchesCancelled(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        super.touchesCancelled(touches, with: event)
        
        onTouchEnded?()
    }
}
