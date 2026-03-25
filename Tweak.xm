#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ==================== 日志系统 ====================
// 写入文件日志，方便调试非越狱环境
static void WriteLog(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *log = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    // 写入文件（路径在非越狱环境可访问）
    NSString *path = @"/var/mobile/Documents/aweme_bypass_log.txt";
    NSFileHandle *file = [NSFileHandle fileHandleForWritingAtPath:path];
    if (!file) {
        [[log stringByAppendingString:@"\n"] writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    } else {
        [file seekToEndOfFile];
        [file writeData:[log dataUsingEncoding:NSUTF8StringEncoding]];
        [file writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [file closeFile];
    }
    // 同时输出到 NSLog（越狱环境可见）
    NSLog(@"[AwemeBypass] %@", log);
}

// ==================== Hook 版本检查任务 ====================
%hook AWECheckVersionTask
+ (void)execute {
    WriteLog(@"✅ AWECheckVersionTask.execute 被调用，已跳过");
    // 不调用原方法，完全阻止版本检查
}
%end

// ==================== Hook 版本更新管理器 ====================
%hook AWEVersionUpdateManager
- (BOOL)canShow {
    WriteLog(@"✅ AWEVersionUpdateManager.canShow 返回 NO");
    return NO; // 禁止显示升级弹窗
}

- (void)_showUpgradeIfNeeded {
    WriteLog(@"✅ AWEVersionUpdateManager._showUpgradeIfNeeded 已阻止");
    // 不调用原方法
}

- (void)_showUpgradeModal {
    WriteLog(@"✅ AWEVersionUpdateManager._showUpgradeModal 已阻止");
    // 不调用原方法
}
%end

// ==================== Hook 新版本提醒工具 ====================
%hook AWENewVersionAlertUtils
+ (BOOL)appShouldRemindNewVersion {
    WriteLog(@"✅ AWENewVersionAlertUtils.appShouldRemindNewVersion 返回 NO");
    return NO;
}
%end

// ==================== Hook 应用版本工具类 ====================
%hook AWEIMAppVersionUtil
+ (long long)appVersionCode {
    WriteLog(@"✅ AWEIMAppVersionUtil.appVersionCode 返回伪造版本 380100");
    return 380100; // 伪造为 38.1.0 的 build 号
}
%end

// ==================== Hook 通用版本比较工具（重要） ====================
%hook BDCommonClientABManagerUtils
+ (unsigned long long)compareVersion:(id)a0 toVersion:(id)a1 {
    WriteLog(@"✅ BDCommonClientABManagerUtils.compareVersion:%@ toVersion:%@ 返回 0 (相等)", a0, a1);
    return 0; // 返回 0 表示版本相等，绕过强制升级
}
%end

// ==================== Hook 搜索视频交互管理器 ====================
%hook AWEVideoSearchInteractionManager
- (void)requireLoginWithContext:(id)a0 completion:(id /* block */)a1 {
    WriteLog(@"✅ AWEVideoSearchInteractionManager.requireLoginWithContext 已跳过登录要求");
    // 直接调用完成块，模拟已登录状态
    if (a1) {
        ((void (^)(BOOL))a1)(YES);
    }
}
%end

// ==================== Hook 弹窗控制器（拦截“版本过低”提示） ====================
%hook UIAlertController
- (void)viewDidAppear:(BOOL)animated {
    NSString *title = self.title ?: @"";
    NSString *message = self.message ?: @"";
    
    // 检测版本过低相关弹窗
    if ([title containsString:@"版本过低"] || 
        [message containsString:@"版本过低"] ||
        [title containsString:@"升级"] ||
        [message containsString:@"升级"] ||
        [title containsString:@"安全"] ||
        [message containsString:@"安全"]) {
        
        WriteLog(@"🚨 拦截到疑似版本检查弹窗: title=%@, message=%@", title, message);
        
        // 延迟 0.5 秒后自动点击第一个按钮（通常是“确定”）
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if (self.actions.count > 0) {
                WriteLog(@"🔄 自动点击弹窗按钮");
                [self.actions.firstObject performSelector:@selector(_triggerAction)];
            }
        });
    }
    %orig;
}
%end

// ==================== Hook 登录相关检查 ====================
%hook AWEUserLoginManager
- (BOOL)isLogin {
    WriteLog(@"✅ AWEUserLoginManager.isLogin 返回 YES");
    return YES; // 伪造成已登录状态
}

- (BOOL)isValidToken {
    WriteLog(@"✅ AWEUserLoginManager.isValidToken 返回 YES");
    return YES;
}
%end

// ==================== 通用网络请求拦截（备用） ====================
%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    NSString *urlString = request.URL.absoluteString;
    // 如果请求包含版本检查 API，返回伪造的成功响应
    if ([urlString containsString:@"check_version"] || 
        [urlString containsString:@"upgrade"] ||
        [urlString containsString:@"version"]) {
        WriteLog(@"🌐 拦截版本检查请求: %@", urlString);
        // 这里可以构造一个假的响应，但为了简单先放行
    }
    return %orig;
}
%end

// ==================== 初始化函数 ====================
%ctor {
    WriteLog(@"========================================");
    WriteLog(@"🎬 AwemeBypass 加载成功 - 非越狱兼容版");
    WriteLog(@"📱 目标应用: com.ss.iphone.ugc.aweme.mobile");
    WriteLog(@"⏰ 加载时间: %@", [NSDate date]);
    WriteLog(@"========================================");
    
    // 确保日志文件存在
    NSString *path = @"/var/mobile/Documents/aweme_bypass_log.txt";
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [@"AwemeBypass Log File\n" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}