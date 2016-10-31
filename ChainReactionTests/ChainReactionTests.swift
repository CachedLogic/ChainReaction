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
    
    fileprivate var counter = 0
    
    fileprivate func successfulTestMethod(_ completionHandler: ((NSError?) -> ())) {
        print("\n\nSuccessful test method : \(counter)\n\n")
        
        counter += 1
        
        completionHandler(nil)
    }

    fileprivate func successfulAsyncTestMethod(_ completionHandler: ((NSError?) -> ())) {
        let randomValue = Double(random() % 10) / 10.0
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(randomValue * Double(NSEC_PER_SEC)))

        dispatch_after(delayTime, dispatch_get_main_queue()) {
            print("\n\nSuccessful async test method : \(self.counter)\n\n")
            
            self.counter += 1
            
            completionHandler(nil)
        }
    }

    
    override func spec() {
        describe("ChainReaction") {
            it("executes chain reaction") {
                let reaction = ChainReaction()
                
                reaction.addParticle(self.successfulAsyncTestMethod)
                
                var success: Bool?
                
                reaction.initiateReaction({ 
                    print("\n\nSuccess\n\n")
                    success = true
                }, failureHandler: { (error) in
                    fail("\n\nTest Method should be always successful but it gave error:\n\n\(error)\n\n")
                    success = false
                })
                
                expect(success).toEventually(beTrue(), timeout: 30)
            }
        }
        
        describe("CompundReaction") {
            it("executes compund chain reaction") {
                let reaction = ChainReaction()
                
                reaction.addParticle(self.successfulAsyncTestMethod)
                reaction.addParticle(self.successfulAsyncTestMethod)
                
                let compoundReaction = ChainReaction()
                
                compoundReaction.addParticle(self.successfulAsyncTestMethod)
                compoundReaction.addParticle(self.successfulAsyncTestMethod)
                
                reaction.addCompound(compoundReaction)
                
                var success: Bool?
                
                reaction.initiateReaction({ 
                    print("\n\nSuccess\n\n")
                    success = true
                }, failureHandler: { (error) in
                    success = false
                    fail("\n\nTest Method should be always successful but it gave error:\n\n\(error)\n\n")
                })
                
                expect(success).toEventually(beTrue(), timeout: 30)
            }
        }
    }
    
}
