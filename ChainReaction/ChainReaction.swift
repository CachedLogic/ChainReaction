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
    func activate(_ finishedHandler: @escaping () -> (), failureHandler: @escaping (Error?) -> ())
}

enum ChainableError: Error {
    case compoundError([Error])
    case recurrenceError
}

open class ChainReaction {
    
    fileprivate class Compound: Chainable {

        var nextChainable: Chainable?
        
        fileprivate let chainables: [Chainable]
        
        init(chainables: [Chainable]) {
            self.chainables = chainables
        }

        internal func activate(_ finishedHandler: @escaping () -> (), failureHandler: @escaping (Error?) -> ()) {
            var errors = [Error]()
            
            let dispatchGroup = DispatchGroup()
            
            for var chainable in self.chainables {
                dispatchGroup.enter()
                
                chainable.nextChainable = nil
                chainable.activate({
                    dispatchGroup.leave()
                    }, failureHandler: { (error) in
                        if error != nil {
                            errors.append(error!)
                        }
                        
                        dispatchGroup.leave()
                })
            }
            
            dispatchGroup.notify(queue: DispatchQueue.main) {
                if errors.count > 0 {
                    failureHandler(ChainableError.compoundError(errors))
                } else {
                    self.activateNext(finishedHandler, failureHandler: failureHandler)
                }
            }
        }
        
        fileprivate func activateNext(_ finishedHandler: @escaping () -> (), failureHandler: @escaping (Error?) -> ()) {
            guard let chainable = self.nextChainable else {
                finishedHandler()
                return
            }
            
            chainable.activate(finishedHandler, failureHandler: failureHandler)
        }
    }
    
    fileprivate class Particle: Chainable {

        var nextChainable: Chainable?
        
        let activationBehaviour: (@escaping (Error?) -> ()) -> ()
        let failureConditions: (Error) -> (Bool)
        
        init(activationBehaviour: @escaping (@escaping (Error?) -> ()) -> (), failureConditions: @escaping ((Error) -> (Bool)), nextChainable: Chainable? = nil) {
            self.activationBehaviour = activationBehaviour
            self.failureConditions = failureConditions
            
            self.nextChainable = nextChainable
        }
        
        internal func activate(_ finishedHandler: @escaping () -> (), failureHandler: @escaping (Error?) -> ()) {
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
        
        fileprivate func activateNext(_ finishedHandler: @escaping () -> (), failureHandler: @escaping (Error?) -> ()) {
            guard let chainable = self.nextChainable else {
                finishedHandler()
                return
            }
        
            chainable.activate(finishedHandler, failureHandler: failureHandler)
        }
    }
    
    fileprivate var chainables = [Chainable]()
    
    public init() {
        
    }
    
    // MARK: - Add Particle
    
    fileprivate func addChainable(_ chainable: Chainable) {
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

    open func addParticle(_ activationBehaviour: @escaping (@escaping (Error?) -> ()) -> ()) {
        let failureConditions: (Error) -> (Bool) = { _ in return true }
        
        let particle = Particle(activationBehaviour: activationBehaviour, failureConditions: failureConditions)
        
        self.addChainable(particle)
    }

    
    open func addParticle(_ activationBehaviour: @escaping (@escaping (Error?) -> ()) -> (), failureConditions: @escaping (Error) -> (Bool)) {
        let particle = Particle(activationBehaviour: activationBehaviour, failureConditions: failureConditions)
        
        self.addChainable(particle)
    }
    
    /**
     
     Adds compound reaction. This reaction is executed asynchronously, and finishes only when all of the particles finish executing.
     
     This method adds all of the `ChainReaction` objects particles and executes them asynchronously. This chainable element finishes after all of the added particles finish. On failure, `failureHandler` can return a `ChainableError.CompoundError`, which contains array of `ErrorType` elements. This array contains every error that occurred while executing this compound reaction.
     
     - parameters:
        - ChainReaction: compoundReaction Compund reaction chain reaction object
     */
    
    // MARK: - Add Compound
    
    open func addCompound(_ compoundReaction: ChainReaction) {
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
    
    open func initiateReaction(_ finishedHandler: @escaping () -> (), failureHandler: @escaping (Error?) -> ()) {
        self.chainables.first?.activate(finishedHandler, failureHandler: failureHandler)
    }
}
