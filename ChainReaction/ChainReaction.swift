//
//  ChainReaction.swift
//  Loyalty
//
//  Created by Maciej Stramski on 29/03/16.
//  Copyright © 2016 Cached Logic. All rights reserved.
//

public class ChainReaction {
    
    private class Particle {
        var nextParticle: Particle?
        
        let activationBehaviour: ((ErrorType?) -> ()) -> ()
        let failureConditions: ((ErrorType) -> (Bool))
        
        init(activationBehaviour: ((ErrorType?) -> ()) -> (), failureConditions: ((ErrorType) -> (Bool)), nextParticle: Particle? = nil) {
            self.activationBehaviour = activationBehaviour
            self.failureConditions = failureConditions
            
            self.nextParticle = nextParticle
        }
        
        func activate(finishedHandler: () -> (), failureHandler: (ErrorType?) -> ()) {
            self.activationBehaviour() { (error) -> () in
                if error == nil {
                    self.activateNext(finishedHandler, failureHandler: failureHandler)
                } else {
                    if self.failureConditions(error!) {
                        failureHandler(error)
                    } else {
                        self.activateNext(finishedHandler, failureHandler: failureHandler)
                    }
                }
            }
        }
        
        private func activateNext(finishedHandler: () -> (), failureHandler: (ErrorType?) -> ()) {
            guard let reaction = self.nextParticle else {
                finishedHandler()
                return
            }
            
            reaction.activate(finishedHandler, failureHandler: failureHandler)
        }
    }
    
    private var particles = [Particle]()
    
    public init() {
        
    }
    
    public func addParticle(activationBehaviour: ((ErrorType?) -> ()) -> (), failureConditions: ((ErrorType) -> (Bool))? = nil) {
        let lastParticle = particles.last
        var failureConditions = failureConditions
        
        if failureConditions == nil {
            failureConditions = { _ in return true }
        }
        
        let particle = Particle(activationBehaviour: activationBehaviour, failureConditions: failureConditions!)
        
        particles.append(particle)
        
        if let lastParticle = lastParticle {
            lastParticle.nextParticle = particle
        }
    }
    
    public func initiateReaction(finishedHandler: () -> (), failureHandler: (ErrorType?) -> ()) {
        particles.first?.activate(finishedHandler, failureHandler: failureHandler)
    }
}