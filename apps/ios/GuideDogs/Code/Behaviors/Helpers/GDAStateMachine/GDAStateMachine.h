//
//  GDAStateMachine.h
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//
//  Description:
//
//  This class represents a state machine. A state machine is constructed with states and events and
//  begins in an initial state. As events occur, the state machine takes transitions from input states
//  to output states, as specified in the event declarations.
//

@import Foundation;
#import "GDAStateMachineDelegate.h"

// State enter action.
typedef void (^GDAStateEnterAction)(id object, NSString ** nextStateName, id * nextStateObject);

// State exit action.
typedef void (^GDAStateExitAction)(void);

// GDAStateMachineState interface.
@interface GDAStateMachineState : NSObject

// Properties.
@property (nonatomic, readonly) NSString * name;
@property (nonatomic, readonly) NSTimeInterval timeout;
@property (nonatomic, readonly) GDAStateEnterAction enterAction;
@property (nonatomic, readonly) GDAStateExitAction exitAction;

// Class initializer.
- (instancetype)initWithName:(NSString *)name
                     timeout:(NSTimeInterval)timeout
                 enterAction:(GDAStateEnterAction)enterAction
                  exitAction:(GDAStateExitAction)exitAction;

@end

// GDAStateMachineEvent interface.
@interface GDAStateMachineEvent : NSObject

// Properties.
@property (nonatomic, readonly) NSString * name;
@property (nonatomic, readonly) NSDictionary<NSString *, NSString *> * transitions;

// Class initializer.
- (instancetype)initWithName:(NSString *)name
                 transitions:(NSDictionary<NSString *, NSString *> *)transitions;

@end

// GDAStateMachine interface.
@interface GDAStateMachine : NSObject

// Properties.
@property (nonatomic, weak) id<GDAStateMachineDelegate> delegate;
@property (nonatomic, readonly) NSString * name;
@property (nonatomic, readonly) NSString * previousStateName;
@property (nonatomic, readonly) GDAStateMachineState * currentState;

// Returns a new state machine.
+ (instancetype)stateMachineWithName:(NSString *)name
                              states:(NSArray<GDAStateMachineState *> *)states
                              events:(NSArray<GDAStateMachineEvent *> *)events;

// Returns a new state machine.
+ (instancetype)stateMachineWithName:(NSString *)name
                              states:(NSArray<GDAStateMachineState *> *)states
                              events:(NSArray<GDAStateMachineEvent *> *)events
                    defaultStateName:(NSString *)defaultStateName;

// Returns a new state machine state.
+ (id)stateWithName:(NSString *)name
            timeout:(NSTimeInterval)timeout
        enterAction:(GDAStateEnterAction)enterAction
         exitAction:(GDAStateExitAction)exitAction;

// Returns a new state machine event.
+ (id)eventWithName:(NSString *)name
        transitions:(NSDictionary<NSString *, NSString *> *)transitions;

// Fires an event by name.
- (BOOL)fireEventWithName:(NSString *)eventName;

// Fires an event by name.
- (BOOL)fireEventWithName:(NSString *)eventName
                   object:(id)object;

@end
