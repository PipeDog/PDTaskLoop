//
//  PDTaskLoop.m
//  PDTaskLoop
//
//  Created by liang on 2021/12/17.
//

#import "PDTaskLoop.h"

@interface _PDLoopTimer : NSObject

@end

@implementation _PDLoopTimer {
    dispatch_source_t _timer;
    NSTimeInterval _ti;
    NSTimeInterval _leeway;
    dispatch_queue_t _queue;
    dispatch_block_t _block;
}

- (void)dealloc {
    [self invalidate];
}

- (instancetype)initWithTimeInterval:(NSTimeInterval)ti
                              leeway:(NSTimeInterval)leeway
                               queue:(dispatch_queue_t)queue
                               block:(dispatch_block_t)block {
    self = [super init];
    if (self) {
        _ti = ti;
        _leeway = leeway;
        _queue = queue ?: dispatch_get_main_queue();
        _block = [block copy];
    }
    return self;
}

- (void)fire {
    if (_timer) {
        return;
    }
    
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _queue);
    dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, _ti * NSEC_PER_SEC, _leeway * NSEC_PER_SEC);
    
    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(_timer, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            !strongSelf->_block ?: strongSelf->_block();
        }
    });
    
    dispatch_resume(_timer);
}

- (void)invalidate {
    if (!_timer) {
        return;
    }
    
    dispatch_source_cancel(_timer);
    _timer = nil;
}

@end

@interface _PDTaskLoopPool : NSObject

@end

@implementation _PDTaskLoopPool {
    NSLock *_lock;
    NSMutableDictionary *_loopDict;
}

+ (_PDTaskLoopPool *)defaultPool {
    static _PDTaskLoopPool *__defaultPool;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __defaultPool = [[self alloc] init];
    });
    return __defaultPool;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _lock = [[NSLock alloc] init];
        _loopDict = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)registerTaskLoop:(PDTaskLoop *)taskLoop forName:(NSString *)name {
    if (!taskLoop || !name.length) {
        return;
    }
    
    [_lock lock];
    _loopDict[name] = taskLoop;
    [_lock unlock];
}

- (void)unregisterTaskLoopForName:(NSString *)name {
    if (!name.length) {
        return;
    }
    
    [_lock lock];
    _loopDict[name] = nil;
    [_lock unlock];
}

- (PDTaskLoop *)taskLoopForName:(NSString *)name {
    if (!name.length) {
        return nil;
    }

    [_lock lock];
    PDTaskLoop *taskLoop = _loopDict[name];
    [_lock unlock];
    return taskLoop;
}

@end

@interface PDTaskLoop ()

@property (nonatomic, assign) PDTaskLoopMode mode;
@property (nonatomic, assign) NSTimeInterval timeInterval;
@property (nonatomic, strong) _PDLoopTimer *timer;
@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, strong) NSMutableArray<dispatch_block_t> *taskQueue;

@end

@implementation PDTaskLoop

+ (void)registerTaskLoop:(PDTaskLoop *)taskLoop forName:(NSString *)name {
    [[_PDTaskLoopPool defaultPool] registerTaskLoop:taskLoop forName:name];
}

+ (void)unregisterTaskLoopForName:(NSString *)name {
    [[_PDTaskLoopPool defaultPool] unregisterTaskLoopForName:name];
}

+ (PDTaskLoop *)taskLoopForName:(NSString *)name {
    return [[_PDTaskLoopPool defaultPool] taskLoopForName:name];
}

- (void)dealloc {
    [self shutdown];
}

- (instancetype)initWithMode:(PDTaskLoopMode)mode timeInterval:(NSTimeInterval)secs {
    self = [super init];
    if (self) {
        _mode = mode;
        _timeInterval = secs;
        _lock = [[NSLock alloc] init];
        _taskQueue = [NSMutableArray array];
    }
    return self;
}

- (void)addTask:(dispatch_block_t)block {
    if (!block) {
        return;
    }
    
    [self.lock lock];
    [self.taskQueue addObject:block];
    [self.lock unlock];
}

- (void)run {
    if (self.timer) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    self.timer = [[_PDLoopTimer alloc] initWithTimeInterval:self.timeInterval
                                                     leeway:0.01f
                                                      queue:nil
                                                      block:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf executeTasks];
        }
    }];
    
    [self.timer fire];
}

- (void)shutdown {
    if (!_timer) {
        return;
    }
    
    [_timer invalidate];
    _timer = nil;
}

#pragma mark - Private Methods
- (void)executeTasks {
    if (!self.taskQueue.count) {
        return;
    }
    
    [self.lock unlock];
    NSArray<dispatch_block_t> *taskQueue = [self.taskQueue copy];
    [self.taskQueue removeAllObjects];
    [self.lock unlock];

    switch (self.mode) {
        case PDTaskLoopModeRunFirst: {
            dispatch_block_t taskBlock = taskQueue.firstObject;
            !taskBlock ?: taskBlock();
        } break;
        case PDTaskLoopModeRunLast: {
            dispatch_block_t taskBlock = taskQueue.lastObject;
            !taskBlock ?: taskBlock();
        } break;
        case PDTaskLoopModeRunAll: {
            for (dispatch_block_t taskBlock in taskQueue) {
                taskBlock();
            }
        } break;
        case PDTaskLoopModeRunAllReverse: {
            NSInteger count = taskQueue.count;
            for (NSInteger i = count - 1; i >= 0; i--) {
                dispatch_block_t taskBlock = taskQueue[i];
                taskBlock();
            }
        } break;
        default: break;
    }
}

@end
