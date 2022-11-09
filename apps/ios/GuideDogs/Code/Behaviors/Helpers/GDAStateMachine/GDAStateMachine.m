//
//  GDAStateMachine.m
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

#import "GDAStateMachine.h"
#import <pthread.h>

// Logging.
static inline void Log(NSString * format, ...)
{
    // Removed logs for now.
    return;
    
//    // Format the log entry.
//    va_list args;
//    va_start(args, format);
//    NSString * formattedString = [[NSString alloc] initWithFormat:format arguments:args];
//    va_end(args);
//    
//    // Log the log entry.
//    NSLog(@"%@", [NSString stringWithFormat:@"     StateMachine: %@", formattedString]);
}

// GDAStateMachineState implementation.
@implementation GDAStateMachineState

// Class initializer.
- (instancetype)initWithName:(NSString *)name
                     timeout:(NSTimeInterval)timeout
                 enterAction:(GDAStateEnterAction)enterAction
                  exitAction:(GDAStateExitAction)exitAction
{
    // Initialize superclass.
    self = [super init];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Initialize.
    _name = name;
    _timeout = timeout;
    _enterAction = enterAction;
    _exitAction = exitAction;
    
    // Done.
    return self;
}

@end

// GDAStateMachineEvent implementation.
@implementation GDAStateMachineEvent

// Class initializer.
- (instancetype)initWithName:(NSString *)name
                 transitions:(NSDictionary<NSString *, NSString *> *)transitions
{
    // Initialize superclass.
    self = [super init];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Initialize.
    _name = name;
    _transitions = transitions;
    
    // Done.
    return self;
}

@end

// GDAStateMachine (Internal) interface.
@interface GDAStateMachine (Internal)

// Class initializer.
- (instancetype)initWithName:(NSString *)name
                      states:(NSArray<GDAStateMachineState *> *)states
                      events:(NSArray<GDAStateMachineEvent *> *)events
            defaultStateName:(NSString *)defaultStateName;

// Transitions to the specified state.
- (void)transitionToState:(GDAStateMachineState *)state
                   object:(id)object;

@end

// GDAStateMachine implementation.
@implementation GDAStateMachine
{
@private
    // The mutex.
    pthread_mutex_t _mutex;
    
    // The default state.
    GDAStateMachineState * _defaultState;
    
    // The timeout state.
    GDAStateMachineState * _timeoutState;
    
    // The states dictionary. The key is the state name. The entry is a GDAStateMachineState object.
    NSDictionary<NSString *, GDAStateMachineState *> * _states;
    
    // The events dictionary. Each key is an event name. The entry is a dictionary of transitions.
    NSDictionary<NSString *, NSDictionary *> * _events;
    
    // The state number. Used for timeout processing.
    uint64_t _stateNumber;
}

// Class initializer.
- (instancetype)init
{
    // Initialize superclass.
    self = [super init];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Done.
    return self;
}

// Returns a new state machine.
+ (instancetype)stateMachineWithName:(NSString *)name
                              states:(NSArray<GDAStateMachineState *> *)states
                              events:(NSArray<GDAStateMachineEvent *> *)events
{
    return [[GDAStateMachine alloc] initWithName:name
                                          states:states
                                          events:events
                                defaultStateName:@""];
}

// Returns a new state machine.
+ (instancetype)stateMachineWithName:(NSString *)name
                              states:(NSArray<GDAStateMachineState *> *)states
                              events:(NSArray<GDAStateMachineEvent *> *)events
                    defaultStateName:(NSString *)defaultStateName
{
    return [[GDAStateMachine alloc] initWithName:name
                                          states:states
                                          events:events
                                defaultStateName:defaultStateName];
}

// Returns a new state machine state.
+ (id)stateWithName:(NSString *)name
            timeout:(NSTimeInterval)timeout
        enterAction:(GDAStateEnterAction)enterAction
         exitAction:(GDAStateExitAction)exitAction
{
    return [[GDAStateMachineState alloc] initWithName:name
                                              timeout:timeout
                                          enterAction:enterAction
                                           exitAction:exitAction];
}

// Returns a new state machine event.
+ (id)eventWithName:(NSString *)name
        transitions:(NSDictionary<NSString *, NSString *> *)transitions
{
    return [[GDAStateMachineEvent alloc] initWithName:name
                                          transitions:transitions];
}

// Fires an event by name.
- (BOOL)fireEventWithName:(NSString *)eventName
{
    return [self fireEventWithName:eventName
                            object:nil];
}

// Fires an event by name.
- (BOOL)fireEventWithName:(NSString *)eventName
                   object:(id)object
{
    // Find the event. If it can't be found, raise an exception.
    NSDictionary * transitions = _events[eventName];
    if (!transitions)
    {
        [NSException raise:@"Undefined Event"
                    format:@"State machine '%@' does not contain an event named '%@'.", _name, eventName];
    }
    
    // Lock.
    pthread_mutex_lock(&_mutex);
    
    // Look for an explicit transition from the current state.
    GDAStateMachineState * toState = transitions[[_currentState name]];
    
    // If we found an explicit transition from the current state, great.
    BOOL result;
    if (toState)
    {
        // Explicit transition found.
        result = YES;
        
        // Log.
        Log(@"%@: Event '%@' fired. Explicit transition from state '%@' to state '%@'.", _name, eventName, [_currentState name], [toState name]);
    }
    else
    {
        // An explicit transition from the current state wasn't found. Look for a wildcard transition.
        toState = transitions[@"*"];
        
        // If a wildcard transition was found, great.
        if (toState)
        {
            // Wildcard transition found.
            result = YES;
            
            // Log.
            Log(@"%@: Event '%@' fired. Wildcard transition from state '%@' to state '%@'.", _name, eventName, [_currentState name], [toState name]);
        }
        else
        {
            // State machine error. Do not make a state transition.
            toState = nil;
            result = NO;
        }
    }
    
    // If we have a new state to transition to, do it.
    if (toState && _currentState != toState)
    {
        [self transitionToState:toState
                         object:object];
    }
    
    // Unlock.
    pthread_mutex_unlock(&_mutex);
    
    // If there was a state machine error, notify the delegate.
    if (!result)
    {
        // Log.
        Log(@"%@: Event '%@' fired. State machine error. Not transition from state '%@' was found.", _name, eventName, [_currentState name]);

        // Notify the delegate.
        if ([[self delegate] respondsToSelector:@selector(stateMachineError:)])
        {
            [[self delegate] stateMachineError:self];
        }
    }
    
    // Retun the result.
    return result;
}

@end

// GDAStateMachine (Internal) implementation.
@implementation GDAStateMachine (Internal)

// Class initializer.
- (instancetype)initWithName:(NSString *)name
                      states:(NSArray<GDAStateMachineState *> *)states
                      events:(NSArray<GDAStateMachineEvent *> *)events
            defaultStateName:(NSString *)defaultStateName
{
    // Initialize superclass.
    self = [super init];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Initialize.
    pthread_mutex_init(&_mutex, NULL);
    _name = name;
    
    // The default state is the first state.
    if(defaultStateName != nil && ![defaultStateName isEqualToString:@""]){
        NSUInteger index = [states indexOfObjectPassingTest:^BOOL(GDAStateMachineState * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            BOOL result = NO;
            
            if([[obj name] isEqualToString: defaultStateName]){
                result = YES;
            }
            
            return result;
        }];
        
        _defaultState = states[index];
    }else{
        _defaultState = states[0];
    }
    
    // Set-up states.
    NSMutableDictionary<NSString *, GDAStateMachineState *> * mutableStates = [[NSMutableDictionary<NSString *, GDAStateMachineState *> alloc] initWithCapacity:[states count]];
    for (GDAStateMachineState * state in states)
    {
        // Check for duplicate state definitions.
        if (mutableStates[[state name]])
        {
            [NSException raise:@"Duplicate State"
                        format:@"State machine '%@' defines state '%@' more than once.", _name, [state name]];
        }
        
        // Note the timeout statem.
        if ([[state name] isEqualToString:@"[Timeout]"])
        {
            _timeoutState = state;
        }
        
        // Add the state.
        mutableStates[[state name]] = state;
    }
    _states = mutableStates;
    
    // If a timeout state wasn't explicitly defined, use the detault state.
    if (!_timeoutState)
    {
        _timeoutState = _defaultState;
    }
    
    // Set-up events.
    NSMutableDictionary<NSString *, NSDictionary<NSString *, GDAStateMachineState *> *> * mutableEvents = [[NSMutableDictionary<NSString *, NSDictionary<NSString *, GDAStateMachineState *> *> alloc] initWithCapacity:[events count]];
    for (GDAStateMachineEvent * event in events)
    {
        // Check for duplicate event definitions.
        if (mutableEvents[[event name]])
        {
            [NSException raise:@"Duplicate Event"
                        format:@"State machine '%@' defines event '%@' more than once.", _name, [event name]];
        }
        
        // Process the transitions.
        NSMutableDictionary<NSString *, GDAStateMachineState *> * mutableTransitions = [[NSMutableDictionary<NSString *, GDAStateMachineState *> alloc] init];
        [[event transitions] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL * stop) {
            // Get the from state name and to state name.
            NSString * fromStateName = (NSString *)key;
            NSString * toStateName = (NSString *)obj;
            
//            // Verify the from state.
//            if (![fromStateName isEqualToString:@"*"] && !_states[fromStateName])
//            {
//                [NSException raise:@"Event Definition Error"
//                            format:@"State machine '%@' event '%@' from state '%@' not defined.", _name, [event name], fromStateName];
//            }
            
            // Verify the to state.
            GDAStateMachineState * toState = _states[toStateName];
//            if (!toState)
//            {
//                [NSException raise:@"Event Definition Error"
//                            format:@"State machine '%@' event '%@' to state '%@' not defined.", _name, [event name], toStateName];
//            }
            
            // Add the transition.
            mutableTransitions[fromStateName] = toState;
        }];
        
        // Add the event and its transitions.
        mutableEvents[[event name]] = (NSDictionary<NSString *, GDAStateMachineState *> *)mutableTransitions;
    }
    _events = mutableEvents;
    
#if defined(Logging)
    // Log.
    Log(@"%@: Initialized (States: %u Events: %u)", _name, [_states count], [_events count]);
#endif
    
    // Transition to the default state.
    [self transitionToState:_defaultState
                     object:nil];
    
    // Done.
    return self;
}

// Transitions to the specified state.
- (void)transitionToState:(GDAStateMachineState *)state
                   object:(id)object
{
    // Log.
    Log(@"%@: Transition from state '%@' to state '%@'.", _name, [_currentState name], [state name]);
    
    // If the current state has an exit action, call it.
    if ([_currentState exitAction])
    {
        [_currentState exitAction];
    }
    
    // Increment the state number.
    _stateNumber++;
    
    //set the previous state
    _previousStateName = [_currentState name];
    
    // Set the current state.
    _currentState = state;
    
    // If the current state specifies a timeout, set-up timeout processing before calling the enter action.
    NSTimeInterval timeout = [state timeout];
    if (timeout)
    {
        // Capture the state number for timeout processing.
        uint64_t stateNumber = _stateNumber;
        
        // Log.
        Log(@"%@: State '%@' will time out after %.0f seconds.", _name, [state name], timeout);
        
        // Schedule timeout processing.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // Lock.
            pthread_mutex_lock(&_mutex);
            
            // If the operation timed out, change to the default state.
            BOOL timedout = _stateNumber == stateNumber;
            if (timedout)
            {
                // Log.
                Log(@"%@: State '%@' timed out after %.0f seconds. Transition to state '%@'", _name, [state name], timeout, [_timeoutState name]);
                
                // Transition to the timeout state.
                [self transitionToState:_timeoutState
                                 object:[state name]];
            }
            
            // Unlock.
            pthread_mutex_unlock(&_mutex);
            
            // If the operation timed out, notify the delegate.
            if (timedout && [[self delegate] respondsToSelector:@selector(stateMachine:timedOutWithState:)])
            {
                [[self delegate] stateMachine:self timedOutWithState:[state name]];
            }
        });
    }
    
    // If the current state has an enter action, call it.
    if ([state enterAction])
    {
        // Call the enter action.
        NSString * nextStateName = nil;
        id nextStateObject = nil;
        [state enterAction](object, &nextStateName, &nextStateObject);
        
        // If the enter action specifies a next state, immediately transition to that state.
        if (nextStateName)
        {
            // Find the next state.
            GDAStateMachineState * nextState = _states[nextStateName];
            if (!nextState)
            {
                [NSException raise:@"Undefined State"
                            format:@"State machine '%@' state '%@' enter action transitions to next state '%@' which is not defined.", _name, [state name], nextStateName];
            }
            
            // Transition.
            [self transitionToState:nextState
                             object:nextStateObject];
        }
    }
}

@end
