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
    
    // MARK: - Add Particle
    
    /**
     
     Adds one particle to your reaction chain.
     
     This method adds one particle to your reaction chain. It will be invoked after all previously added elements executed with success. You can start the chain reaction events by invoking `initiateReaction(_:_:)` method.
     
     - parameters:
        - ((ErrorType?) -> ()) -> (): activationBehaviour Main event method for the particle.
     */
    
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
    
    // MARK: - Add Compound
    
    public func addCompound(compoundReaction: ChainReaction) {
        
    }
    
    // MARK: - Initiate Reaction
    
    /**
     
     Initiates created chain reaction.
     
     This method initiates created chain reaction. Particles are treated as separete invocations. Compounds, comprised of particles, will be executed as a group of events, and the output result will be the accumulated results of all independent particles.
     
     - parameters:
        - () -> (): finishedHandler Success handler for whole chain reaction
        - (ErrorType?) -> (): failureHandler: Failure handler for whole chain reaction
    */
    
    public func initiateReaction(finishedHandler: () -> (), failureHandler: (ErrorType?) -> ()) {
        particles.first?.activate(finishedHandler, failureHandler: failureHandler)
    }
}