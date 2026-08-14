import common from '@ohos.app.ability.common';
import UIAbility from '@ohos.app.ability.UIAbility';
import promptAction from '@ohos.promptAction';
import window from '@ohos.window';
import {
  AbilityAware,
  AbilityPluginBinding,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import {
  JVerificationInterface,
  JVerificationLoginSettings,
} from '@jg/verify';
import { JverifyLog } from '../../core/JverifyLog';
import { JverifyNavigation } from '../../core/JverifyNavigation';
import { JverifyUIAdapter } from '../../core/JverifyUIAdapter';

const CHANNEL_NAME: string = 'jverify';
const CLASS_NAME: string = 'JverifyPlugin';
const NOT_SUPPORTED_CODE: number = -2;
const DEFAULT_TIMEOUT: number = 10000;

export default class JverifyPlugin implements FlutterPlugin, MethodCallHandler, AbilityAware {
  private channel: MethodChannel | null = null;
  private applicationContext?: common.ApplicationContext;
  private ability?: UIAbility;
  private topSafeAreaHeight: number = 44;
  private bottomSafeAreaHeight: number = 0;

  getUniqueClassName(): string {
    return CLASS_NAME;
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    const context: common.Context = binding.getApplicationContext();
    this.applicationContext = context.getApplicationContext();
    this.channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    this.channel.setMethodCallHandler(this);
    JverifyLog.info('engine attached; MethodChannel jverify ready');
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel !== null) {
      this.channel.setMethodCallHandler(null);
    }
    this.channel = null;
    this.applicationContext = undefined;
    JverifyLog.info('engine detached');
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.ability = binding.getAbility();
    this.updateSafeArea();
    JverifyLog.info('ability attached');
  }

  onDetachedFromAbility(): void {
    this.ability = undefined;
    JverifyLog.info('ability detached');
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    JverifyLog.info('method call: ' + call.method);
    switch (call.method) {
      case 'setup':
        this.setup(call, result);
        return;
      case 'setDebugMode':
        this.setDebugMode(call, result);
        return;
      case 'setCollectionAuth':
      case 'setGetCodeInternal':
        JverifyLog.unsupported(call.method);
        result.success(null);
        return;
      case 'getSMSCode':
      case 'verifyNumber':
        result.success(this.unsupportedMap(call.method));
        return;
      case 'isInitSuccess':
        result.success(this.boolMap(JVerificationInterface.isInitSuccess()));
        return;
      case 'checkVerifyEnable':
        this.checkVerifyEnable(result);
        return;
      case 'getToken':
        this.getToken(call, result);
        return;
      case 'preLogin':
        this.preLogin(call, result);
        return;
      case 'validPreloginCache':
        this.validPreloginCache(result);
        return;
      case 'clearPreLoginCache':
        JVerificationInterface.clearPreLoginCache();
        result.success(null);
        return;
      case 'loginAuth':
        this.loginAuth(call, result, false);
        return;
      case 'loginAuthSyncApi':
        this.loginAuth(call, result, true);
        return;
      case 'smsAuth':
        this.unsupportedSmsAuth(call, result);
        return;
      case 'dismissLoginAuthView':
        this.dismissLoginAuthView(result);
        return;
      case 'setCustomAuthorizationView':
        this.applyCustomUI(call, 'portraitConfig', result);
        return;
      case 'setCustomAuthViewAllWidgets':
        this.applyCustomUI(call, 'uiconfig', result);
        return;
      default:
        result.notImplemented();
        return;
    }
  }

  private setup(call: MethodCall, result: MethodResult): void {
    const appKeyValue: Object | null = call.argument('appKey') as Object | null;
    const appKey: string = typeof appKeyValue === 'string' ? appKeyValue : '';
    if (this.applicationContext === undefined || appKey.length === 0) {
      const message: string = this.applicationContext === undefined
        ? 'HarmonyOS ApplicationContext is unavailable'
        : 'appKey is required';
      this.invokeFlutter('onReceiveSDKSetupCallBackEvent', this.codeMap(-3, message));
      result.success(null);
      return;
    }

    const ignoredOptions: Array<string> = new Array<string>();
    const channelValue: Object | null = call.argument('channel') as Object | null;
    if (typeof channelValue === 'string' && channelValue.length > 0) {
      ignoredOptions.push('channel');
    }
    const idfaValue: Object | null = call.argument('useIDFA') as Object | null;
    if (typeof idfaValue === 'boolean') {
      ignoredOptions.push('useIDFA');
    }
    const timeoutValue: Object | null = call.argument('timeout') as Object | null;
    if (typeof timeoutValue === 'number' && timeoutValue !== DEFAULT_TIMEOUT) {
      ignoredOptions.push('timeout');
    }
    const wifiValue: Object | null = call.argument('setControlWifiSwitch') as Object | null;
    if (wifiValue === false) {
      ignoredOptions.push('setControlWifiSwitch');
    }
    if (ignoredOptions.length > 0) {
      JverifyLog.warn('setup ignored unsupported HarmonyOS options: ' + ignoredOptions.join(', '));
    }

    JVerificationInterface.init(this.applicationContext, appKey, (code: number, message: string): void => {
      this.invokeFlutter('onReceiveSDKSetupCallBackEvent', this.codeMap(code, message));
    });
    result.success(null);
  }

  private setDebugMode(call: MethodCall, result: MethodResult): void {
    const debugValue: Object | null = call.argument('debug') as Object | null;
    const debug: boolean = typeof debugValue === 'boolean' ? debugValue : false;
    JVerificationInterface.setDebugMode(debug);
    result.success(this.boolMap(debug));
  }

  private checkVerifyEnable(result: MethodResult): void {
    JVerificationInterface.checkVerifyEnable().then((enabled: boolean): void => {
      result.success(this.boolMap(enabled));
    }).catch((): void => {
      result.success(this.boolMap(false));
    });
  }

  private getToken(call: MethodCall, result: MethodResult): void {
    const timeout: number = this.readTimeout(call, 'timeOut', DEFAULT_TIMEOUT);
    let completed: boolean = false;
    JVerificationInterface.getToken((code: number, message: string, operator: string): void => {
      if (completed) {
        return;
      }
      completed = true;
      result.success(this.codeMap(code, message, operator));
    }, timeout);
  }

  private preLogin(call: MethodCall, result: MethodResult): void {
    const timeout: number = this.readTimeout(call, 'timeOut', DEFAULT_TIMEOUT, 3000, 10000);
    const enableSms: Object | null = call.argument('enableSms') as Object | null;
    if (enableSms === true) {
      JverifyLog.warn('preLogin enableSms is ignored on HarmonyOS');
    }
    let completed: boolean = false;
    JVerificationInterface.prelogin((code: number, message: string, operator: string): void => {
      if (completed) {
        return;
      }
      completed = true;
      result.success(this.codeMap(code, message, operator));
    }, timeout);
  }

  private validPreloginCache(result: MethodResult): void {
    JVerificationInterface.isValidePreloginCache().then((enabled: boolean): void => {
      result.success(this.boolMap(enabled));
    }).catch((): void => {
      result.success(this.boolMap(false));
    });
  }

  private loginAuth(call: MethodCall, result: MethodResult, callbackMode: boolean): void {
    const navPathStack: NavPathStack | undefined = JverifyNavigation.getNavPathStack();
    if (navPathStack === undefined) {
      const message: string = 'A host Navigation NavPathStack is required on HarmonyOS';
      JverifyLog.error(message);
      if (callbackMode) {
        this.invokeLoginCallback(call, -3, message, '');
        result.success(null);
      } else {
        result.success(this.codeMap(-3, message));
      }
      return;
    }
    JverifyLog.info('loginAuth will use the mounted host NavPathStack');

    this.withUiContext((uiContext: UIContext): void => {
      const settings: JVerificationLoginSettings = new JVerificationLoginSettings(uiContext);
      const autoDismissValue: Object | null = call.argument('autoDismiss') as Object | null;
      settings.autoFinish = typeof autoDismissValue === 'boolean' ? autoDismissValue : true;
      settings.timeout = this.readTimeout(call, 'timeout', DEFAULT_TIMEOUT);
      settings.navPathStack = navPathStack;
      settings.isRouter = false;
      settings.authPageEventListener = (code: number, message: string): void => {
        const event: Map<string, Object> = this.codeMap(code, message);
        const indexValue: Object | null = call.argument('loginAuthIndex') as Object | null;
        if (typeof indexValue === 'number') {
          event.set('loginAuthIndex', indexValue);
        }
        this.invokeFlutter('onReceiveAuthPageEvent', event);
      };

      const enableSms: Object | null = call.argument('enableSms') as Object | null;
      if (enableSms === true) {
        JverifyLog.warn('loginAuth enableSms is ignored on HarmonyOS');
      }

      let completed: boolean = false;
      JVerificationInterface.loginAuth(settings,
        (code: number, message: string, operator: string): void => {
          if (completed) {
            return;
          }
          completed = true;
          if (callbackMode) {
            this.invokeLoginCallback(call, code, message, operator);
          } else {
            result.success(this.codeMap(code, message, operator));
          }
        });

      if (callbackMode) {
        result.success(null);
      }
    }, (message: string): void => {
      if (callbackMode) {
        this.invokeLoginCallback(call, -3, message, '');
        result.success(null);
      } else {
        result.success(this.codeMap(-3, message));
      }
    });
  }

  private dismissLoginAuthView(result: MethodResult): void {
    this.withUiContext((uiContext: UIContext): void => {
      JVerificationInterface.dismissLoginAuthActivity(uiContext);
      result.success(null);
    }, (message: string): void => {
      JverifyLog.warn(message);
      result.success(null);
    });
  }

  private applyCustomUI(call: MethodCall, configKey: string, result: MethodResult): void {
    JverifyUIAdapter.apply(call, configKey, (): void => {
      this.invokeFlutter('onReceiveAuthPageBackPressedEvent', new Map<string, Object>());
    }, (id: string): void => {
      const event: Map<string, Object> = new Map<string, Object>();
      event.set('widgetId', id);
      this.invokeFlutter('onReceiveClickWidgetEvent', event);
    }, (): void => {
      this.dismissLoginAuthViewSilently();
    }, (message: string): void => {
      this.showToast(message);
    }, this.topSafeAreaHeight, this.bottomSafeAreaHeight,
    (name: string): string => this.resolveMedia(name));
    result.success(null);
  }

  private updateSafeArea(): void {
    if (this.ability === undefined) {
      return;
    }
    window.getLastWindow(this.ability.context).then((mainWindow: window.Window): void => {
      const avoidArea: window.AvoidArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const uiContext: UIContext = mainWindow.getUIContext();
      const top: number = Math.max(0, uiContext.px2vp(avoidArea.topRect.height));
      this.topSafeAreaHeight = top > 0 ? top : 44;
      this.bottomSafeAreaHeight = Math.max(0, uiContext.px2vp(avoidArea.bottomRect.height));
      JverifyLog.info('safe area cached: top=' + this.topSafeAreaHeight +
        ', bottom=' + this.bottomSafeAreaHeight + ' vp');
    }).catch((): void => {
      JverifyLog.warn('system safe area unavailable; using 44 vp top fallback');
    });
  }

  private dismissLoginAuthViewSilently(): void {
    this.withUiContext((uiContext: UIContext): void => {
      JVerificationInterface.dismissLoginAuthActivity(uiContext);
    }, (message: string): void => {
      JverifyLog.warn(message);
    });
  }

  private showToast(message: string): void {
    if (message.length === 0) {
      return;
    }
    try {
      // The CM authorization page is mounted through Navigation. A Toast from
      // the host UIContext can stay below that page, while the system prompt
      // API is displayed above the active page, matching the official demo.
      promptAction.showToast({ message: message, duration: 3000 });
      JverifyLog.info('custom widget Toast shown: ' + message);
    } catch (error) {
      JverifyLog.warn('custom widget Toast was not shown: ' + JSON.stringify(error));
    }
  }

  private resolveMedia(name: string): string {
    if (this.applicationContext === undefined || name.length === 0) {
      return '';
    }
    try {
      return this.applicationContext.resourceManager.getMediaBase64ByNameSync(name);
    } catch (error) {
      JverifyLog.warn('HarmonyOS media not found: ' + name);
      return '';
    }
  }

  private unsupportedSmsAuth(call: MethodCall, result: MethodResult): void {
    const message: string = JverifyLog.unsupported('smsAuth');
    const event: Map<string, Object> = this.codeMap(NOT_SUPPORTED_CODE, message);
    const indexValue: Object | null = call.argument('smsAuthIndex') as Object | null;
    if (typeof indexValue === 'number') {
      event.set('smsAuthIndex', indexValue);
    }
    this.invokeFlutter('onReceiveSMSAuthCallBackEvent', event);
    result.success(null);
  }

  private invokeLoginCallback(call: MethodCall, code: number, message: string, operator: string): void {
    const event: Map<string, Object> = this.codeMap(code, message, operator);
    const indexValue: Object | null = call.argument('loginAuthIndex') as Object | null;
    if (typeof indexValue === 'number') {
      event.set('loginAuthIndex', indexValue);
    }
    this.invokeFlutter('onReceiveLoginAuthCallBackEvent', event);
  }

  private withUiContext(onSuccess: (context: UIContext) => void,
    onFailure: (message: string) => void): void {
    if (this.ability === undefined) {
      onFailure('HarmonyOS UIAbility is unavailable');
      return;
    }
    window.getLastWindow(this.ability.context).then((mainWindow: window.Window): void => {
      onSuccess(mainWindow.getUIContext());
    }).catch((): void => {
      onFailure('HarmonyOS UIContext is unavailable');
    });
  }

  private readTimeout(call: MethodCall, key: string, fallback: number,
    minimum: number = 1, maximum: number = 30000): number {
    const value: Object | null = call.argument(key) as Object | null;
    if (typeof value === 'number' && value >= minimum && value <= maximum) {
      return value;
    }
    if (typeof value === 'string') {
      const parsed: number = Number(value);
      if (!Number.isNaN(parsed) && parsed >= minimum && parsed <= maximum) {
        return parsed;
      }
    }
    return fallback;
  }

  private unsupportedMap(method: string): Map<string, Object> {
    return this.codeMap(NOT_SUPPORTED_CODE, JverifyLog.unsupported(method));
  }

  private boolMap(value: boolean): Map<string, Object> {
    const result: Map<string, Object> = new Map<string, Object>();
    result.set('result', value);
    return result;
  }

  private codeMap(code: number, message: string, operator?: string): Map<string, Object> {
    const result: Map<string, Object> = new Map<string, Object>();
    result.set('code', code);
    result.set('message', message);
    if (operator !== undefined) {
      result.set('operator', operator);
    }
    return result;
  }

  private invokeFlutter(method: string, argumentsMap: Map<string, Object>): void {
    if (this.channel !== null) {
      this.channel.invokeMethod(method, argumentsMap);
    }
  }
}
