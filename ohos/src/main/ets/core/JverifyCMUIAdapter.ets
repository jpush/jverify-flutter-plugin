import window from '@ohos.window';
import { LengthMetrics } from '@ohos.arkui.node';
import {
  GenAuthThemeConfigBuilder,
  JVerificationInterface,
  SpanEntity,
} from '@jg/verify';
import { JverifyLog } from './JverifyLog';
import {
  buildHarmonyCMLoginPage,
  configureHarmonyCMLoginPage,
  JverifyCMAuthLoginListener,
  JverifyCMLoginPageStyle,
  JverifyCMLoginPageWidgetStyle,
} from './JverifyHarmonyViews';

interface JverifyGenBackPressedCallBack {
  obj: Object;
  onBackPressedCallBack: (accepted: boolean) => void;
}

interface JverifyLoginDialogOptions {
  width?: Length;
  height?: Length;
  alignment?: DialogAlignment;
  offset?: Offset;
  showInSubWindow?: boolean;
  isModal?: boolean;
  autoCancel?: boolean;
  maskColor?: ResourceColor;
}

interface JverifyHorizontalRuleItem {
  anchor: string;
  align: HorizontalAlign;
}

interface JverifyVerticalRuleItem {
  anchor: string;
  align: VerticalAlign;
}

export interface PrivacyItemConfig {
  name?: string;
  url?: string;
  separator?: string;
}

/** Maps China-Mobile-only Flutter UI values to GenAuthThemeConfigBuilder. */
export class JverifyCMUIAdapter {
  static apply(config: Map<string, Object>, privacyItems: Array<PrivacyItemConfig>,
    onBackPressed?: () => void, onWidgetClick?: (id: string) => void,
    onDismiss?: () => void, onToast?: (message: string) => void,
    resolveMedia?: (name: string) => string): GenAuthThemeConfigBuilder {
    const builder: GenAuthThemeConfigBuilder = new GenAuthThemeConfigBuilder();

    JverifyCMUIAdapter.applyNavigation(config, builder);
    JverifyCMUIAdapter.applyNumber(config, builder);
    JverifyCMUIAdapter.applyLoginButton(config, builder);
    JverifyCMUIAdapter.applyPrivacy(config, privacyItems, builder);
    JverifyCMUIAdapter.applyAnimation(config, builder);
    JverifyCMUIAdapter.applySpecificConfig(config, builder, onWidgetClick, onDismiss, onToast, resolveMedia);
    JverifyCMUIAdapter.applyWindowFallback(config, builder);

    const privacyReturnPath: string | undefined = JverifyCMUIAdapter.stringValue(config,
      'privacyNavReturnBtnImage');
    if (privacyReturnPath !== undefined) {
      const resolvedPrivacyReturnPath: string = resolveMedia === undefined ? privacyReturnPath :
        resolveMedia(privacyReturnPath);
      builder.setWebCloseImgPath(resolvedPrivacyReturnPath.length > 0 ?
        resolvedPrivacyReturnPath : privacyReturnPath);
    }

    if (JverifyCMUIAdapter.booleanValue(config, 'authPageBackPressedListener') === true &&
      onBackPressed !== undefined) {
      builder.setGenBackPressedListener({
        onBackPressed: (callBack: JverifyGenBackPressedCallBack): void => {
          onBackPressed();
          callBack.onBackPressedCallBack(true);
        },
      });
    }
    return builder;
  }

  private static applyNavigation(config: Map<string, Object>, builder: GenAuthThemeConfigBuilder): void {
    const language: string | undefined = JverifyCMUIAdapter.stringValue(config, 'appLanguageType');
    if (language !== undefined) {
      const languageType: number = Number(language);
      if (Number.isInteger(languageType) && languageType >= 0 && languageType <= 2) {
        builder.setLanguageType(languageType);
      } else {
        JverifyLog.warn('appLanguageType ignored for China Mobile: expected 0, 1 or 2');
      }
    }
    const navColor: number | undefined = JverifyCMUIAdapter.numberValue(config, 'navColor');
    if (navColor !== undefined) {
      builder.setNavColor(navColor);
    }
    const navTextColor: number | undefined = JverifyCMUIAdapter.numberValue(config, 'navTextColor');
    if (navTextColor !== undefined) {
      builder.setNavTextColor(navTextColor);
    }
  }

  private static applyNumber(config: Map<string, Object>, builder: GenAuthThemeConfigBuilder): void {
    const cmConfig: Map<string, Object> | undefined = JverifyCMUIAdapter.mapValue(config, 'harmonyCmUIConfig');
    const numberSize: number | undefined = JverifyCMUIAdapter.numberValue(config, 'numberSize');
    const numberBold: boolean = JverifyCMUIAdapter.booleanValue(config, 'numberTextBold') ?? false;
    if (numberSize !== undefined) {
      builder.setNumberSize(numberSize, numberBold);
    }
    const numberColor: number | undefined = JverifyCMUIAdapter.numberValue(config, 'numberColor');
    if (numberColor !== undefined) {
      builder.setNumberColor(numberColor);
    }
    const numberWidth: number | undefined = cmConfig === undefined ?
      JverifyCMUIAdapter.numberValue(config, 'numberFieldWidth') :
      (JverifyCMUIAdapter.numberValue(cmConfig, 'numberWidth') ??
        JverifyCMUIAdapter.numberValue(config, 'numberFieldWidth'));
    if (numberWidth !== undefined) {
      builder.setNumberWidth(numberWidth);
    }
    const numberHeight: number | undefined = cmConfig === undefined ?
      JverifyCMUIAdapter.numberValue(config, 'numberFieldHeight') :
      (JverifyCMUIAdapter.numberValue(cmConfig, 'numberHeight') ??
        JverifyCMUIAdapter.numberValue(config, 'numberFieldHeight'));
    if (numberHeight !== undefined) {
      builder.setNumberHeight(numberHeight);
    }
    const explicitMargin: Margin | undefined = cmConfig === undefined ? undefined :
      JverifyCMUIAdapter.marginValue(cmConfig, 'numberMargin');
    if (explicitMargin !== undefined) {
      builder.setNumberMargin(explicitMargin);
    } else {
      const x: number | undefined = JverifyCMUIAdapter.numberValue(config, 'numFieldOffsetX');
      const y: number | undefined = JverifyCMUIAdapter.numberValue(config, 'numFieldOffsetY');
      const margin: Margin | undefined = JverifyCMUIAdapter.xyMargin(x, y);
      if (margin !== undefined) {
        builder.setNumberMargin(margin);
      }
    }
  }

  private static applyLoginButton(config: Map<string, Object>, builder: GenAuthThemeConfigBuilder): void {
    const text: string | undefined = JverifyCMUIAdapter.stringValue(config, 'logBtnText');
    if (text !== undefined) {
      builder.setLogBtnText(text);
    }
    const textSize: number | undefined = JverifyCMUIAdapter.numberValue(config, 'logBtnTextSize');
    if (textSize !== undefined) {
      builder.setLoginBtnTextSize(textSize);
    }
    const textColor: number | undefined = JverifyCMUIAdapter.numberValue(config, 'logBtnTextColor');
    if (textColor !== undefined) {
      builder.setLoginBtnTextColor(textColor);
    }
    const backgroundColor: number | undefined =
      JverifyCMUIAdapter.numberValue(config, 'harmonyLogBtnBackgroundColor');
    if (backgroundColor !== undefined) {
      builder.setLoginBtnColor(backgroundColor);
    }
    const borderRadius: number | undefined =
      JverifyCMUIAdapter.numberValue(config, 'harmonyLogBtnBorderRadius');
    if (borderRadius !== undefined) {
      builder.setLoginBtnBorderRadius(borderRadius);
    }
    const imagePath: string | undefined = JverifyCMUIAdapter.stringValue(config, 'logBtnBackgroundPath');
    if (imagePath !== undefined) {
      builder.setLoginBtnImgPath(imagePath);
    }
    const width: number | undefined = JverifyCMUIAdapter.numberValue(config, 'logBtnWidth');
    if (width !== undefined) {
      builder.setLoginBtnWidth(width);
    }
    const height: number | undefined = JverifyCMUIAdapter.numberValue(config, 'logBtnHeight');
    if (height !== undefined) {
      builder.setLoginBtnHeight(height);
    }

    const cmConfig: Map<string, Object> | undefined = JverifyCMUIAdapter.mapValue(config, 'harmonyCmUIConfig');
    const explicitMargin: Margin | undefined = cmConfig === undefined ? undefined :
      JverifyCMUIAdapter.marginValue(cmConfig, 'loginBtnMargin');
    if (explicitMargin !== undefined) {
      builder.setLoginBtnMargin(explicitMargin);
    } else if (cmConfig === undefined) {
      // Generic offsets are a compatibility fallback only when no dedicated
      // China Mobile config exists. CM margins use independent relative-layout
      // semantics, so applying a generic Column gap can move the button into
      // the system/navigation area.
      const x: number | undefined = JverifyCMUIAdapter.numberValue(config, 'logBtnOffsetX');
      const y: number | undefined = JverifyCMUIAdapter.numberValue(config, 'logBtnOffsetY');
      const margin: Margin | undefined = JverifyCMUIAdapter.xyMargin(x, y);
      if (margin !== undefined) {
        builder.setLoginBtnMargin(margin);
      }
    }
  }

  private static applyPrivacy(config: Map<string, Object>, privacyItems: Array<PrivacyItemConfig>,
    builder: GenAuthThemeConfigBuilder): void {
    const cmConfig: Map<string, Object> | undefined = JverifyCMUIAdapter.mapValue(config, 'harmonyCmUIConfig');
    const explicitCheckBoxSize: Map<string, Object> | undefined = cmConfig === undefined ? undefined :
      JverifyCMUIAdapter.mapValue(cmConfig, 'checkBoxSize');
    const checkboxSize: number | undefined = JverifyCMUIAdapter.numberValue(config, 'privacyCheckboxSize');
    if (explicitCheckBoxSize !== undefined) {
      const width: number | undefined = JverifyCMUIAdapter.numberValue(explicitCheckBoxSize, 'width');
      const height: number | undefined = JverifyCMUIAdapter.numberValue(explicitCheckBoxSize, 'height');
      if (width !== undefined && height !== undefined) {
        builder.setCheckBox(width, height);
      }
    } else if (checkboxSize !== undefined) {
      builder.setCheckBox(checkboxSize, checkboxSize);
    }
    const checkedPath: string | undefined = JverifyCMUIAdapter.stringValue(config, 'checkedImgPath');
    const uncheckedPath: string | undefined = JverifyCMUIAdapter.stringValue(config, 'uncheckedImgPath');
    if (checkedPath !== undefined && uncheckedPath !== undefined) {
      builder.setCheckBoxImg(checkedPath, uncheckedPath);
    }
    const state: boolean | undefined = JverifyCMUIAdapter.booleanValue(config, 'privacyState');
    if (state !== undefined) {
      builder.setClauseState(state);
    }
    const hintText: string | undefined = JverifyCMUIAdapter.stringValue(config, 'harmonyPrivacyHintToastText');
    if (hintText !== undefined) {
      builder.setCheckTipText(hintText);
    }
    const privacySize: number | undefined = JverifyCMUIAdapter.numberValue(config, 'privacyTextSize');
    if (privacySize !== undefined) {
      builder.setprivacyTextSize(privacySize);
    }
    const privacyBold: boolean | undefined = JverifyCMUIAdapter.booleanValue(config, 'privacyTextBold');
    if (privacyBold !== undefined) {
      builder.setPrivacyTextBold(privacyBold);
    }
    const baseColor: number | undefined = JverifyCMUIAdapter.numberValue(config, 'clauseBaseColor');
    if (baseColor !== undefined) {
      builder.setclauseBaseColor(baseColor);
    }
    const clauseColor: number | undefined = JverifyCMUIAdapter.numberValue(config, 'clauseColor');
    if (clauseColor !== undefined) {
      builder.setclauseColor(clauseColor);
    }
    const privacyCenter: boolean | undefined =
      JverifyCMUIAdapter.booleanValue(config, 'privacyTextCenterGravity');
    if (privacyCenter !== undefined) {
      builder.setisPrivacyTextGravityCenter(privacyCenter);
    }
    const bookSymbol: boolean | undefined = JverifyCMUIAdapter.booleanValue(config, 'privacyWithBookTitleMark');
    if (bookSymbol !== undefined) {
      builder.setprivacyBookSymbol(bookSymbol);
    }

    const explicitMargin: Margin | undefined = cmConfig === undefined ? undefined :
      JverifyCMUIAdapter.marginValue(cmConfig, 'clauseMargin');
    const explicitAlignRule: Map<string, Object> | undefined = cmConfig === undefined ? undefined :
      JverifyCMUIAdapter.mapValue(cmConfig, 'clauseAlignRule');
    if (explicitMargin !== undefined) {
      builder.setClauseMargin(explicitMargin);
    } else if (explicitAlignRule === undefined) {
      // A CM RelativeContainer rule defines the clause position relative to
      // clause_checkBox. Do not reapply the generic platform offset after the
      // alignment, otherwise the text and checkbox are pulled onto two rows.
      const left: number | undefined = JverifyCMUIAdapter.numberValue(config, 'privacyOffsetX');
      const right: number | undefined = JverifyCMUIAdapter.numberValue(config, 'privacyMarginR');
      const top: number | undefined = JverifyCMUIAdapter.numberValue(config, 'privacyTopOffsetY');
      const bottom: number | undefined = JverifyCMUIAdapter.numberValue(config, 'privacyOffsetY');
      if (left !== undefined || right !== undefined || top !== undefined || bottom !== undefined) {
        builder.setClauseMargin({
          left: left ?? 0,
          right: right ?? 0,
          top: top ?? 0,
          bottom: bottom ?? 0,
        });
      }
    }

    const explicitCheckBoxMargin: Margin | undefined = cmConfig === undefined ? undefined :
      JverifyCMUIAdapter.marginValue(cmConfig, 'checkBoxMargin');
    if (explicitCheckBoxMargin !== undefined) {
      builder.setCheckBoxMargin(explicitCheckBoxMargin);
    } else {
      const checkX: number | undefined = JverifyCMUIAdapter.numberValue(config, 'privacyCheckboxOffsetX');
      const checkY: number | undefined = JverifyCMUIAdapter.numberValue(config, 'privacyCheckboxOffsetY');
      const checkMargin: Margin | undefined = JverifyCMUIAdapter.xyMargin(checkX, checkY);
      if (checkMargin !== undefined) {
        builder.setCheckBoxMargin(checkMargin);
      }
    }
    builder.setClauses(JverifyCMUIAdapter.buildClauses(config, privacyItems));
  }

  private static applyAnimation(config: Map<string, Object>, builder: GenAuthThemeConfigBuilder): void {
    const enterAnimation: string | undefined = JverifyCMUIAdapter.stringValue(config, 'enterAnim');
    if (enterAnimation !== undefined) {
      builder.setauthPageActIn(enterAnimation);
    }
    const exitAnimation: string | undefined = JverifyCMUIAdapter.stringValue(config, 'exitAnim');
    if (exitAnimation !== undefined) {
      builder.setauthPageActOut(exitAnimation);
    }
  }

  private static applySpecificConfig(config: Map<string, Object>, builder: GenAuthThemeConfigBuilder,
    onWidgetClick?: (id: string) => void, onDismiss?: () => void,
    onToast?: (message: string) => void, resolveMedia?: (name: string) => string): void {
    const cmConfig: Map<string, Object> | undefined = JverifyCMUIAdapter.mapValue(config, 'harmonyCmUIConfig');
    if (cmConfig === undefined) {
      return;
    }

    const systemBar: Map<string, Object> | undefined = JverifyCMUIAdapter.mapValue(cmConfig, 'systemBar');
    if (systemBar !== undefined) {
      const properties: window.SystemBarProperties = {};
      properties.statusBarColor = JverifyCMUIAdapter.stringValue(systemBar, 'statusBarColor');
      properties.isStatusBarLightIcon = JverifyCMUIAdapter.booleanValue(systemBar, 'isStatusBarLightIcon');
      properties.statusBarContentColor = JverifyCMUIAdapter.stringValue(systemBar, 'statusBarContentColor');
      properties.navigationBarColor = JverifyCMUIAdapter.stringValue(systemBar, 'navigationBarColor');
      properties.isNavigationBarLightIcon =
        JverifyCMUIAdapter.booleanValue(systemBar, 'isNavigationBarLightIcon');
      properties.navigationBarContentColor =
        JverifyCMUIAdapter.stringValue(systemBar, 'navigationBarContentColor');
      properties.enableStatusBarAnimation =
        JverifyCMUIAdapter.booleanValue(systemBar, 'enableStatusBarAnimation');
      properties.enableNavigationBarAnimation =
        JverifyCMUIAdapter.booleanValue(systemBar, 'enableNavigationBarAnimation');
      builder.setSystemBarProperties(properties);
    }

    const grayScale: number | undefined = JverifyCMUIAdapter.numberValue(cmConfig, 'authPageGrayScale');
    if (grayScale !== undefined) {
      if (grayScale >= 0 && grayScale <= 1) {
        builder.setAuthPageGrayScale(grayScale);
      } else {
        JverifyLog.warn('harmonyCmUIConfig.authPageGrayScale ignored: expected 0...1');
      }
    }
    const navTextSize: number | undefined = JverifyCMUIAdapter.numberValue(cmConfig, 'navTextSize');
    if (navTextSize !== undefined) {
      builder.setNavTextSize(navTextSize);
    }
    const clauseLineSpacing: number | undefined =
      JverifyCMUIAdapter.numberValue(cmConfig, 'clauseLineSpacing');
    if (clauseLineSpacing !== undefined) {
      builder.setClauseLineSpacing(LengthMetrics.vp(clauseLineSpacing));
    }

    const checkBoxLocation: number | undefined = JverifyCMUIAdapter.numberValue(cmConfig, 'checkBoxLocation');
    if (checkBoxLocation !== undefined) {
      builder.setcheckBoxLocation(checkBoxLocation);
    }
    const privacyMarginRight: number | undefined =
      JverifyCMUIAdapter.numberValue(cmConfig, 'privacyMarginRight');
    if (privacyMarginRight !== undefined) {
      builder.setprivacyMarginRight(privacyMarginRight);
    }
    const privacyOffsetY: number | undefined = JverifyCMUIAdapter.numberValue(cmConfig, 'privacyOffsetY');
    if (privacyOffsetY !== undefined) {
      builder.setprivacyOffsetY(privacyOffsetY);
    }
    const privacyOffsetYB: number | undefined = JverifyCMUIAdapter.numberValue(cmConfig, 'privacyOffsetYB');
    if (privacyOffsetYB !== undefined) {
      builder.setprivacyOffsetYB(privacyOffsetYB);
    }
    const activityIn: string | undefined = JverifyCMUIAdapter.stringValue(cmConfig, 'activityIn');
    if (activityIn !== undefined) {
      builder.setactivityIn(activityIn);
    }
    const activityOut: string | undefined = JverifyCMUIAdapter.stringValue(cmConfig, 'activityOut');
    if (activityOut !== undefined) {
      builder.setactivityOut(activityOut);
    }
    JverifyCMUIAdapter.applyNumberProperty(cmConfig, 'windowWidth',
      (value: number): void => { builder.setWindowWidth(value); });
    JverifyCMUIAdapter.applyNumberProperty(cmConfig, 'windowHeight',
      (value: number): void => { builder.setWindowHeight(value); });
    JverifyCMUIAdapter.applyNumberProperty(cmConfig, 'windowX',
      (value: number): void => { builder.setwindowX(value); });
    JverifyCMUIAdapter.applyNumberProperty(cmConfig, 'windowY',
      (value: number): void => { builder.setwindowY(value); });
    JverifyCMUIAdapter.applyNumberProperty(cmConfig, 'windowBottom',
      (value: number): void => { builder.setwindowBottom(value); });
    JverifyCMUIAdapter.applyNumberProperty(cmConfig, 'themeId',
      (value: number): void => { builder.setthemeId(value); });
    const fitsSystemWindows: boolean | undefined =
      JverifyCMUIAdapter.booleanValue(cmConfig, 'fitsSystemWindows');
    if (fitsSystemWindows !== undefined) {
      builder.setisFitsSystemWindows(fitsSystemWindows);
    }

    // setClauses rebuilds the SDK's clause nodes and resets their relative
    // layout state. Match the official demo order: create clauses first, then
    // apply AlignRuleOptions against clause_text/clause_checkBox.
    JverifyCMUIAdapter.applyClauses(cmConfig, builder);
    const rebuiltClauseMargin: Margin | undefined =
      JverifyCMUIAdapter.marginValue(cmConfig, 'clauseMargin');
    if (rebuiltClauseMargin !== undefined) {
      builder.setClauseMargin(rebuiltClauseMargin);
    }

    JverifyCMUIAdapter.applyAlignRule(cmConfig, 'numberAlignRule',
      (rule: AlignRuleOption): void => {
        builder.setNumberAlignRuleOption(rule);
      });
    JverifyCMUIAdapter.applyAlignRule(cmConfig, 'loginBtnAlignRule',
      (rule: AlignRuleOption): void => {
        builder.setLoginBtnAlignRuleOption(rule);
      });
    JverifyCMUIAdapter.applyAlignRule(cmConfig, 'checkBoxAlignRule',
      (rule: AlignRuleOption): void => {
        builder.setCheckBoxAlignRuleOption(rule);
      });
    JverifyCMUIAdapter.applyAlignRule(cmConfig, 'clauseAlignRule',
      (rule: AlignRuleOption): void => {
        builder.setClauseAlignRuleOption(rule);
      });
    JverifyCMUIAdapter.applyAlignRule(cmConfig, 'webCloseImgAlignRule',
      (rule: AlignRuleOption): void => {
        builder.setWebCloseImgAlignRuleOption(rule);
      });

    const loginMarginRight: number | undefined =
      JverifyCMUIAdapter.numberValue(cmConfig, 'loginBtnMarginRight');
    if (loginMarginRight !== undefined) {
      builder.setLoginBtnMarginRight(loginMarginRight);
    }
    const loginBorderColor: number | undefined =
      JverifyCMUIAdapter.numberValue(cmConfig, 'loginBtnBorderColor');
    if (loginBorderColor !== undefined) {
      builder.setLoginBtnBorderColor(loginBorderColor);
    }
    const loginBorderWidth: number | undefined =
      JverifyCMUIAdapter.numberValue(cmConfig, 'loginBtnBorderWidth');
    if (loginBorderWidth !== undefined) {
      builder.setLoginBtnBorderWidth(loginBorderWidth);
    }
    const disabledTextColor: number | undefined =
      JverifyCMUIAdapter.numberValue(cmConfig, 'loginBtnDisabledTextColor');
    if (disabledTextColor !== undefined) {
      builder.setLoginBtnDisabledTextColor(disabledTextColor);
    }
    const disabledColor: number | undefined =
      JverifyCMUIAdapter.numberValue(cmConfig, 'loginBtnDisabledColor');
    if (disabledColor !== undefined) {
      builder.setLoginBtnDisabledColor(disabledColor);
    }
    const disabledImage: string | undefined =
      JverifyCMUIAdapter.stringValue(cmConfig, 'loginBtnDisabledImgPath');
    if (disabledImage !== undefined) {
      builder.setLoginBtnDisabledImgPath(disabledImage);
    }
    const disabledBorderColor: number | undefined =
      JverifyCMUIAdapter.numberValue(cmConfig, 'loginBtnDisabledBorderColor');
    if (disabledBorderColor !== undefined) {
      builder.setLoginBtnDisabledBorderColor(disabledBorderColor);
    }
    const disabledBorderWidth: number | undefined =
      JverifyCMUIAdapter.numberValue(cmConfig, 'loginBtnDisabledBorderWidth');
    if (disabledBorderWidth !== undefined) {
      builder.setLoginBtnDisabledBorderWidth(disabledBorderWidth);
    }

    const checkedColor: number | undefined = JverifyCMUIAdapter.numberValue(cmConfig, 'checkedColor');
    if (checkedColor !== undefined) {
      builder.setCheckedColor(checkedColor);
    }
    const checkBoxShape: string | undefined = JverifyCMUIAdapter.stringValue(cmConfig, 'checkBoxShape');
    if (checkBoxShape !== undefined) {
      builder.setCheckBoxShape(checkBoxShape === 'circle' ? CheckBoxShape.CIRCLE : CheckBoxShape.ROUNDED_SQUARE);
    }
    const clauseTextAlign: string | undefined = JverifyCMUIAdapter.stringValue(cmConfig, 'clauseTextAlign');
    if (clauseTextAlign !== undefined) {
      builder.setClauseTextAlign(JverifyCMUIAdapter.textAlign(clauseTextAlign));
    }
    const clauseNavMarginTop: number | undefined =
      JverifyCMUIAdapter.numberValue(cmConfig, 'clauseNavMarginTop');
    if (clauseNavMarginTop !== undefined) {
      if (clauseNavMarginTop >= 0 && clauseNavMarginTop <= 99) {
        builder.setClauseNavMarginTop(clauseNavMarginTop);
      } else {
        JverifyLog.warn('harmonyCmUIConfig.clauseNavMarginTop ignored: expected 0...99');
      }
    }
    const webDomStorage: boolean | undefined =
      JverifyCMUIAdapter.booleanValue(cmConfig, 'webDomStorageEnabled');
    if (webDomStorage !== undefined) {
      builder.setWebDomStorage(webDomStorage);
    }
    const webCloseWidth: number | undefined = JverifyCMUIAdapter.numberValue(cmConfig, 'webCloseImgWidth');
    if (webCloseWidth !== undefined) {
      builder.setWebCloseImgWidth(webCloseWidth);
    }
    const webCloseHeight: number | undefined = JverifyCMUIAdapter.numberValue(cmConfig, 'webCloseImgHeight');
    if (webCloseHeight !== undefined) {
      builder.setWebCloseImgHeight(webCloseHeight);
    }
    const webCloseMargin: Margin | undefined = JverifyCMUIAdapter.marginValue(cmConfig, 'webCloseImgMargin');
    if (webCloseMargin !== undefined) {
      builder.setWebCloseImgMargin(webCloseMargin);
    }
    JverifyCMUIAdapter.applyDefaultLoginButtonImage(cmConfig, builder, resolveMedia);
    JverifyCMUIAdapter.applyLoginPage(cmConfig, builder, onWidgetClick, onDismiss, onToast, resolveMedia);
    JverifyCMUIAdapter.applyLoginConfirmDialog(cmConfig, builder);
    JverifyCMUIAdapter.applyWindowMode(cmConfig, builder);
  }

  private static applyNumberProperty(config: Map<string, Object>, key: string,
    apply: (value: number) => void): void {
    const value: number | undefined = JverifyCMUIAdapter.numberValue(config, key);
    if (value !== undefined) {
      apply(value);
    }
  }

  private static applyClauses(cmConfig: Map<string, Object>, builder: GenAuthThemeConfigBuilder): void {
    const entries: Array<Object> | undefined = JverifyCMUIAdapter.arrayValue(cmConfig, 'clauses');
    if (entries === undefined || entries.length === 0) {
      return;
    }
    const clauses: Array<SpanEntity> = new Array<SpanEntity>();
    entries.forEach((entry: Object): void => {
      if (!(entry instanceof Map)) {
        return;
      }
      const source: Map<string, Object> = entry as Map<string, Object>;
      const text: string | undefined = JverifyCMUIAdapter.stringValue(source, 'text');
      if (text === undefined) {
        return;
      }
      const span: SpanEntity = new SpanEntity();
      span.text = text;
      span.url = JverifyCMUIAdapter.stringValue(source, 'url');
      span.fontSize = JverifyCMUIAdapter.numberValue(source, 'fontSize') ?? 14;
      span.fontColor = JverifyCMUIAdapter.numberValue(source, 'fontColor') ?? 0xFF64748B;
      span.fontWeight = JverifyCMUIAdapter.booleanValue(source, 'bold') === true
        ? FontWeight.Bold : FontWeight.Normal;
      span.isProtocol = JverifyCMUIAdapter.booleanValue(source, 'isProtocol') ?? false;
      clauses.push(span);
    });
    if (clauses.length > 0) {
      builder.setClauses(clauses);
    }
  }

  private static applyDefaultLoginButtonImage(cmConfig: Map<string, Object>,
    builder: GenAuthThemeConfigBuilder, resolveMedia?: (name: string) => string): void {
    if (JverifyCMUIAdapter.booleanValue(cmConfig, 'useDefaultLoginButtonImage') !== true) {
      return;
    }
    const explicitPath: string | undefined =
      JverifyCMUIAdapter.stringValue(cmConfig, 'defaultLoginButtonImagePath');
    const resolvedPath: string = explicitPath ??
      (resolveMedia === undefined ? 'jverify_login_back' : resolveMedia('jverify_login_back'));
    if (resolvedPath.length > 0) {
      builder.setLoginBtnImgPath(resolvedPath);
      // The CM SDK renders the unchecked-agreement state with its independent
      // disabled style. Keep both states on the same visible resource, as in
      // the official harmony-verify-sdk demo.
      builder.setLoginBtnDisabledImgPath(resolvedPath);
    }
  }

  private static applyLoginPage(cmConfig: Map<string, Object>, builder: GenAuthThemeConfigBuilder,
    onWidgetClick?: (id: string) => void, onDismiss?: () => void,
    onToast?: (message: string) => void, resolveMedia?: (name: string) => string): void {
    const page: Map<string, Object> | undefined = JverifyCMUIAdapter.mapValue(cmConfig, 'loginPage');
    if (page === undefined) {
      return;
    }
    const style: JverifyCMLoginPageStyle = new JverifyCMLoginPageStyle();
    style.showTitle = JverifyCMUIAdapter.booleanValue(page, 'showTitle') ?? false;
    style.title = JverifyCMUIAdapter.stringValue(page, 'title') ?? '极光认证';
    style.titleSize = JverifyCMUIAdapter.numberValue(page, 'titleSize') ?? 24;
    style.titleColor = JverifyCMUIAdapter.numberValue(page, 'titleColor') ?? 0xFF17233D;
    // The CM custom component is layered on top of the SDK page. A missing
    // background must therefore remain transparent instead of painting an
    // opaque full-page Column over the native number/button/protocol views.
    style.backgroundColor = JverifyCMUIAdapter.numberValue(page, 'backgroundColor') ?? 0x00000000;
    const imageSource: string | undefined = JverifyCMUIAdapter.stringValue(page, 'backgroundImageSource');
    const imageName: string | undefined = JverifyCMUIAdapter.stringValue(page, 'backgroundImage');
    if (imageSource !== undefined) {
      style.backgroundImage = imageSource;
    } else if (imageName !== undefined && resolveMedia !== undefined) {
      style.backgroundImage = resolveMedia(imageName);
    }
    const entries: Array<Object> | undefined = JverifyCMUIAdapter.arrayValue(page, 'widgets');
    if (entries !== undefined) {
      entries.forEach((entry: Object, index: number): void => {
        if (!(entry instanceof Map)) {
          return;
        }
        const source: Map<string, Object> = entry as Map<string, Object>;
        const item: JverifyCMLoginPageWidgetStyle = new JverifyCMLoginPageWidgetStyle();
        item.id = JverifyCMUIAdapter.stringValue(source, 'id') ?? 'harmony-cm-widget-' + index;
        item.anchor = JverifyCMUIAdapter.stringValue(source, 'anchor') ?? 'loginBtn';
        item.type = JverifyCMUIAdapter.stringValue(source, 'type') ?? 'button';
        item.text = JverifyCMUIAdapter.stringValue(source, 'text') ?? '';
        item.textSize = JverifyCMUIAdapter.numberValue(source, 'textSize') ?? 16;
        item.textColor = JverifyCMUIAdapter.numberValue(source, 'textColor') ?? 0xFFFFFFFF;
        item.backgroundColor = JverifyCMUIAdapter.numberValue(source, 'backgroundColor') ?? 0xFF359AF3;
        item.width = JverifyCMUIAdapter.numberValue(source, 'width') ?? 180;
        item.height = JverifyCMUIAdapter.numberValue(source, 'height') ?? 44;
        item.borderRadius = JverifyCMUIAdapter.numberValue(source, 'borderRadius') ?? 22;
        const image: Map<string, Object> | undefined = JverifyCMUIAdapter.mapValue(source, 'image');
        if (image !== undefined) {
          const directSource: string | undefined = JverifyCMUIAdapter.stringValue(image, 'source');
          const imageName: string | undefined = JverifyCMUIAdapter.stringValue(image, 'name');
          if (directSource !== undefined) {
            item.imageSource = directSource;
          } else if (imageName !== undefined) {
            item.imageSource = resolveMedia === undefined ? imageName : resolveMedia(imageName);
          }
          item.imageFit = JverifyCMUIAdapter.stringValue(image, 'fit') ?? 'contain';
        }
        const margin: Margin | undefined = JverifyCMUIAdapter.marginValue(source, 'margin');
        if (margin !== undefined) {
          item.marginTop = margin.top as number;
          item.marginRight = margin.right as number;
          item.marginBottom = margin.bottom as number;
          item.marginLeft = margin.left as number;
        }
        item.action = JverifyCMUIAdapter.stringValue(source, 'action') ?? 'callback';
        item.toastText = JverifyCMUIAdapter.stringValue(source, 'toastText') ?? '';
        if (item.type === 'image' && item.imageSource.length === 0) {
          JverifyLog.warn('China Mobile custom image ignored: media source unavailable for id=' + item.id);
          return;
        }
        style.widgets.push(item);
      });
    }
    style.onWidgetClick = (id: string, action: string, toastText: string): void => {
      JverifyLog.info('China Mobile custom login page clicked: id=' + id + ', action=' + action);
      if (id.length > 0 && onWidgetClick !== undefined) {
        onWidgetClick(id);
      }
      if (toastText.length > 0 && onToast !== undefined) {
        onToast(toastText);
      }
      if (action === 'dismissLoginAuth' && onDismiss !== undefined) {
        onDismiss();
      } else if (action === 'closeCheckDialog') {
        JVerificationInterface.closeCheckDialog();
      }
    };
    configureHarmonyCMLoginPage(style);
    builder.setLoginPageComponent(buildHarmonyCMLoginPage);
  }

  private static applyLoginConfirmDialog(cmConfig: Map<string, Object>,
    builder: GenAuthThemeConfigBuilder): void {
    const dialog: Map<string, Object> | undefined =
      JverifyCMUIAdapter.mapValue(cmConfig, 'loginConfirmDialog');
    if (dialog === undefined) {
      return;
    }
    builder.setGenAuthLoginListener(new JverifyCMAuthLoginListener(
      JverifyCMUIAdapter.stringValue(dialog, 'message') ?? '是否登录授权',
      JverifyCMUIAdapter.stringValue(dialog, 'confirmText') ?? '确定',
      JverifyCMUIAdapter.stringValue(dialog, 'cancelText') ?? '取消',
      JverifyCMUIAdapter.stringValue(dialog, 'confirmColor') ?? '#000000',
      JverifyCMUIAdapter.stringValue(dialog, 'cancelColor') ?? '#000000'));
  }

  private static applyWindowFallback(config: Map<string, Object>, builder: GenAuthThemeConfigBuilder): void {
    const cmConfig: Map<string, Object> | undefined = JverifyCMUIAdapter.mapValue(config, 'harmonyCmUIConfig');
    if (cmConfig !== undefined) {
      if (JverifyCMUIAdapter.mapValue(cmConfig, 'windowMode') !== undefined ||
        JverifyCMUIAdapter.numberValue(cmConfig, 'windowWidth') !== undefined ||
        JverifyCMUIAdapter.numberValue(cmConfig, 'windowHeight') !== undefined ||
        JverifyCMUIAdapter.numberValue(cmConfig, 'windowX') !== undefined ||
        JverifyCMUIAdapter.numberValue(cmConfig, 'windowY') !== undefined ||
        JverifyCMUIAdapter.numberValue(cmConfig, 'windowBottom') !== undefined) {
        return;
      }
    }
    const popConfig: Map<string, Object> | undefined = JverifyCMUIAdapter.mapValue(config, 'popViewConfig');
    if (popConfig === undefined || JverifyCMUIAdapter.booleanValue(popConfig, 'isPopViewTheme') === false) {
      return;
    }
    const width: number | undefined = JverifyCMUIAdapter.numberValue(popConfig, 'width');
    const height: number | undefined = JverifyCMUIAdapter.numberValue(popConfig, 'height');
    if (width === undefined || height === undefined) {
      JverifyLog.warn('China Mobile popViewConfig requires both width and height');
      return;
    }
    const isBottom: boolean = JverifyCMUIAdapter.booleanValue(popConfig, 'isBottom') ?? false;
    const options: JverifyLoginDialogOptions = {
      width: width,
      height: height,
      alignment: isBottom ? DialogAlignment.Bottom : DialogAlignment.Center,
      offset: {
        dx: JverifyCMUIAdapter.numberValue(popConfig, 'offsetCenterX') ?? 0,
        dy: isBottom ? 0 : (JverifyCMUIAdapter.numberValue(popConfig, 'offsetCenterY') ?? 0),
      },
    };
    builder.setWindowMode(options);
  }

  private static applyWindowMode(cmConfig: Map<string, Object>, builder: GenAuthThemeConfigBuilder): void {
    const windowMode: Map<string, Object> | undefined = JverifyCMUIAdapter.mapValue(cmConfig, 'windowMode');
    if (windowMode === undefined) {
      return;
    }
    const width: Length | undefined = JverifyCMUIAdapter.lengthValue(windowMode, 'width');
    const height: Length | undefined = JverifyCMUIAdapter.lengthValue(windowMode, 'height');
    if (width === undefined || height === undefined) {
      JverifyLog.warn('harmonyCmUIConfig.windowMode ignored: width and height are required');
      return;
    }
    const options: JverifyLoginDialogOptions = {
      width: width,
      height: height,
      alignment: JverifyCMUIAdapter.dialogAlignment(
        JverifyCMUIAdapter.stringValue(windowMode, 'alignment') ?? 'center'),
      offset: {
        dx: JverifyCMUIAdapter.numberValue(windowMode, 'offsetX') ?? 0,
        dy: JverifyCMUIAdapter.numberValue(windowMode, 'offsetY') ?? 0,
      },
      showInSubWindow: JverifyCMUIAdapter.booleanValue(windowMode, 'showInSubWindow') ?? false,
      isModal: JverifyCMUIAdapter.booleanValue(windowMode, 'isModal') ?? true,
      autoCancel: JverifyCMUIAdapter.booleanValue(windowMode, 'autoCancel') ?? true,
      maskColor: JverifyCMUIAdapter.numberValue(windowMode, 'maskColor') ?? 0x33000000,
    };
    builder.setWindowMode(options);
  }

  private static applyAlignRule(config: Map<string, Object>, key: string,
    apply: (rule: AlignRuleOption) => void): void {
    const value: Map<string, Object> | undefined = JverifyCMUIAdapter.mapValue(config, key);
    if (value === undefined) {
      return;
    }
    const rule: AlignRuleOption = {};
    JverifyCMUIAdapter.setHorizontalRule(value, 'left',
      (item: JverifyHorizontalRuleItem): void => {
        rule.left = item;
      });
    JverifyCMUIAdapter.setHorizontalRule(value, 'right',
      (item: JverifyHorizontalRuleItem): void => {
        rule.right = item;
      });
    JverifyCMUIAdapter.setHorizontalRule(value, 'middle',
      (item: JverifyHorizontalRuleItem): void => {
        rule.middle = item;
      });
    JverifyCMUIAdapter.setVerticalRule(value, 'top',
      (item: JverifyVerticalRuleItem): void => {
        rule.top = item;
      });
    JverifyCMUIAdapter.setVerticalRule(value, 'bottom',
      (item: JverifyVerticalRuleItem): void => {
        rule.bottom = item;
      });
    JverifyCMUIAdapter.setVerticalRule(value, 'center',
      (item: JverifyVerticalRuleItem): void => {
        rule.center = item;
      });
    apply(rule);
  }

  private static setHorizontalRule(config: Map<string, Object>, key: string,
    apply: (item: JverifyHorizontalRuleItem) => void): void {
    const item: Map<string, Object> | undefined = JverifyCMUIAdapter.mapValue(config, key);
    if (item === undefined) {
      return;
    }
    const anchor: string | undefined = JverifyCMUIAdapter.stringValue(item, 'anchor');
    const align: string | undefined = JverifyCMUIAdapter.stringValue(item, 'align');
    if (anchor !== undefined && align !== undefined) {
      const ruleItem: JverifyHorizontalRuleItem = {
        anchor: anchor,
        align: JverifyCMUIAdapter.horizontalAlign(align),
      };
      apply(ruleItem);
    }
  }

  private static setVerticalRule(config: Map<string, Object>, key: string,
    apply: (item: JverifyVerticalRuleItem) => void): void {
    const item: Map<string, Object> | undefined = JverifyCMUIAdapter.mapValue(config, key);
    if (item === undefined) {
      return;
    }
    const anchor: string | undefined = JverifyCMUIAdapter.stringValue(item, 'anchor');
    const align: string | undefined = JverifyCMUIAdapter.stringValue(item, 'align');
    if (anchor !== undefined && align !== undefined) {
      const ruleItem: JverifyVerticalRuleItem = {
        anchor: anchor,
        align: JverifyCMUIAdapter.verticalAlign(align),
      };
      apply(ruleItem);
    }
  }

  private static buildClauses(config: Map<string, Object>,
    privacyItems: Array<PrivacyItemConfig>): Array<SpanEntity> {
    const spans: Array<SpanEntity> = new Array<SpanEntity>();
    const privacyText: Array<string> | undefined = JverifyCMUIAdapter.stringListValue(config, 'privacyText');
    const start: string = JverifyCMUIAdapter.stringValue(config, 'harmonyPrivacyClauseStart') ??
      (privacyText !== undefined && privacyText.length > 0 ? privacyText[0] : '登录即同意');
    const end: string = JverifyCMUIAdapter.stringValue(config, 'harmonyPrivacyClauseEnd') ??
      (privacyText !== undefined && privacyText.length > 1 ? privacyText[1] : '，并使用本机号码登录');
    const size: number = JverifyCMUIAdapter.numberValue(config, 'privacyTextSize') ?? 11;
    const baseColor: number = JverifyCMUIAdapter.numberValue(config, 'clauseBaseColor') ?? 0xFF808080;
    const clauseColor: number = JverifyCMUIAdapter.numberValue(config, 'clauseColor') ?? 0x00359AF3;

    spans.push(JverifyCMUIAdapter.span(start, undefined, size, baseColor, false));
    spans.push(JverifyCMUIAdapter.span('《&&Clause&&》', undefined, size, clauseColor, true));
    if (privacyItems.length > 0) {
      privacyItems.forEach((item: PrivacyItemConfig): void => {
        if (item.separator !== undefined && item.separator.length > 0) {
          spans.push(JverifyCMUIAdapter.span(item.separator, undefined, size, baseColor, false));
        }
        spans.push(JverifyCMUIAdapter.span(item.name as string, item.url, size, clauseColor, true));
      });
    } else {
      JverifyCMUIAdapter.appendPrivacySpan(spans, config, 'clauseName', 'clauseUrl', size, clauseColor);
      JverifyCMUIAdapter.appendPrivacySpan(spans, config, 'clauseNameTwo', 'clauseUrlTwo', size, clauseColor);
    }
    spans.push(JverifyCMUIAdapter.span(end, undefined, size, baseColor, false));
    return spans;
  }

  private static appendPrivacySpan(spans: Array<SpanEntity>, config: Map<string, Object>,
    nameKey: string, urlKey: string, size: number, color: number): void {
    const name: string | undefined = JverifyCMUIAdapter.stringValue(config, nameKey);
    const url: string | undefined = JverifyCMUIAdapter.stringValue(config, urlKey);
    if (name !== undefined && url !== undefined) {
      spans.push(JverifyCMUIAdapter.span(name, url, size, color, true));
    }
  }

  private static span(text: string, url: string | undefined, size: number,
    color: number, isProtocol: boolean): SpanEntity {
    const span: SpanEntity = new SpanEntity();
    span.text = text;
    span.url = url;
    span.isProtocol = isProtocol;
    span.fontSize = size;
    span.fontColor = color;
    return span;
  }

  private static xyMargin(x?: number, y?: number): Margin | undefined {
    if (x !== undefined && x >= 0 && y !== undefined) {
      return { left: x, top: y };
    }
    if (x !== undefined && x >= 0) {
      return { left: x };
    }
    if (y !== undefined) {
      return { top: y };
    }
    return undefined;
  }

  private static marginValue(config: Map<string, Object>, key: string): Margin | undefined {
    const value: Map<string, Object> | undefined = JverifyCMUIAdapter.mapValue(config, key);
    if (value === undefined) {
      return undefined;
    }
    return {
      left: JverifyCMUIAdapter.numberValue(value, 'left') ?? 0,
      right: JverifyCMUIAdapter.numberValue(value, 'right') ?? 0,
      top: JverifyCMUIAdapter.numberValue(value, 'top') ?? 0,
      bottom: JverifyCMUIAdapter.numberValue(value, 'bottom') ?? 0,
    };
  }

  private static horizontalAlign(value: string): HorizontalAlign {
    switch (value) {
      case 'end':
        return HorizontalAlign.End;
      case 'center':
        return HorizontalAlign.Center;
      default:
        return HorizontalAlign.Start;
    }
  }

  private static verticalAlign(value: string): VerticalAlign {
    switch (value) {
      case 'bottom':
        return VerticalAlign.Bottom;
      case 'center':
        return VerticalAlign.Center;
      default:
        return VerticalAlign.Top;
    }
  }

  private static textAlign(value: string): TextAlign {
    switch (value) {
      case 'end':
        return TextAlign.End;
      case 'center':
        return TextAlign.Center;
      default:
        return TextAlign.Start;
    }
  }

  private static dialogAlignment(value: string): DialogAlignment {
    switch (value) {
      case 'top': return DialogAlignment.Top;
      case 'bottom': return DialogAlignment.Bottom;
      case 'topStart': return DialogAlignment.TopStart;
      case 'topEnd': return DialogAlignment.TopEnd;
      case 'centerStart': return DialogAlignment.CenterStart;
      case 'centerEnd': return DialogAlignment.CenterEnd;
      case 'bottomStart': return DialogAlignment.BottomStart;
      case 'bottomEnd': return DialogAlignment.BottomEnd;
      default: return DialogAlignment.Center;
    }
  }

  private static mapValue(map: Map<string, Object>, key: string): Map<string, Object> | undefined {
    const value: Object | null | undefined = map.get(key);
    return value instanceof Map ? value as Map<string, Object> : undefined;
  }

  private static stringValue(map: Map<string, Object>, key: string): string | undefined {
    const value: Object | null | undefined = map.get(key);
    return typeof value === 'string' ? value : undefined;
  }

  private static numberValue(map: Map<string, Object>, key: string): number | undefined {
    const value: Object | null | undefined = map.get(key);
    return typeof value === 'number' ? value : undefined;
  }

  private static booleanValue(map: Map<string, Object>, key: string): boolean | undefined {
    const value: Object | null | undefined = map.get(key);
    return typeof value === 'boolean' ? value : undefined;
  }

  private static lengthValue(map: Map<string, Object>, key: string): Length | undefined {
    const value: Object | null | undefined = map.get(key);
    if (typeof value === 'number' || typeof value === 'string') {
      return value;
    }
    return undefined;
  }

  private static arrayValue(map: Map<string, Object>, key: string): Array<Object> | undefined {
    const value: Object | null | undefined = map.get(key);
    return value instanceof Array ? value as Array<Object> : undefined;
  }

  private static stringListValue(map: Map<string, Object>, key: string): Array<string> | undefined {
    const value: Object | null | undefined = map.get(key);
    if (!(value instanceof Array)) {
      return undefined;
    }
    const values: Array<string> = new Array<string>();
    (value as Array<Object>).forEach((item: Object): void => {
      if (typeof item === 'string') {
        values.push(item);
      }
    });
    return values;
  }
}
