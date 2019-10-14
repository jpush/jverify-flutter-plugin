#import "JverifyPlugin.h"
#import "JVERIFICATIONService.h"
// 如果需要使用 idfa 功能所需要引入的头文件（可选）
#import <AdSupport/AdSupport.h>
#define UIColorFromRGB(rgbValue)  ([UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0])


#define JVLog(fmt, ...) NSLog((@"| JVER | iOS | " fmt), ##__VA_ARGS__)

/// 统一 key
static NSString *const j_result_key = @"result";
/// 错误码
static NSString *const j_code_key = @"code";
/// 回调的提示信息，统一返回 flutter 为 message
static NSString *const j_msg_key = @"message";
/// 运营商信息
static NSString *const j_opr_key = @"operator";
/// 默认超时时间
static long j_default_timeout = 5000;

@implementation JverifyPlugin

NSObject<FlutterPluginRegistrar>* _jv_registrar;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:@"jverify"
                                                              binaryMessenger:[registrar messenger]];
  _jv_registrar = registrar;
  JverifyPlugin* instance = [[JverifyPlugin alloc] init];
  instance.channel = channel;
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    JVLog(@"Action - handleMethodCall: %@",call.method);
    
    NSString *methodName = call.method;
    if ([methodName isEqualToString:@"setup"]) {
        [self setup:call result:result];
    }else if([methodName isEqualToString:@"setDebugMode"]){
        [self setDebugMode:call result:result];
    }else if([methodName isEqualToString:@"isInitSuccess"]) {
        [self isSetupClient:result];
    }else if([methodName isEqualToString:@"checkVerifyEnable"]){
        [self checkVerifyEnable:call result:result];
    }else if([methodName isEqualToString:@"getToken"]){
        [self getToken:call result:result];
    }else if([methodName isEqualToString:@"verifyNumber"]){
        [self verifyNumber:call result:result];
    }else if([methodName isEqualToString:@"loginAuth"]){
        [self loginAuth:call result:result];
    }else if ([methodName isEqualToString:@"loginAuthSyncApi"]){
        [self loginAuthSyncApi:call result:result];
    } else if([methodName isEqualToString:@"preLogin"]){
        [self preLogin:call result:result];
    }else if([methodName isEqualToString:@"dismissLoginAuthView"]){
        [self dismissLoginController:call result:result];
    }else if([methodName isEqualToString:@"setCustomUI"]){
//        [self setCustomUIWithConfig:call result:result];
    }else if ([methodName isEqualToString:@"setCustomAuthViewAllWidgets"]) {
        [self setCustomAuthViewAllWidgets:call result:result];
    }else if ([methodName isEqualToString:@"clearPreLoginCache"]) {
        [self clearPreLoginCache:call result:result];
    }else if ([methodName isEqualToString:@"setCustomAuthorizationView"]) {
        [self setCustomAuthorizationView:call result:result];
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}


#pragma mark - 设置日志 debug 模式
-(void)setDebugMode:(FlutterMethodCall*) call result:(FlutterResult)result{
    JVLog(@"Action - setDebugMode::");
    
    NSDictionary *arguments = call.arguments;
    NSNumber *debug = arguments[@"debug"];
    [JVERIFICATIONService setDebug:[debug boolValue]];
}

#pragma mark - 初始化 SDK
- (void)setup:(FlutterMethodCall*) call result:(FlutterResult)result{
    JVLog(@"Action - setup::");
    NSDictionary *arguments = [call arguments];
    NSString *appKey = arguments[@"appKey"];
    NSString *channel = arguments[@"channel"];
    NSNumber *useIDFA = arguments[@"useIDFA"];
    
    JVAuthConfig *config = [[JVAuthConfig alloc] init];
    if (![appKey isKindOfClass:[NSNull class]]) {
        config.appKey = appKey;
    }
    config.appKey =appKey;
    if (![channel isKindOfClass:[NSNull class]]) {
        config.channel = channel;
    }
    NSString *idfaStr = NULL;
    if(![useIDFA isKindOfClass:[NSNull class]]){
        if([useIDFA boolValue]){
            idfaStr = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
            config.advertisingId = idfaStr;
        }
    }
    [JVERIFICATIONService setupWithConfig:config];
}

#pragma mark - 获取初始化状态
-(BOOL)isSetupClient:(FlutterResult)result {
    JVLog(@"Action - isSetupClient:");
    BOOL isSetup = [JVERIFICATIONService isSetupClient];
    if (!isSetup) {
        JVLog(@"初始化未完成!");
    }
    result(@{j_result_key:[NSNumber numberWithBool:isSetup]});
    // 初始换成功
    //···
    return isSetup;
}

#pragma mark - 判断网络环境是否支持
-(BOOL)checkVerifyEnable:(FlutterMethodCall*)call result:(FlutterResult)result{
    JVLog(@"Action - checkVerifyEnable::");
    BOOL isEnable = [JVERIFICATIONService checkVerifyEnable];
    if(!isEnable) {
        JVLog(@"当前网络环境不支持认证！");
    }
    result(@{j_result_key:[NSNumber numberWithBool:isEnable]});
    //继续获取token操作
    //...
    return isEnable;
}

#pragma mark - 获取号码认证token
-(void)getToken:(FlutterMethodCall*)call result:(FlutterResult)result{
    JVLog(@"Action - getToken::%@",call.arguments);
    
    NSDictionary *arguments=  [call arguments];
    NSNumber *timeoutNum = arguments[@"timeout"];
    NSTimeInterval timeout = [timeoutNum longLongValue];
    if (timeout <= 0) {
        timeout = j_default_timeout;
    }
    
    /*
     参数说明
     timeout 超时时间。单位ms，合法范围3000~10000。
     completion 参数是字典 返回token 、错误码等相关信息，token有效期1分钟, 一次认证后失效
        res 字典
            获取到token时，key 有 code、token、operator 字段，
            获取不到token时，key 为 code 、content 字段
     
     */
    [JVERIFICATIONService getToken:timeout completion:^(NSDictionary *res) {
        JVLog(@"sdk getToken completion : %@",res);
        
        NSString *content = @"";
        if(res[@"token"]){
            content =res[@"token"];
        }else if(res[@"content"]){
            content = res[@"content"];
        }
        NSDictionary *dict = @{
                               j_code_key: res[@"code"],
                               j_msg_key : content,
                               j_opr_key : res[@"operator"] ? res[@"operator"] : @""
                               };
        
        dispatch_async(dispatch_get_main_queue(), ^{
            result(dict);
        });
    }];
}

#pragma mark - SDK 发起号码认证
-(void)verifyNumber:(FlutterMethodCall*) call result:(FlutterResult)result{
    JVLog(@"Action - verifyNumber::%@",call.arguments);

    /* 2.4.3版本开始，此接口已移除
    NSDictionary *arguments=  [call arguments];
    NSString *phone = arguments[@"phone"];
    NSString *token = arguments[@"token"];
    
    [JVERIFICATIONService ]
    JVAuthEntity *entity = [[JVAuthEntity alloc] init];
    entity.number = phone;
    if (![token isKindOfClass:[NSNull class]]) {
        if (token && token.length) {
            entity.token = token;
        }
    }
    
    [JVERIFICATIONService verifyNumber:entity result:^(NSDictionary *res) {
        JVLog(@"sdk verifyNumber completion : %@",res);
        
        NSDictionary *dict = @{
                               j_code_key:res[@"code"],
                               j_msg_key :res[@"content"] ? res[@"content"] : @""
                               };
        dispatch_async(dispatch_get_main_queue(), ^{
            result(dict);
        });
    }];
    */
}
#pragma mark - SDK 登录预取号
- (void)preLogin:(FlutterMethodCall*) call result:(FlutterResult)result {
    JVLog(@"Action - preLogin::%@",call.arguments);
    
    NSDictionary *arguments=  [call arguments];
    NSNumber *timeoutNum = arguments[@"timeout"];
    NSTimeInterval timeout = [timeoutNum longLongValue];
    if (timeout <= 0) {
        timeout = j_default_timeout;
    }
    
    /*
     参数说明:
        completion 预取号结果
            result 字典 key为code和message两个字段
            timeout 超时时间。单位ms，合法范围3000~10000。
     */
    [JVERIFICATIONService preLogin:timeout completion:^(NSDictionary *res) {
        JVLog(@"sdk preLogin completion :%@",res);
        
        NSDictionary *dict = @{
                               j_code_key:res[@"code"],
                               j_msg_key :res[@"message"] ? res[@"message"] : @""
                               };
        dispatch_async(dispatch_get_main_queue(), ^{
            result(dict);
        });
    }];
}

#pragma mark - SDK清除预取号缓存
- (void)clearPreLoginCache:(FlutterMethodCall*) call result:(FlutterResult)result {
    JVLog(@"Action - clearPreLoginCache::");
    [JVERIFICATIONService clearPreLoginCache];
}
#pragma mark - SDK 请求授权一键登录
-(void)loginAuth:(FlutterMethodCall*) call result:(FlutterResult)result {
    JVLog(@"Action - loginAuth::%@",call.arguments);
    [self loginAuthSync:NO call:call result:result];
}
-(void)loginAuthSyncApi:(FlutterMethodCall*) call result:(FlutterResult)result {
    JVLog(@"Action - loginAuthSyncApi::%@",call.arguments);
    [self loginAuthSync:YES call:call result:result];
}
-(void)loginAuthSync:(BOOL)isSync call:(FlutterMethodCall*)call result:(FlutterResult)result {
    JVLog(@"Action - loginAuthSync::%@",call.arguments);

    NSDictionary *arguments = [call arguments];
    NSNumber *hide = arguments[@"autoDismiss"];
    
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    __weak typeof(self) weakself = self;
    [JVERIFICATIONService getAuthorizationWithController:vc hide:[hide boolValue] completion:^(NSDictionary *res) {
        JVLog(@"getAuthorizationWithController result = %@",res);
        
        NSString *content = @"";
        if(res[@"loginToken"]){
            content =res[@"loginToken"];
        }else if(res[@"content"]){
            content = res[@"content"];
        }
        
        NSDictionary *dict = @{
                               j_code_key:res[@"code"],
                               j_msg_key :content,
                               j_opr_key :res[@"operator"]?:@""
                               };
        __strong typeof(weakself) strongself = weakself;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (isSync) {
                //通过 channel 返回
                [strongself.channel invokeMethod:@"onReceiveLoginAuthCallBackEvent" arguments:dict];
            }else{
                // 通过回调返回
                result(dict);
            }
        });
    } actionBlock:^(NSInteger type, NSString *content) {
        JVLog("Authorization actionBlock: type = %ld", (long)type);
        /// 事件
        NSDictionary *jsonMap = @{
                                  j_code_key:@(type),
                                  j_msg_key:content?content:@""
                                  };
        __strong typeof(weakself) strongself = weakself;
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongself.channel invokeMethod:@"onReceiveClickWidgetEvent" arguments:jsonMap];
        });
    }];
}
#pragma mark - SDK关闭授权页面
-(void)dismissLoginController:(FlutterMethodCall*) call result:(FlutterResult)result{
    JVLog(@"Action - dismissLoginController::");
    [JVERIFICATIONService dismissLoginController];
}

#pragma mark - 自定义授权页面所有的 UI （包括：原有的、新加的）
-(void)setCustomAuthViewAllWidgets:(FlutterMethodCall*) call result:(FlutterResult)result {
    JVLog(@"Action - setCustomAuthViewAllWidgets:%@",call.arguments);
    
    NSDictionary *uiconfig = call.arguments[@"uiconfig"];
    NSArray *widgets = call.arguments[@"widgets"];
    [self layoutUIConfig:uiconfig widgets:widgets isAutorotate:NO];
}
- (void)setCustomAuthorizationView:(FlutterMethodCall*) call result:(FlutterResult)result {
    JVLog(@"Action - setCustomAuthorizationView:%@",call.arguments);
    
    BOOL isAutorotate = [call.arguments[@"isAutorotate"] boolValue];
    NSDictionary *portraitConfig = call.arguments[@"portraitConfig"];
    NSArray *widgets = call.arguments[@"widgets"];
    [self layoutUIConfig:portraitConfig widgets:widgets isAutorotate:isAutorotate];
}

- (void)layoutUIConfig:(NSDictionary *)uiconfig widgets:(NSArray *)widgets isAutorotate:(BOOL)isAutorotate {
   
    /*移动*/
    JVMobileUIConfig *mobileUIConfig = [[JVMobileUIConfig alloc] init];
    mobileUIConfig.autoLayout = YES;
    mobileUIConfig.shouldAutorotate = isAutorotate;
    /*联通*/
    JVUnicomUIConfig *unicomUIConfig = [[JVUnicomUIConfig alloc] init];
    unicomUIConfig.autoLayout = YES;
    unicomUIConfig.shouldAutorotate = isAutorotate;
    /*电信*/
    JVTelecomUIConfig *telecomUIConfig = [[JVTelecomUIConfig alloc] init];
    telecomUIConfig.autoLayout = YES;
    telecomUIConfig.shouldAutorotate = isAutorotate;
    
    [self setCustomUIWithConfigWithMobile:mobileUIConfig unicom:unicomUIConfig telecom:telecomUIConfig configArguments:uiconfig];
    
    [JVERIFICATIONService customUIWithConfig:mobileUIConfig customViews:^(UIView *customAreaView) {
        for (NSDictionary *widgetDic in widgets) {
            NSString *type = [self getValue:widgetDic key:@"type"];
            if ([type isEqualToString:@"textView"]) {
                [customAreaView addSubview:[self addCustomTextWidget:widgetDic]];
            }else if ([type isEqualToString:@"button"]){
                [customAreaView addSubview:[self addCustomButtonWidget:widgetDic]];
            }else{
                
            }
        }
    }];
    [JVERIFICATIONService customUIWithConfig:unicomUIConfig customViews:^(UIView *customAreaView) {
        for (NSDictionary *widgetDic in widgets) {
            NSString *type = [self getValue:widgetDic key:@"type"];
            if ([type isEqualToString:@"textView"]) {
                [customAreaView addSubview:[self addCustomTextWidget:widgetDic]];
            }else if ([type isEqualToString:@"button"]){
                [customAreaView addSubview:[self addCustomButtonWidget:widgetDic]];
            }else{
                
            }
        }
    }];
    [JVERIFICATIONService customUIWithConfig:telecomUIConfig customViews:^(UIView *customAreaView) {
        for (NSDictionary *widgetDic in widgets) {
            NSString *type = [self getValue:widgetDic key:@"type"];
            if ([type isEqualToString:@"textView"]) {
                [customAreaView addSubview:[self addCustomTextWidget:widgetDic]];
            }else if ([type isEqualToString:@"button"]){
                [customAreaView addSubview:[self addCustomButtonWidget:widgetDic]];
            }else{
                
            }
        }
    }];
}
#pragma mark - 自定义授权页面原有的 UI 控件

JVLayoutConstraint *JVLayoutTop(CGFloat top,JVLayoutItem toItem,NSLayoutAttribute attr2) {
    return [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:toItem attribute:attr2 multiplier:1 constant:top];
}
JVLayoutConstraint *JVLayoutLeft(CGFloat left,JVLayoutItem toItem,NSLayoutAttribute attr2) {
    return [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:toItem attribute:attr2 multiplier:1 constant:left];
}
JVLayoutConstraint *JVLayoutRight(CGFloat right,JVLayoutItem toItem,NSLayoutAttribute attr2) {
    return [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:toItem attribute:attr2 multiplier:1 constant:right];
}
JVLayoutConstraint *JVLayoutCenterX(CGFloat centerX) {
    return [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemSuper attribute:NSLayoutAttributeCenterX multiplier:1 constant:centerX];
}
JVLayoutConstraint *JVLayoutWidth(CGFloat widht) {
    return [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemNone attribute:NSLayoutAttributeWidth multiplier:1 constant:widht];
}
JVLayoutConstraint *JVLayoutHeight(CGFloat height) {
    return [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemNone attribute:NSLayoutAttributeHeight multiplier:1 constant:height];
}

/**
 自定义授权页面原有的 UI 控件

 @param mobileUIConfig 移动
 @param unicomUIConfig 联通
 @param telecomUIConfig 电信
 @param config 自定义配置
 */
- (void)setCustomUIWithConfigWithMobile:(JVUIConfig *)mobileUIConfig
                                 unicom:(JVUIConfig *)unicomUIConfig
                                telecom:(JVUIConfig *)telecomUIConfig
                        configArguments:(NSDictionary *)config {
    JVLog(@"Action - setCustomUIWithConfigWithMobile:::");
    
    mobileUIConfig.barStyle = 0;
    unicomUIConfig.barStyle = 0;
    telecomUIConfig.barStyle = 0;

     /************** 背景 ***************/
    NSString *authBackgroundImage = [config objectForKey:@"authBackgroundImage"];
    authBackgroundImage = authBackgroundImage?:nil;
    if (authBackgroundImage) {
        mobileUIConfig.authPageBackgroundImage = [UIImage imageNamed:authBackgroundImage];
        unicomUIConfig.authPageBackgroundImage = [UIImage imageNamed:authBackgroundImage];
        telecomUIConfig.authPageBackgroundImage = [UIImage imageNamed:authBackgroundImage];
    }
    
     /************** 导航栏 ***************/
    NSNumber *navHidden = [self getValue:config key:@"navHidden"];
    if (navHidden) {
        mobileUIConfig.navCustom = [navHidden boolValue];
        unicomUIConfig.navCustom = [navHidden boolValue];
        telecomUIConfig.navCustom = [navHidden boolValue];
    }
    NSNumber *navReturnBtnHidden = [self getValue:config key:@"navReturnBtnHidden"];
    if (navReturnBtnHidden) {
        mobileUIConfig.navReturnHidden = [navReturnBtnHidden boolValue];
        unicomUIConfig.navReturnHidden = [navReturnBtnHidden boolValue];
        telecomUIConfig.navReturnHidden = [navReturnBtnHidden boolValue];
    }
    
    NSNumber *navColor = [self getValue:config key:@"navColor"];
    if (navColor) {
        mobileUIConfig.navColor  = UIColorFromRGB([navColor intValue]);
        unicomUIConfig.navColor  = UIColorFromRGB([navColor intValue]);
        telecomUIConfig.navColor = UIColorFromRGB([navColor intValue]);
    }
    
    NSString *navText = [self getValue:config key:@"navText"];
    if (!navText) {
        navText = @"登录";
    }
    UIColor *navTextColor = UIColorFromRGB(-1);
    if ([self getValue:config key:@"navTextColor"]) {
        navTextColor = UIColorFromRGB([[self getValue:config key:@"navTextColor"] intValue]);
    }
    NSDictionary *navTextAttr = @{NSForegroundColorAttributeName:navTextColor};
    NSAttributedString *attr = [[NSAttributedString alloc]initWithString:navText attributes:navTextAttr];
    mobileUIConfig.navText = attr;
    unicomUIConfig.navText = attr;
    telecomUIConfig.navText = attr;
    
    NSString *imageName =[self getValue:config key:@"navReturnImgPath"];
    if(imageName){
        mobileUIConfig.navReturnImg  = [UIImage imageNamed:imageName];
        unicomUIConfig.navReturnImg  = [UIImage imageNamed:imageName];
        telecomUIConfig.navReturnImg = [UIImage imageNamed:imageName];
    }
    mobileUIConfig.navReturnHidden = NO;
    unicomUIConfig.navReturnHidden = NO;
    telecomUIConfig.navReturnHidden = NO;
    
    
    /************** logo ***************/
    JVLayoutItem logoLayoutItem = [self getLayotItem:[self getValue:config key:@"logoVerticalLayoutItem"]];
    NSNumber *logoWidth = [self getNumberValue:config key:@"logoWidth"];
    NSNumber *logoHeight = [self getNumberValue:config key:@"logoHeight"];
    NSNumber *logoOffsetX = [self getNumberValue:config key:@"logoOffsetX"];
    NSNumber *logoOffsetY = [self getNumberValue:config key:@"logoOffsetY"];
    if (logoLayoutItem == JVLayoutItemNone) {
        mobileUIConfig.logoWidth = [logoWidth floatValue];
        mobileUIConfig.logoHeight = [logoHeight floatValue];
        mobileUIConfig.logoOffsetY = [logoOffsetY floatValue];
        
        unicomUIConfig.logoWidth = [logoWidth floatValue];
        unicomUIConfig.logoHeight = [logoHeight floatValue];
        unicomUIConfig.logoOffsetY = [logoOffsetY floatValue];
        
        telecomUIConfig.logoWidth = [logoWidth floatValue];
        telecomUIConfig.logoHeight = [logoHeight floatValue];
        telecomUIConfig.logoOffsetY = [logoOffsetY floatValue];
    }else{
        
        JVLayoutConstraint *logo_cons_x = JVLayoutCenterX([logoOffsetX floatValue]);
        JVLayoutConstraint *logo_cons_y = JVLayoutTop([logoOffsetY floatValue],logoLayoutItem,NSLayoutAttributeTop);
        JVLayoutConstraint *logo_cons_w = JVLayoutWidth([logoWidth floatValue]);
        JVLayoutConstraint *logo_cons_h = JVLayoutHeight([logoHeight floatValue]);
        
        mobileUIConfig.logoConstraints = @[logo_cons_x,logo_cons_y,logo_cons_w,logo_cons_h];
        unicomUIConfig.logoConstraints = @[logo_cons_x,logo_cons_y,logo_cons_w,logo_cons_h];
        telecomUIConfig.logoConstraints = @[logo_cons_x,logo_cons_y,logo_cons_w,logo_cons_h];
        
        mobileUIConfig.logoHorizontalConstraints = mobileUIConfig.logoConstraints;
        unicomUIConfig.logoHorizontalConstraints = unicomUIConfig.logoConstraints;
        telecomUIConfig.logoHorizontalConstraints = telecomUIConfig.logoConstraints;
    }
    
    NSString *logoImgPath =[self getValue:config key:@"logoImgPath"];
    if(logoImgPath){
        mobileUIConfig.logoImg  = [UIImage imageNamed:logoImgPath];
        unicomUIConfig.logoImg  = [UIImage imageNamed:logoImgPath];
        telecomUIConfig.logoImg = [UIImage imageNamed:logoImgPath];
    }
    
    NSNumber *logoHidden = [self getValue:config key:@"logoHidden"];
    if(logoHidden){
        mobileUIConfig.logoHidden  = [logoHidden boolValue];
        unicomUIConfig.logoHidden  = [logoHidden boolValue];
        telecomUIConfig.logoHidden = [logoHidden boolValue];
    }
    
    /************** num ***************/
    JVLayoutItem numberLayoutItem = [self getLayotItem:[self getValue:config key:@"numberVerticalLayoutItem"]];
    NSNumber *numFieldOffsetX = [self getNumberValue:config key:@"numFieldOffsetX"];
    NSNumber *numFieldOffsetY = [self getNumberValue:config key:@"numFieldOffsetY"];
    NSNumber *numberFieldWidth = [self getNumberValue:config key:@"numberFieldWidth"];
    NSNumber *numberFieldHeight = [self getNumberValue:config key:@"numberFieldHeight"];
    if (numberLayoutItem == JVLayoutItemNone) {
        mobileUIConfig.numFieldOffsetY = [numFieldOffsetY floatValue];
        unicomUIConfig.numFieldOffsetY = [numFieldOffsetY floatValue];
        telecomUIConfig.numFieldOffsetY = [numFieldOffsetY floatValue];
    }else{
        JVLayoutConstraint *num_cons_x = JVLayoutCenterX([numFieldOffsetX floatValue]);
        JVLayoutConstraint *num_cons_y = JVLayoutTop([numFieldOffsetY floatValue],numberLayoutItem,NSLayoutAttributeBottom);
        JVLayoutConstraint *num_cons_w = JVLayoutWidth([numberFieldWidth floatValue]);
        JVLayoutConstraint *num_cons_h = JVLayoutHeight([numberFieldHeight floatValue]);
        
        mobileUIConfig.numberConstraints = @[num_cons_x,num_cons_y,num_cons_w,num_cons_h];
        unicomUIConfig.numberConstraints = @[num_cons_x,num_cons_y,num_cons_w,num_cons_h];
        telecomUIConfig.numberConstraints = @[num_cons_x,num_cons_y,num_cons_w,num_cons_h];
        
        mobileUIConfig.numberHorizontalConstraints = mobileUIConfig.numberConstraints;
        unicomUIConfig.numberHorizontalConstraints = unicomUIConfig.numberConstraints;
        telecomUIConfig.numberHorizontalConstraints = telecomUIConfig.numberConstraints;
    }
    
    NSNumber *numberColor = [self getValue:config key:@"numberColor"];
    if(numberColor){
        mobileUIConfig.numberColor  = UIColorFromRGB([numberColor intValue]);
        unicomUIConfig.numberColor  = UIColorFromRGB([numberColor intValue]);
        telecomUIConfig.numberColor = UIColorFromRGB([numberColor intValue]);
    }
    
    NSNumber *numberSize = [self getValue:config key:@"numberSize"];
    if (numberSize) {
        mobileUIConfig.numberFont = [UIFont systemFontOfSize:[numberSize floatValue]];
        unicomUIConfig.numberFont = [UIFont systemFontOfSize:[numberSize floatValue]];
        telecomUIConfig.numberFont = [UIFont systemFontOfSize:[numberSize floatValue]];
    }
    
    /************** slogan ***************/
    JVLayoutItem sloganLayoutItem = [self getLayotItem:[self getValue:config key:@"sloganVerticalLayoutItem"]];
    NSNumber *sloganOffsetX = [self getNumberValue:config key:@"sloganOffsetX"];
    NSNumber *sloganOffsetY = [self getNumberValue:config key:@"sloganOffsetY"];
    if (sloganLayoutItem == JVLayoutItemNone) {
        mobileUIConfig.sloganOffsetY = [sloganOffsetY floatValue];
        unicomUIConfig.sloganOffsetY = [sloganOffsetY floatValue];
        telecomUIConfig.sloganOffsetY = [sloganOffsetY floatValue];
    }else{
        JVLayoutConstraint *slogan_cons_top = JVLayoutTop([sloganOffsetY floatValue], sloganLayoutItem,NSLayoutAttributeBottom);
        JVLayoutConstraint *slogan_cons_centerx = JVLayoutCenterX([sloganOffsetX floatValue]);
        
        mobileUIConfig.sloganConstraints = @[slogan_cons_top,slogan_cons_centerx];
        unicomUIConfig.sloganConstraints = @[slogan_cons_top,slogan_cons_centerx];
        telecomUIConfig.sloganConstraints = @[slogan_cons_top,slogan_cons_centerx];
        
        mobileUIConfig.sloganHorizontalConstraints = mobileUIConfig.sloganConstraints;
        unicomUIConfig.sloganHorizontalConstraints = unicomUIConfig.sloganConstraints;
        telecomUIConfig.sloganHorizontalConstraints = telecomUIConfig.sloganConstraints;
    }
    
    NSNumber *sloganTextColor = [self getValue:config key:@"sloganTextColor"];
    if(sloganTextColor){
        mobileUIConfig.sloganTextColor  = UIColorFromRGB([sloganTextColor integerValue]);
        unicomUIConfig.sloganTextColor  = UIColorFromRGB([sloganTextColor integerValue]);
        telecomUIConfig.sloganTextColor = UIColorFromRGB([sloganTextColor integerValue]);
    }
    
    NSNumber *sloganTextSize = [self getValue:config key:@"sloganTextSize"];
    if (sloganTextSize) {
        mobileUIConfig.sloganFont = [UIFont systemFontOfSize:[sloganTextSize floatValue]];
        unicomUIConfig.sloganFont = [UIFont systemFontOfSize:[sloganTextSize floatValue]];
        telecomUIConfig.sloganFont = [UIFont systemFontOfSize:[sloganTextSize floatValue]];
    }
    
    /************** login btn ***************/
    JVLayoutItem logBtnLayoutItem = [self getLayotItem:[self getValue:config key:@"logBtnVerticalLayoutItem"]];
    NSNumber *logBtnOffsetX = [self getNumberValue:config key:@"logBtnOffsetX"];
    NSNumber *logBtnOffsetY = [self getNumberValue:config key:@"logBtnOffsetY"];
    NSNumber *logBtnWidth   = [self getNumberValue:config key:@"logBtnWidth"];
    NSNumber *logBtnHeight  = [self getNumberValue:config key:@"logBtnHeight"];
    if (logBtnLayoutItem == JVLayoutItemNone) {
        mobileUIConfig.logBtnOffsetY = [logBtnOffsetY floatValue];
        unicomUIConfig.logBtnOffsetY = [logBtnOffsetY floatValue];
        telecomUIConfig.logBtnOffsetY = [logBtnOffsetY floatValue];
    }else{
        JVLayoutConstraint *logoBtn_cons_x = JVLayoutCenterX([logBtnOffsetX floatValue]);
        JVLayoutConstraint *logoBtn_cons_y = JVLayoutTop([logBtnOffsetY floatValue], logBtnLayoutItem,NSLayoutAttributeBottom);
        JVLayoutConstraint *logoBtn_cons_w = JVLayoutWidth([logBtnWidth floatValue]);
        JVLayoutConstraint *logoBtn_cons_h = JVLayoutHeight([logBtnHeight floatValue]);
        
        mobileUIConfig.logBtnConstraints  = @[logoBtn_cons_x,logoBtn_cons_y,logoBtn_cons_w,logoBtn_cons_h];
        unicomUIConfig.logBtnConstraints  = @[logoBtn_cons_x,logoBtn_cons_y,logoBtn_cons_w,logoBtn_cons_h];
        telecomUIConfig.logBtnConstraints = @[logoBtn_cons_x,logoBtn_cons_y,logoBtn_cons_w,logoBtn_cons_h];
        
        mobileUIConfig.logBtnHorizontalConstraints  = mobileUIConfig.logBtnConstraints;
        unicomUIConfig.logBtnHorizontalConstraints  = unicomUIConfig.logBtnConstraints;
        telecomUIConfig.logBtnHorizontalConstraints = telecomUIConfig.logBtnConstraints;
    }
    
    NSString *logBtnText = [self getValue:config key:@"logBtnText"];
    if(logBtnText){
        mobileUIConfig.logBtnText  = logBtnText;
        unicomUIConfig.logBtnText  = logBtnText;
        telecomUIConfig.logBtnText = logBtnText;
    }
    NSNumber *logBtnTextSize = [self getValue:config key:@"logBtnTextSize"];
    if (logBtnTextSize) {
        mobileUIConfig.logBtnFont = [UIFont systemFontOfSize:[logBtnTextSize floatValue]];
        unicomUIConfig.logBtnFont = [UIFont systemFontOfSize:[logBtnTextSize floatValue]];
        telecomUIConfig.logBtnFont = [UIFont systemFontOfSize:[logBtnTextSize floatValue]];
    }
    NSNumber *logBtnTextColor = [self getValue:config key:@"logBtnTextColor"];
    if(logBtnTextColor){
        mobileUIConfig.logBtnTextColor  = UIColorFromRGB([logBtnTextColor integerValue]);
        unicomUIConfig.logBtnTextColor  = UIColorFromRGB([logBtnTextColor integerValue]);
        telecomUIConfig.logBtnTextColor = UIColorFromRGB([logBtnTextColor integerValue]);
    }
    
    NSString *loginBtnNormalImage = [config objectForKey:@"loginBtnNormalImage"];
    loginBtnNormalImage = loginBtnNormalImage?:nil;
    NSString *loginBtnPressedImage = [config objectForKey:@"loginBtnPressedImage"];
    loginBtnPressedImage = loginBtnPressedImage?:nil;
    NSString *loginBtnUnableImage = [config objectForKey:@"loginBtnUnableImage"];
    loginBtnUnableImage = loginBtnUnableImage?:nil;
    NSArray * images =[[NSArray alloc]initWithObjects:[UIImage imageNamed:loginBtnNormalImage],[UIImage imageNamed:loginBtnPressedImage],[UIImage imageNamed:loginBtnUnableImage],nil];
    mobileUIConfig.logBtnImgs = images;
    unicomUIConfig.logBtnImgs = images;
    telecomUIConfig.logBtnImgs = images;
    
    /************** chck box ***************/
    CGFloat privacyCheckboxSize = [[self getNumberValue:config key:@"privacyCheckboxSize"] floatValue];
    if (privacyCheckboxSize == 0) {
        privacyCheckboxSize = 20.0;
    }
    BOOL privacyCheckboxInCenter = [[self getValue:config key:@"privacyCheckboxInCenter"] boolValue];
    
    JVLayoutConstraint *box_cons_x = [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemPrivacy attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
    JVLayoutConstraint *box_cons_y = [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemPrivacy attribute:NSLayoutAttributeTop multiplier:1 constant:3];
    if (privacyCheckboxInCenter) {
        box_cons_y = [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemPrivacy attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
    }
    JVLayoutConstraint *box_cons_w = [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemNone attribute:NSLayoutAttributeWidth multiplier:1 constant:privacyCheckboxSize];
    JVLayoutConstraint *box_cons_h = [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemNone attribute:NSLayoutAttributeHeight multiplier:1 constant:privacyCheckboxSize];
    
    mobileUIConfig.checkViewConstraints = @[box_cons_x,box_cons_y,box_cons_w,box_cons_h];
    unicomUIConfig.checkViewConstraints = @[box_cons_x,box_cons_y,box_cons_w,box_cons_h];
    telecomUIConfig.checkViewConstraints = @[box_cons_x,box_cons_y,box_cons_w,box_cons_h];
    
    mobileUIConfig.checkViewHorizontalConstraints = mobileUIConfig.checkViewConstraints;
    unicomUIConfig.checkViewHorizontalConstraints = unicomUIConfig.checkViewConstraints;
    telecomUIConfig.checkViewHorizontalConstraints = telecomUIConfig.checkViewConstraints;
    
    BOOL privacyCheckboxHidden = [[self getValue:config key:@"privacyCheckboxHidden"] boolValue];
    mobileUIConfig.checkViewHidden = privacyCheckboxHidden;
    unicomUIConfig.checkViewHidden = privacyCheckboxHidden;
    telecomUIConfig.checkViewHidden = privacyCheckboxHidden;
    
    NSNumber *privacyState = [self getValue:config key:@"privacyState"];
    mobileUIConfig.privacyState = [privacyState boolValue];
    unicomUIConfig.privacyState = [privacyState boolValue];
    telecomUIConfig.privacyState = [privacyState boolValue];
    
    NSString *uncheckedImgPath = [config objectForKey:@"uncheckedImgPath"];
    if (uncheckedImgPath) {
        mobileUIConfig.uncheckedImg  = [UIImage imageNamed:uncheckedImgPath];
        unicomUIConfig.uncheckedImg  = [UIImage imageNamed:uncheckedImgPath];
        telecomUIConfig.uncheckedImg = [UIImage imageNamed:uncheckedImgPath];
    }
    NSString *checkedImgPath = [config objectForKey:@"checkedImgPath"];
    if (checkedImgPath) {
        mobileUIConfig.checkedImg  = [UIImage imageNamed:checkedImgPath];
        unicomUIConfig.checkedImg  = [UIImage imageNamed:checkedImgPath];
        telecomUIConfig.checkedImg = [UIImage imageNamed:checkedImgPath];
    }

    /************** privacy ***************/
    BOOL isCenter = [[self getValue:config key:@"privacyTextCenterGravity"] boolValue];
    NSTextAlignment alignmet = isCenter?NSTextAlignmentCenter:NSTextAlignmentLeft;
    mobileUIConfig.privacyTextAlignment = alignmet;
    unicomUIConfig.privacyTextAlignment = alignmet;
    telecomUIConfig.privacyTextAlignment = alignmet;
    
    BOOL privacyWithBookTitleMark = [[self getValue:config key:@"privacyWithBookTitleMark"] boolValue];
    mobileUIConfig.privacyShowBookSymbol = privacyWithBookTitleMark;
    unicomUIConfig.privacyShowBookSymbol = privacyWithBookTitleMark;
    telecomUIConfig.privacyShowBookSymbol = privacyWithBookTitleMark;
    
    NSString *tempSting = @"";
    NSString *clauseName = [self getValue:config key:@"clauseName"];
    NSString *clauseUrl = [self getValue:config key:@"clauseUrl"];
    if (clauseName && clauseUrl) {
        mobileUIConfig.appPrivacyOne  = @[clauseName,clauseUrl];
        unicomUIConfig.appPrivacyOne  = @[clauseName,clauseUrl];
        telecomUIConfig.appPrivacyOne = @[clauseName,clauseUrl];
        tempSting = [tempSting stringByAppendingFormat:@"%@%@%@",(privacyWithBookTitleMark?@"《":@""),clauseName,(privacyWithBookTitleMark?@"》":@"")];
    }
    
    NSString *clauseNameTwo = [self getValue:config key:@"clauseNameTwo"];
    NSString *clauseUrlTwo = [self getValue:config key:@"clauseUrlTwo"];
    if (clauseNameTwo && clauseUrlTwo) {
        mobileUIConfig.appPrivacyTwo  = @[clauseNameTwo,clauseUrlTwo];
        unicomUIConfig.appPrivacyTwo  = @[clauseNameTwo,clauseUrlTwo];
        telecomUIConfig.appPrivacyTwo = @[clauseNameTwo,clauseUrlTwo];
        tempSting = [tempSting stringByAppendingFormat:@"%@%@%@",(privacyWithBookTitleMark?@"《":@""),clauseNameTwo,(privacyWithBookTitleMark?@"》":@"")];
    }
    
    NSArray *privacyComponents = [self getValue:config key:@"privacyText"];
    if (privacyComponents.count) {
        mobileUIConfig.privacyComponents = privacyComponents;
        unicomUIConfig.privacyComponents = privacyComponents;
        telecomUIConfig.privacyComponents = privacyComponents;
        tempSting = [tempSting stringByAppendingString:[privacyComponents componentsJoinedByString:@"、"]];
    }
    
    NSNumber *privacyTextSize = [self getValue:config key:@"privacyTextSize"];
    if (privacyTextSize) {
        mobileUIConfig.privacyTextFontSize = [privacyTextSize floatValue];
        unicomUIConfig.privacyTextFontSize = [privacyTextSize floatValue];
        telecomUIConfig.privacyTextFontSize = [privacyTextSize floatValue];
    }
    
    JVLayoutItem privacyLayoutItem = [self getLayotItem:[self getValue:config key:@"privacyVerticalLayoutItem"]];
    NSNumber *privacyOffsetY = [self getNumberValue:config key:@"privacyOffsetY"];
    NSNumber *privacyOffsetX = [self getValue:config key:@"privacyOffsetX"];
    
    CGFloat privacyLeftSpace = 0;
    CGFloat privacyRightSpace = 15;
    if (privacyOffsetX == nil) {
        mobileUIConfig.privacyTextAlignment = NSTextAlignmentCenter;
        privacyOffsetX = @(15);
        privacyLeftSpace = [privacyOffsetX floatValue] + privacyCheckboxSize;
        privacyRightSpace = privacyCheckboxSize;
    }else{
        privacyLeftSpace = [privacyOffsetX floatValue];
        privacyRightSpace = privacyLeftSpace - privacyCheckboxSize;
    }
    
    tempSting = [tempSting stringByAppendingString:@"《xxx统一认证服务条款》"];
    CGFloat lableWidht = [UIScreen mainScreen].bounds.size.width - [privacyOffsetX floatValue]*2 - privacyCheckboxSize*3;
    CGSize lablesize = [tempSting boundingRectWithSize:CGSizeMake(lableWidht, MAXFLOAT)
                                          options:NSStringDrawingUsesLineFragmentOrigin
                                       attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:[privacyTextSize floatValue]+2]}
                                          context:nil].size;
    
    JVLayoutConstraint *privacy_cons_left = [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemSuper attribute:NSLayoutAttributeLeft multiplier:1 constant:privacyLeftSpace];
    JVLayoutConstraint *privacy_cons_right = [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemSuper attribute:NSLayoutAttributeRight multiplier:1 constant:-(privacyRightSpace)];
    JVLayoutConstraint *privacy_cons_y = [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemSuper attribute:NSLayoutAttributeBottom multiplier:1 constant:-[privacyOffsetY floatValue]];
    JVLayoutConstraint *privacy_cons_h = [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemNone attribute:NSLayoutAttributeHeight multiplier:1 constant:lablesize.height];
    
    if (privacyLayoutItem == JVLayoutItemNone) {
        mobileUIConfig.privacyOffsetY = [privacyOffsetY floatValue];
        unicomUIConfig.privacyOffsetY = [privacyOffsetY floatValue];
        telecomUIConfig.privacyOffsetY = [privacyOffsetY floatValue];
    }else{
        mobileUIConfig.privacyConstraints = @[privacy_cons_left,privacy_cons_y,privacy_cons_right,privacy_cons_h];
        unicomUIConfig.privacyConstraints = @[privacy_cons_left,privacy_cons_y,privacy_cons_right,privacy_cons_h];
        telecomUIConfig.privacyConstraints = @[privacy_cons_left,privacy_cons_y,privacy_cons_right,privacy_cons_h];
        
        mobileUIConfig.privacyHorizontalConstraints = mobileUIConfig.privacyConstraints;
        unicomUIConfig.privacyHorizontalConstraints = unicomUIConfig.privacyConstraints;
        telecomUIConfig.privacyHorizontalConstraints = telecomUIConfig.privacyConstraints;
    }
    
    NSNumber *clauseBaseColor = [self getValue:config key:@"clauseBaseColor"];
    UIColor *privacyBasicColor =[UIColor grayColor];
    if(clauseBaseColor){
        privacyBasicColor =  UIColorFromRGB([clauseBaseColor integerValue]);
    }
    NSNumber *clauseColor = [self getValue:config key:@"clauseColor"];
    UIColor *privacyColor = UIColorFromRGB(-16007674);
    if(clauseColor){
        privacyColor =UIColorFromRGB([clauseColor integerValue]);
    }
    mobileUIConfig.appPrivacyColor  = @[privacyBasicColor,privacyColor];
    unicomUIConfig.appPrivacyColor  = @[privacyBasicColor,privacyColor];
    telecomUIConfig.appPrivacyColor = @[privacyBasicColor,privacyColor];
    
    
    /************** 协议 web 页面 ***************/
    NSNumber *privacyNavColor = [self getValue:config key:@"privacyNavColor"];
    if (navColor) {
        mobileUIConfig.agreementNavBackgroundColor  = UIColorFromRGB([privacyNavColor intValue]);
        unicomUIConfig.agreementNavBackgroundColor  = UIColorFromRGB([privacyNavColor intValue]);
        telecomUIConfig.agreementNavBackgroundColor = UIColorFromRGB([privacyNavColor intValue]);
    }
    
    NSString *privacyNavText = @"服务条款"; //[self getValue:config key:@"navText"];

    UIColor *privacyNavTitleTextColor = UIColorFromRGB(-1);
    if ([self getValue:config key:@"privacyNavTitleTextColor"]) {
        privacyNavTitleTextColor = UIColorFromRGB([[self getValue:config key:@"privacyNavTitleTextColor"] intValue]);
    }
    NSNumber *privacyNavTitleTextSize = [self getValue:config key:@"privacyNavTitleTextSize"];
    if (!privacyNavTitleTextSize) {
        privacyNavTitleTextSize = @(16);
    }
    NSDictionary *privayNavTextAttr = @{NSForegroundColorAttributeName:privacyNavTitleTextColor,
                                        NSFontAttributeName:[UIFont systemFontOfSize:[privacyNavTitleTextSize floatValue]]};
    NSAttributedString *privayAttr = [[NSAttributedString alloc]initWithString:privacyNavText attributes:privayNavTextAttr];
    mobileUIConfig.agreementNavText = privayAttr;
    unicomUIConfig.agreementNavText = privayAttr;
    telecomUIConfig.agreementNavText = privayAttr;
    
    NSString *privacyNavReturnBtnImage =[self getValue:config key:@"privacyNavReturnBtnImage"];
    if(privacyNavReturnBtnImage){
        mobileUIConfig.agreementNavReturnImage  = [UIImage imageNamed:privacyNavReturnBtnImage];
        unicomUIConfig.agreementNavReturnImage  = [UIImage imageNamed:privacyNavReturnBtnImage];
        telecomUIConfig.agreementNavReturnImage = [UIImage imageNamed:privacyNavReturnBtnImage];
    }
}

#pragma mark - 添加 label
- (UILabel *)addCustomTextWidget:(NSDictionary *)widgetDic {
    JVLog(@"Action - addCustomTextWidget:");
    UILabel *label = [[UILabel alloc] init];
    
    NSInteger left = [[self getValue:widgetDic key:@"left"] integerValue];
    NSInteger top = [[self getValue:widgetDic key:@"top"] integerValue];
    NSInteger width = [[self getValue:widgetDic key:@"width"] integerValue];
    NSInteger height = [[self getValue:widgetDic key:@"height"] integerValue];
    
    NSString *title = [self getValue:widgetDic key:@"title"];
    if (title) {
        label.text = title;
    }
    NSNumber *titleColor = [self getValue:widgetDic key:@"titleColor"];
    if (titleColor) {
        label.textColor = UIColorFromRGB([titleColor integerValue]);
    }
    NSNumber *backgroundColor = [self getValue:widgetDic key:@"backgroundColor"];
    if (backgroundColor) {
        label.backgroundColor = UIColorFromRGB([backgroundColor integerValue]);
    }
    NSString *textAlignment = [self getValue:widgetDic key:@"textAlignment"];
    if (textAlignment) {
        label.textAlignment = [self getTextAlignment:textAlignment];
    }
    
    NSNumber *font = [self getValue:widgetDic key:@"titleFont"];
    if (font) {
        label.font = [UIFont systemFontOfSize:[font floatValue]];
    }
    
    NSNumber *lines = [self getValue:widgetDic key:@"lines"];
    if (lines) {
        label.numberOfLines = [lines integerValue];
    }
    NSNumber *isSingleLine = [self getValue:widgetDic key:@"isSingleLine"];
    if (![isSingleLine boolValue]) {
        label.numberOfLines = 0;
        NSDictionary *attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:20],};
        CGSize textSize = [label.text boundingRectWithSize:CGSizeMake(width, height) options:NSStringDrawingTruncatesLastVisibleLine attributes:attributes context:nil].size;
        height = textSize.height;
    }
    
    NSNumber *isShowUnderline = [self getValue:widgetDic key:@"isShowUnderline"];
    if ([isShowUnderline boolValue]) {
        NSDictionary *attribtDic = @{NSUnderlineStyleAttributeName: [NSNumber numberWithInteger:NSUnderlineStyleSingle]};
        NSMutableAttributedString *attribtStr = [[NSMutableAttributedString alloc]initWithString:title attributes:attribtDic];
        label.attributedText = attribtStr;
    }
    
    NSString *widgetId = [self getValue:widgetDic key:@"widgetId"];
    
    label.frame = CGRectMake(left, top, width, height);
    
    NSNumber *isClickEnable = [self getValue:widgetDic key:@"isClickEnable"];
    if ([isClickEnable boolValue]) {
        NSString *tag = @"1001";
        label.userInteractionEnabled = YES;
        
        UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickTextWidgetAction:)];
        [singleTapGestureRecognizer setNumberOfTapsRequired:1];
        [label addGestureRecognizer:singleTapGestureRecognizer];
        singleTapGestureRecognizer.view.tag = [tag integerValue];
        
        [self.customWidgetIdDic setObject:widgetId forKey:tag];
    }
    
    return label;
}
- (void)clickTextWidgetAction:(UITapGestureRecognizer *)gestureRecognizer {
    JVLog(@"Action - clickTextWidgetAction:");
    NSString *tag = [NSString stringWithFormat:@"%@",@(gestureRecognizer.view.tag)];
    if (tag) {
        NSString *widgetId = [self.customWidgetIdDic objectForKey:tag];
        [_channel invokeMethod:@"onReceiveClickWidgetEvent" arguments:@{@"widgetId":widgetId}];
    }
}


#pragma mark - 添加 button
- (UIButton *)addCustomButtonWidget:(NSDictionary *)widgetDic {
    JVLog(@"Action - addCustomButtonWidget:");
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    NSInteger left = [[self getValue:widgetDic key:@"left"] integerValue];
    NSInteger top = [[self getValue:widgetDic key:@"top"] integerValue];
    NSInteger width = [[self getValue:widgetDic key:@"width"] integerValue];
    NSInteger height = [[self getValue:widgetDic key:@"height"] integerValue];
    
    NSString *title = [self getValue:widgetDic key:@"title"];
    if (title) {
        [button setTitle:title forState:UIControlStateNormal];
        [button setTitle:title forState:UIControlStateHighlighted];
    }
    NSNumber *titleColor = [self getValue:widgetDic key:@"titleColor"];
    if (titleColor) {
        [button setTitleColor:UIColorFromRGB([titleColor integerValue]) forState:UIControlStateNormal];
    }
    NSNumber *backgroundColor = [self getValue:widgetDic key:@"backgroundColor"];
    if (backgroundColor) {
        [button setBackgroundColor:UIColorFromRGB([backgroundColor integerValue])];
    }
    NSString *textAlignment = [self getValue:widgetDic key:@"textAlignment"];
    if (textAlignment) {
        button.contentHorizontalAlignment = [self getButtonTitleAlignment:textAlignment];
    }
    
    NSNumber *font = [self getValue:widgetDic key:@"titleFont"];
    if (font) {
        button.titleLabel.font = [UIFont systemFontOfSize:[font floatValue]];
    }
    /*
    NSNumber *isSingleLine = [self getValue:widgetDic key:@"isSingleLine"];
    if (![isSingleLine boolValue]) {
        label.numberOfLines = 0;
        NSDictionary *attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:20],};
        CGSize textSize = [label.text boundingRectWithSize:CGSizeMake(width, height) options:NSStringDrawingTruncatesLastVisibleLine attributes:attributes context:nil].size;
        height = textSize.height;
    }
    
     NSNumber *lines = [self getValue:widgetDic key:@"lines"];
     if (lines) {
     label.numberOfLines = [lines integerValue];
     }
     NSNumber *maxLines = [self getValue:widgetDic key:@"maxLines"];
     if (maxLines) {
     }
     */
    
    
    NSNumber *isShowUnderline = [self getValue:widgetDic key:@"isShowUnderline"];
    if ([isShowUnderline boolValue]) {
        NSDictionary *attribtDic = @{NSUnderlineStyleAttributeName: [NSNumber numberWithInteger:NSUnderlineStyleSingle]};
        NSMutableAttributedString *attribtStr = [[NSMutableAttributedString alloc]initWithString:title attributes:attribtDic];
        button.titleLabel.attributedText = attribtStr;
    }
    
    button.frame = CGRectMake(left, top, width, height);
    
    NSNumber *isClickEnable = [self getValue:widgetDic key:@"isClickEnable"];
    button.userInteractionEnabled = [isClickEnable boolValue];
    [button addTarget:self action:@selector(clickCustomWidgetAction:) forControlEvents:UIControlEventTouchUpInside];
    NSString *tag = @"1002";
    button.tag = [tag integerValue];
    
    NSString *widgetId = [self getValue:widgetDic key:@"widgetId"];
    [self.customWidgetIdDic setObject:widgetId forKey:tag];
    
    
    NSString *btnNormalImageName = [self getValue:widgetDic key:@"btnNormalImageName"];
    NSString *btnPressedImageName = [self getValue:widgetDic key:@"btnPressedImageName"];
    if (!btnPressedImageName) {
        btnPressedImageName = btnNormalImageName;
    }
    if (btnNormalImageName) {
        [button setBackgroundImage:[UIImage imageNamed:btnNormalImageName] forState:UIControlStateNormal];
    }
    if (btnPressedImageName) {
        [button setBackgroundImage:[UIImage imageNamed:btnPressedImageName] forState:UIControlStateHighlighted];
        [button setBackgroundImage:[UIImage imageNamed:btnPressedImageName] forState:UIControlStateSelected];
    }
    
    return button;
}

- (void)clickCustomWidgetAction:(UIButton *)button {
    JVLog(@"Action - clickCustomWidgetAction:");
    
    NSString *tag = [NSString stringWithFormat:@"%@",@(button.tag)];
    if (tag) {
        NSString *widgetId = [self.customWidgetIdDic objectForKey:tag];
        [_channel invokeMethod:@"onReceiveClickWidgetEvent" arguments:@{@"widgetId":widgetId}];
    }
}

#pragma mark - 其他
- (id)getValue:(NSDictionary *)arguments key:(NSString*) key{
    if (arguments && ![arguments[key] isKindOfClass:[NSNull class]]) {
        return arguments[key]?:nil;
    }else{
        return nil;
    }
}
- (id)getNumberValue:(NSDictionary *)arguments key:(NSString*) key{
    if (arguments && ![arguments[key] isKindOfClass:[NSNull class]]) {
        return arguments[key]?:@(0);
    }else{
        return @(0);
    }
}


//- (id)object:(FlutterMethodCall*)caller forKey:(NSString *)key {
//    if (caller && ![caller.arguments[key] isKindOfClass:[NSNull class]]) {
//        return caller.arguments[key]?:nil;
//    }
//    return nil;
//}
- (JVLayoutItem)getLayotItem:(NSString *)itemString {
    JVLayoutItem item = JVLayoutItemNone;
    if (itemString) {
        if ([itemString isEqualToString:@"ItemNone"]) {
            item = JVLayoutItemNone;
        }else if ([itemString isEqualToString:@"ItemLogo"]) {
            item = JVLayoutItemLogo;
        }else if ([itemString isEqualToString:@"ItemNumber"]) {
            item = JVLayoutItemNumber;
        }else if ([itemString isEqualToString:@"ItemSlogan"]) {
            item = JVLayoutItemSlogan;
        }else if ([itemString isEqualToString:@"ItemLogin"]) {
            item = JVLayoutItemLogin;
        }else if ([itemString isEqualToString:@"ItemCheck"]) {
            item = JVLayoutItemCheck;
        }else if ([itemString isEqualToString:@"ItemPrivacy"]) {
            item = JVLayoutItemPrivacy;
        }else if ([itemString isEqualToString:@"ItemSuper"]) {
            item = JVLayoutItemSuper;
        }else{
            item = JVLayoutItemNone;
        }
    }
    return item;
}
- (NSTextAlignment)getTextAlignment:(NSString *)aligement {
    NSTextAlignment model = NSTextAlignmentLeft;
    if (aligement) {
        if ([aligement isEqualToString:@"left"]) {
            model = NSTextAlignmentLeft;
        }else if ([aligement isEqualToString:@"right"]) {
            model = NSTextAlignmentRight;
        }else if ([aligement isEqualToString:@"center"]) {
            model = NSTextAlignmentCenter;
        }else {
            model = NSTextAlignmentLeft;
        }
    }
    return model;
}
- (UIControlContentHorizontalAlignment)getButtonTitleAlignment:(NSString *)aligement {
    UIControlContentHorizontalAlignment model = UIControlContentHorizontalAlignmentCenter;
    if (aligement) {
        if ([aligement isEqualToString:@"left"]) {
            model = UIControlContentHorizontalAlignmentLeft;
        }else if ([aligement isEqualToString:@"right"]) {
            model = UIControlContentHorizontalAlignmentRight;
        }else if ([aligement isEqualToString:@"center"]) {
            model = UIControlContentHorizontalAlignmentCenter;
        }else {
            model = UIControlContentHorizontalAlignmentCenter;
        }
    }
    return model;
}
- (NSMutableDictionary *)customWidgetIdDic {
    if (!_customWidgetIdDic) {
        _customWidgetIdDic  = [NSMutableDictionary dictionary];
    }
    return _customWidgetIdDic;
}

@end
