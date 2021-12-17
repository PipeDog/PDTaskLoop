//
//  PDTaskLoop.h
//  PDTaskLoop
//
//  Created by liang on 2021/12/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 任务循环执行模式
typedef NS_ENUM(NSUInteger, PDTaskLoopMode) {
    /// 执行本次循环中，当前队列的第一个任务
    PDTaskLoopModeRunFirst = 0,
    /// 执行本次循环中，当前队列的最后一个任务
    PDTaskLoopModeRunLast,
    /// 执行本次循环中的所有任务
    PDTaskLoopModeRunAll,
    /// 倒序执行本次循环中的所有任务
    PDTaskLoopModeRunAllReverse,
};

/// @class PDTaskLoop
/// @brief 任务运行循环，采用队列 + 定时轮询的方式进行任务调度执行
@interface PDTaskLoop : NSObject

/// 任务执行模式，在初始化完成设置后禁止再次更改
@property (nonatomic, assign, readonly) PDTaskLoopMode mode;
/// 任务运行循环单次时间间隔，在初始化完成设置后禁止再次更改
@property (nonatomic, assign, readonly) NSTimeInterval timeInterval;

/// 注册任务运行循环到池子中，方便全局存取使用
/// @param taskLoop 任务运行循环实例
/// @param name 循环唯一标识
+ (void)registerTaskLoop:(PDTaskLoop *)taskLoop forName:(NSString *)name;

/// 注销指定标识的运行循环
/// @param name 循环唯一标识
+ (void)unregisterTaskLoopForName:(NSString *)name;

/// 通过循环唯一标识获取运行循环实例
/// @param name 循环唯一标识
+ (PDTaskLoop * _Nullable)taskLoopForName:(NSString *)name;

/// 禁用初始化方法
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/// 指定初始化方法，如要启动任务循环，需手动调用 `- [PDTaskLoop run]` 方法
/// @param mode 任务执行模式
/// @param secs 任务运行循环单次时间间隔
/// @return 任务运行循环实例
- (instancetype)initWithMode:(PDTaskLoopMode)mode timeInterval:(NSTimeInterval)secs;

/// 启动循环
- (void)run;

/// 停止循环
- (void)shutdown;

/// 加入将要执行的任务（该任务可能不会被执行，取决于选择的循环执行模式以及该任务的添加时机）
- (void)addTask:(dispatch_block_t)block;

@end

NS_ASSUME_NONNULL_END
