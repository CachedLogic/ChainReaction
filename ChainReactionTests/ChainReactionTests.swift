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
    
    private func testMethod(completionHandler: ((NSError?) -> ())) {
        completionHandler(nil)
    }
    
    override func spec() {
        describe("ChainReaction") {
            it("executes chain reaction") {
                let reaction = ChainReaction()
                
                reaction.addParticle(self.testMethod)
                
                reaction.initiateReaction({ 
                    // Success
                }, failureHandler: { (error) in
                    fail("Test Method should be always successful but it gave error:\n\n\(error)\n\n")
                })
            }
        }
    }
    
}
