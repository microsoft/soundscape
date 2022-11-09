//
//  GDAStateMachineDelegate.h
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//
//  Description:
//
//  This protocol defines the events that emitted by the GDAStateMachine class.
//

// Forward declarations.
@class GDAStateMachine;
@class GDAStateMachineState;
@class GDAStateMachineEvent;

// GDAStateMachineDelegate protocol.
@protocol GDAStateMachineDelegate <NSObject>
@required

// Notifies the delegate of a state machine error.
- (void)stateMachineError:(GDAStateMachine *)stateMachine;

// Notifies the delegate of a state machine timeout.
- (void)stateMachine:(GDAStateMachine *)stateMachine
   timedOutWithState:(NSString *)state;

@end
