//
//  ChainReactionTests.swift
//  ChainReactionTests
//
//  Created by Maciej Stramski on 19/04/16.
//  Copyright © 2016 Cached Logic. All rights reserved.
//

import Quick
import Nimble
import ChainReaction

class ChainReactionTests: QuickSpec {
    
    private var counter = 0
    
    private func successfulTestMethod(completionHandler: ((NSError?) -> ())) {
        print("Successful test method : \(counter)")
        
        counter += 1
        
        completionHandler(nil)
    }

    private func successfulAsyncTestMethod(completionHandler: ((NSError?) -> ())) {
        let randomValue = Double(random() % 100) / 2.0
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(randomValue * Double(NSEC_PER_SEC)))

        dispatch_after(delayTime, dispatch_get_main_queue()) {
            print("Successful async test method : \(self.counter)")
            
            self.counter += 1
            
            completionHandler(nil)
        }
    }

    
    override func spec() {
        describe("ChainReaction") {
            it("executes chain reaction") {
                let reaction = ChainReaction()
                
                reaction.addParticle(self.successfulTestMethod)
                
                reaction.initiateReaction({ 
                    print("Success")
                }, failureHandler: { (error) in
                    fail("Test Method should be always successful but it gave error:\n\n\(error)\n\n")
                })
            }
        }
        
        describe("CompundReaction") {
            it("executes compund chain reaction") {
                let reaction = ChainReaction()
                
                reaction.addParticle(self.successfulTestMethod)
                
                let compoundReaction = ChainReaction()
                
                compoundReaction.addParticle(self.successfulAsyncTestMethod)
                compoundReaction.addParticle(self.successfulAsyncTestMethod)
                
                reaction.addCompound(compoundReaction)
                
                reaction.initiateReaction({ 
                    // Success
                }, failureHandler: { (error) in
                    fail("Test Method should be always successful but it gave error:\n\n\(error)\n\n")
                })
            }
        }
    }
    
}
