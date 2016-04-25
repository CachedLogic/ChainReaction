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

enum ChainableError: ErrorType {
    case CompoundError([ErrorType])
    case RecurrenceError
}

public class ChainReaction {
    
    private class Compound: Chainable {
        var nextChainable: Chainable?
        
        private let chainables: [Chainable]
        
        init(chainables: [Chainable]) {
            self.chainables = chainables
        }
        
        func activate(finishedHandler: () -> (), failureHandler: (ErrorType?) -> ()) {
            var errors = [ErrorType]()
            
            let dispatchGroup = dispatch_group_create()
            
            for chainable in self.chainables {
                dispatch_group_enter(dispatchGroup)
                
                chainable.activate({
                    dispatch_group_leave(dispatchGroup)
                }, failureHandler: { (error) in
                    if error != nil {
                        errors.append(error!)
                    }
                    
                    dispatch_group_leave(dispatchGroup)
                })
            }
            
            dispatch_group_notify(dispatchGroup, dispatch_get_main_queue()) {
                if errors.count > 0 {
                    failureHandler(ChainableError.CompoundError(errors))
                } else {
                    self.activateNext(finishedHandler, failureHandler: failureHandler)
                }
            }
        }
        
        private func activateNext(finishedHandler: () -> (), failureHandler: (ErrorType?) -> ()) {
            guard let chainable = self.nextChainable else {
                finishedHandler()
                return
            }
            
            chainable.activate(finishedHandler, failureHandler: failureHandler)
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
            guard let chainable = self.nextChainable else {
                finishedHandler()
                return
            }
        
            chainable.activate(finishedHandler, failureHandler: failureHandler)
        }
    }
    
    private var chainables = [Chainable]()
    
    public init() {
        
    }
    
    // MARK: - Add Particle
    
    private func addChainable(chainable: Chainable) {
        var lastChainable = self.chainables.last
        
        self.chainables.append(chainable)
        
        lastChainable?.nextChainable = chainable
    }
    
    /**
     
     Adds one particle to your reaction chain.
     
     This method adds one particle to your reaction chain. It will be invoked after all previously added elements executed with success. You can start the chain reaction events by invoking `initiateReaction(_:_:)` method.
     
     - parameters:
        - ((ErrorType?) -> ()) -> (): activationBehaviour Main event method for the particle.
     */
    
    public func addParticle(activationBehaviour: ((ErrorType?) -> ()) -> (), failureConditions: ((ErrorType) -> (Bool))? = nil) {
        var failureConditions = failureConditions
        
        if failureConditions == nil {
            failureConditions = { _ in return true }
        }
        
        let particle = Particle(activationBehaviour: activationBehaviour, failureConditions: failureConditions!)
        
        self.addChainable(particle)
    }
    
    // MARK: - Add Compound
    
    public func addCompound(compoundReaction: ChainReaction) {
        let compound = Compound(chainables: compoundReaction.chainables)
        
        self.addChainable(compound)
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
        self.chainables.first?.activate(finishedHandler, failureHandler: failureHandler)
    }
}