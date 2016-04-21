//
//  ChainReaction.swift
//  Loyalty
//
//  Created by Maciej Stramski on 29/03/16.
//  Copyright © 2016 Cached Logic. All rights reserved.
//
import Foundation

private protocol Chainable {
    var nextChainable: Chainable? { get set }
    func activate(finishedHandler: () -> (), failureHandler: (ErrorType?) -> ())
}

public class ChainReaction {
    
    private class Compound: Chainable {
        var nextChainable: Chainable?
        
        private let particles: [Particle]
        
        init(particles: [Particle]) {
            self.particles = particles
        }
        
        func activate(finishedHandler: () -> (), failureHandler: (ErrorType?) -> ()) {
            var errors = [ErrorType?]()
            
            let particleFinishedHandler: (ErrorType?) -> () = { (error) -> () in
                // TODO: Implement finished handler
            }
            
            for particle in particles {
                dispatch_async(dispatch_get_main_queue()) {
                    particle.activate({ 
                        particleFinishedHandler(nil)
                    }, failureHandler: { (error) in
                        particleFinishedHandler(error)
                    })
                }
            }
        }
    }
    
    private class Particle: Chainable {
        var nextChainable: Chainable?
        
        let activationBehaviour: ((ErrorType?) -> ()) -> ()
        let failureConditions: ((ErrorType) -> (Bool))
        
        init(activationBehaviour: ((ErrorType?) -> ()) -> (), failureConditions: ((ErrorType) -> (Bool)), nextChainable: Chainable? = nil) {
            self.activationBehaviour = activationBehaviour
            self.failureConditions = failureConditions
            
            self.nextChainable = nextChainable
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
            guard let reaction = self.nextChainable else {
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