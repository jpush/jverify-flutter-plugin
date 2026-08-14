import { MethodCall } from '@ohos/flutter_ohos';
import {
  JVerificationInterface,
  JVerifyUIConfigBuilder,
  PrivacyBean,
} from '@jg/verify';
import { JverifyCMUIAdapter, PrivacyItemConfig } from './JverifyCMUIAdapter';
import {
  buildHarmonyAuthCustomViews,
  buildHarmonyCheckDialogCustomViews,
  configureHarmonyAuthCustomViews,
  configureHarmonyCheckDialogCustomViews,
  JverifyCustomViewStyle,
} from './JverifyHarmonyViews';
import { JverifyLog } from './JverifyLog';
import { JverifyNavigation } from './JverifyNavigation';

/** Maps the cross-platform Flutter UI model to the HarmonyOS SDK builder. */
export class JverifyUIAdapter {
  static apply(call: MethodCall, configKey: string, onBackPressed?: () => void,
    onWidgetClick?: (id: string) => void, onDismiss?: () => void,
    onToast?: (message: string) => void,
    defaultTopSafeAreaHeight: number = 44, defaultBottomSafeAreaHeight: number = 0,
    resolveMedia?: (name: string) => string): void {
    const config: Map<string, Object> | undefined = JverifyUIAdapter.readArgumentMap(call, configKey);
    if (config === undefined) {
      JverifyLog.warn(call.method + ' ignored: ' + configKey + ' is missing');
      return;
    }

    const builder: JVerifyUIConfigBuilder = new JVerifyUIConfigBuilder();
    const privacyItems: Array<PrivacyItemConfig> = JverifyUIAdapter.readPrivacyItems(config);
    JverifyUIAdapter.applyPage(config, builder, defaultTopSafeAreaHeight, defaultBottomSafeAreaHeight);
    JverifyUIAdapter.applyReturnButton(config, builder);
    JverifyUIAdapter.applyLogo(config, builder);
    JverifyUIAdapter.applyNumber(config, builder);
    JverifyUIAdapter.applySlogan(config, builder);
    JverifyUIAdapter.applyLoginButton(config, builder);
    JverifyUIAdapter.applyPrivacy(config, privacyItems, builder);
    JverifyUIAdapter.applyPrivacyNavigation(config, builder);
    JverifyUIAdapter.applyDialog(config, builder);
    JverifyUIAdapter.applyPrivacyCheckDialog(config, builder);
    JverifyUIAdapter.applyCustomViews(call, config, builder, onWidgetClick, onDismiss, onToast, resolveMedia);
    builder.setCmUIConfig(JverifyCMUIAdapter.apply(
      config, privacyItems, onBackPressed, onWidgetClick, onDismiss, onToast, resolveMedia));
    JverifyUIAdapter.warnUnsupportedOptions(call, config);

    JVerificationInterface.setCustomUIWithConfig(builder.build());
    JverifyLog.info(call.method + ' applied to HarmonyOS JVerifyUIConfig');

  }

  private static applyPage(config: Map<string, Object>, builder: JVerifyUIConfigBuilder,
    defaultTopSafeAreaHeight: number, defaultBottomSafeAreaHeight: number): void {
    const background: string | undefined = JverifyUIAdapter.stringValue(config, 'authBackgroundImage');
    if (background !== undefined) {
      builder.setAuthBGImgPath(background);
    }
    const gifPath: string | undefined = JverifyUIAdapter.stringValue(config, 'authBGGifPath');
    if (gifPath !== undefined) {
      builder.setAuthBGGifPath(gifPath);
    }
    const videoPath: string | undefined = JverifyUIAdapter.stringValue(config, 'authBGVideoPath');
    const videoImagePath: string | undefined = JverifyUIAdapter.stringValue(config, 'authBGVideoImgPath');
    if (videoPath !== undefined && videoImagePath !== undefined) {
      builder.setAuthBGVideoPath(videoPath, videoImagePath);
    } else if (videoPath !== undefined) {
      JverifyLog.warn('authBGVideoPath ignored on HarmonyOS: authBGVideoImgPath is required');
    }

    const fontFollowSystem: boolean | undefined =
      JverifyUIAdapter.booleanValue(config, 'harmonyAuthPageFontFollowSystem');
    if (fontFollowSystem !== undefined) {
      builder.setAuthPageFontFollowSystem(fontFollowSystem);
    }
    const topSafeAreaHeight: number | undefined =
      JverifyUIAdapter.numberValue(config, 'harmonyTopSafeAreaHeight');
    builder.setTopSafeAreaHeight(topSafeAreaHeight ?? defaultTopSafeAreaHeight);
    const bottomSafeAreaHeight: number | undefined =
      JverifyUIAdapter.numberValue(config, 'harmonyBottomSafeAreaHeight');
    builder.setBottomSafeAreaHeight(bottomSafeAreaHeight ?? defaultBottomSafeAreaHeight);
    const stackLayout: boolean | undefined = JverifyUIAdapter.booleanValue(config, 'harmonyStackLayout');
    if (stackLayout !== undefined) {
      builder.setStackLayout(stackLayout);
    }
  }

  private static applyReturnButton(config: Map<string, Object>, builder: JVerifyUIConfigBuilder): void {
    const imagePath: string | undefined = JverifyUIAdapter.stringValue(config, 'navReturnImgPath');
    if (imagePath !== undefined) {
      builder.setReturnBtnImgPath(imagePath);
    }
    const navHidden: boolean | undefined = JverifyUIAdapter.booleanValue(config, 'navHidden');
    const returnHidden: boolean | undefined = JverifyUIAdapter.booleanValue(config, 'navReturnBtnHidden');
    if (navHidden !== undefined || returnHidden !== undefined) {
      builder.setReturnBtnHidden(navHidden === true || returnHidden === true);
    }
    const offsetX: number | undefined = JverifyUIAdapter.numberValue(config, 'navReturnBtnOffsetX');
    if (offsetX !== undefined) {
      builder.setReturnBtnOffsetX(offsetX);
    }
    const offsetY: number | undefined = JverifyUIAdapter.numberValue(config, 'navReturnBtnOffsetY');
    if (offsetY !== undefined) {
      builder.setReturnBtnOffsetY(offsetY);
    }
    const width: number | undefined = JverifyUIAdapter.numberValue(config, 'harmonyReturnBtnWidth');
    if (width !== undefined) {
      builder.setReturnBtnWidth(width);
    }
    const height: number | undefined = JverifyUIAdapter.numberValue(config, 'harmonyReturnBtnHeight');
    if (height !== undefined) {
      builder.setReturnBtnHeight(height);
    }
  }

  private static applyLogo(config: Map<string, Object>, builder: JVerifyUIConfigBuilder): void {
    const imagePath: string | undefined = JverifyUIAdapter.stringValue(config, 'logoImgPath');
    if (imagePath !== undefined) {
      builder.setLogoImgPath(imagePath);
    }
    const width: number | undefined = JverifyUIAdapter.numberValue(config, 'logoWidth');
    if (width !== undefined) {
      builder.setLogoWidth(width);
    }
    const height: number | undefined = JverifyUIAdapter.numberValue(config, 'logoHeight');
    if (height !== undefined) {
      builder.setLogoHeight(height);
    }
    const offsetX: number | undefined = JverifyUIAdapter.numberValue(config, 'logoOffsetX');
    if (offsetX !== undefined) {
      builder.setLogoOffsetX(offsetX);
    }
    const offsetY: number | undefined = JverifyUIAdapter.numberValue(config, 'logoOffsetY');
    if (offsetY !== undefined) {
      builder.setLogoOffsetY(offsetY);
    }
    const hidden: boolean | undefined = JverifyUIAdapter.booleanValue(config, 'logoHidden');
    if (hidden !== undefined) {
      builder.setLogoHidden(hidden);
    }
  }

  private static applyNumber(config: Map<string, Object>, builder: JVerifyUIConfigBuilder): void {
    const color: number | undefined = JverifyUIAdapter.numberValue(config, 'numberColor');
    if (color !== undefined) {
      builder.setNumberColor(color);
    }
    const size: number | undefined = JverifyUIAdapter.numberValue(config, 'numberSize');
    if (size !== undefined) {
      builder.setNumberSize(size);
    }
    const offsetX: number | undefined = JverifyUIAdapter.numberValue(config, 'numFieldOffsetX');
    if (offsetX !== undefined) {
      builder.setNumberFieldOffsetX(offsetX);
    }
    const offsetY: number | undefined = JverifyUIAdapter.numberValue(config, 'numFieldOffsetY');
    if (offsetY !== undefined) {
      builder.setNumberFieldOffsetY(offsetY);
    }
    const width: number | undefined = JverifyUIAdapter.numberValue(config, 'numberFieldWidth');
    if (width !== undefined) {
      builder.setNumberFieldWidth(width);
    }
    const height: number | undefined = JverifyUIAdapter.numberValue(config, 'numberFieldHeight');
    if (height !== undefined) {
      builder.setNumberFieldHeight(height);
    }
    const bold: boolean | undefined = JverifyUIAdapter.booleanValue(config, 'numberTextBold');
    if (bold !== undefined) {
      builder.setNumberTextBold(bold);
    }
  }

  private static applySlogan(config: Map<string, Object>, builder: JVerifyUIConfigBuilder): void {
    const color: number | undefined = JverifyUIAdapter.numberValue(config, 'sloganTextColor');
    if (color !== undefined) {
      builder.setSloganTextColor(color);
    }
    const size: number | undefined = JverifyUIAdapter.numberValue(config, 'sloganTextSize');
    if (size !== undefined) {
      builder.setSloganTextSize(size);
    }
    const offsetX: number | undefined = JverifyUIAdapter.numberValue(config, 'sloganOffsetX');
    if (offsetX !== undefined) {
      builder.setSloganOffsetX(offsetX);
    }
    const offsetY: number | undefined = JverifyUIAdapter.numberValue(config, 'sloganOffsetY');
    if (offsetY !== undefined) {
      builder.setSloganOffsetY(offsetY);
    }
    const bold: boolean | undefined = JverifyUIAdapter.booleanValue(config, 'sloganTextBold');
    if (bold !== undefined) {
      builder.setSloganTextBold(bold);
    }
  }

  private static applyLoginButton(config: Map<string, Object>, builder: JVerifyUIConfigBuilder): void {
    const text: string | undefined = JverifyUIAdapter.stringValue(config, 'logBtnText');
    if (text !== undefined) {
      builder.setLogBtnText(text);
    }
    const color: number | undefined = JverifyUIAdapter.numberValue(config, 'logBtnTextColor');
    if (color !== undefined) {
      builder.setLogBtnTextColor(color);
    }
    const imagePath: string | undefined = JverifyUIAdapter.stringValue(config, 'logBtnBackgroundPath');
    if (imagePath !== undefined) {
      builder.setLogBtnImgPath(imagePath);
    }
    const offsetX: number | undefined = JverifyUIAdapter.numberValue(config, 'logBtnOffsetX');
    if (offsetX !== undefined) {
      builder.setLogBtnOffsetX(offsetX);
    }
    const offsetY: number | undefined = JverifyUIAdapter.numberValue(config, 'logBtnOffsetY');
    if (offsetY !== undefined) {
      builder.setLogBtnOffsetY(offsetY);
    }
    const width: number | undefined = JverifyUIAdapter.numberValue(config, 'logBtnWidth');
    if (width !== undefined) {
      builder.setLogBtnWidth(width);
    }
    const height: number | undefined = JverifyUIAdapter.numberValue(config, 'logBtnHeight');
    if (height !== undefined) {
      builder.setLogBtnHeight(height);
    }
    const size: number | undefined = JverifyUIAdapter.numberValue(config, 'logBtnTextSize');
    if (size !== undefined) {
      builder.setLogBtnTextSize(size);
    }
    const bold: boolean | undefined = JverifyUIAdapter.booleanValue(config, 'logBtnTextBold');
    if (bold !== undefined) {
      builder.setLogBtnTextBold(bold);
    }
    const backgroundColor: number | undefined =
      JverifyUIAdapter.numberValue(config, 'harmonyLogBtnBackgroundColor');
    if (backgroundColor !== undefined) {
      builder.setLogBtnBackgroundColor(backgroundColor);
    }
    const borderRadius: number | undefined =
      JverifyUIAdapter.numberValue(config, 'harmonyLogBtnBorderRadius');
    if (borderRadius !== undefined) {
      builder.setLogBtnBorderRadius(borderRadius);
    }
  }

  private static applyPrivacy(config: Map<string, Object>, privacyItems: Array<PrivacyItemConfig>,
    builder: JVerifyUIConfigBuilder): void {
    const baseColor: number | undefined = JverifyUIAdapter.numberValue(config, 'clauseBaseColor');
    const clauseColor: number | undefined = JverifyUIAdapter.numberValue(config, 'clauseColor');
    if (baseColor !== undefined || clauseColor !== undefined) {
      builder.setPrivacyColor(baseColor ?? 0xFF808080, clauseColor ?? 0x00359AF3);
    }
    const checkedPath: string | undefined = JverifyUIAdapter.stringValue(config, 'checkedImgPath');
    if (checkedPath !== undefined) {
      builder.setCheckedImgPath(checkedPath);
    }
    const uncheckedPath: string | undefined = JverifyUIAdapter.stringValue(config, 'uncheckedImgPath');
    if (uncheckedPath !== undefined) {
      builder.setUncheckedImgPath(uncheckedPath);
    }
    const state: boolean | undefined = JverifyUIAdapter.booleanValue(config, 'privacyState');
    if (state !== undefined) {
      builder.setPrivacyState(state);
    }
    const center: boolean | undefined = JverifyUIAdapter.booleanValue(config, 'privacyTextCenterGravity');
    if (center !== undefined) {
      builder.setPrivacyTextCenterGravity(center);
    }
    const textSize: number | undefined = JverifyUIAdapter.numberValue(config, 'privacyTextSize');
    if (textSize !== undefined) {
      builder.setPrivacyTextSize(textSize);
    }
    const checkboxSize: number | undefined = JverifyUIAdapter.numberValue(config, 'privacyCheckboxSize');
    if (checkboxSize !== undefined) {
      builder.setPrivacyCheckboxSize(checkboxSize);
    }
    const checkboxCenter: boolean | undefined =
      JverifyUIAdapter.booleanValue(config, 'privacyCheckboxInCenter');
    if (checkboxCenter !== undefined) {
      builder.setPrivacyCheckboxInCenter(checkboxCenter);
    }
    const hintText: string | undefined = JverifyUIAdapter.stringValue(config, 'harmonyPrivacyHintToastText');
    if (hintText !== undefined) {
      builder.setEnableHintToastText(hintText);
    }
    const bold: boolean | undefined = JverifyUIAdapter.booleanValue(config, 'privacyTextBold');
    if (bold !== undefined) {
      builder.setPrivacyTextBold(bold);
    }
    const underline: boolean | undefined = JverifyUIAdapter.booleanValue(config, 'privacyUnderlineText');
    if (underline !== undefined) {
      builder.setPrivacyUnderlineText(underline);
    }
    const bookTitleMark: boolean | undefined =
      JverifyUIAdapter.booleanValue(config, 'privacyWithBookTitleMark');
    if (bookTitleMark !== undefined) {
      builder.setPrivacyWithBookTitleMark(bookTitleMark);
    }

    const privacyText: Array<string> | undefined = JverifyUIAdapter.stringListValue(config, 'privacyText');
    const harmonyStart: string | undefined = JverifyUIAdapter.stringValue(config, 'harmonyPrivacyClauseStart');
    const harmonyEnd: string | undefined = JverifyUIAdapter.stringValue(config, 'harmonyPrivacyClauseEnd');
    const start: string | undefined = harmonyStart ??
      (privacyText !== undefined && privacyText.length > 0 ? privacyText[0] : undefined);
    const end: string | undefined = harmonyEnd ??
      (privacyText !== undefined && privacyText.length > 1 ? privacyText[1] : undefined);
    if (start !== undefined || end !== undefined) {
      builder.setPrivacyText(start ?? '', end ?? '');
    }

    const left: number | undefined = JverifyUIAdapter.numberValue(config, 'privacyOffsetX');
    const right: number | undefined = JverifyUIAdapter.numberValue(config, 'privacyMarginR');
    const top: number | undefined = JverifyUIAdapter.numberValue(config, 'privacyTopOffsetY');
    const bottom: number | undefined = JverifyUIAdapter.numberValue(config, 'privacyOffsetY');
    if (left !== undefined || right !== undefined || top !== undefined || bottom !== undefined) {
      const margin: Margin = {
        left: left ?? 10,
        right: right ?? 20,
        top: top ?? 0,
        bottom: bottom ?? 70,
      };
      builder.setPrivacyMargin(margin);
    }

    const privacyBeans: Array<PrivacyBean> = JverifyUIAdapter.buildPrivacyBeans(config, privacyItems);
    if (privacyBeans.length > 0) {
      builder.setPrivacyNameAndUrlBeanList(privacyBeans);
    }
  }

  private static applyPrivacyNavigation(config: Map<string, Object>, builder: JVerifyUIConfigBuilder): void {
    const color: number | undefined = JverifyUIAdapter.numberValue(config, 'privacyNavColor');
    if (color !== undefined) {
      builder.setPrivacyNavColor(color);
    }
    const titleColor: number | undefined = JverifyUIAdapter.numberValue(config, 'privacyNavTitleTextColor');
    if (titleColor !== undefined) {
      builder.setPrivacyNavTitleTextColor(titleColor);
    }
    const titleSize: number | undefined = JverifyUIAdapter.numberValue(config, 'privacyNavTitleTextSize');
    if (titleSize !== undefined) {
      builder.setPrivacyNavTitleTextSize(titleSize);
    }
    const titleBold: boolean | undefined = JverifyUIAdapter.booleanValue(config, 'privacyNavTitleTextBold');
    if (titleBold !== undefined) {
      builder.setPrivacyNavTitleTextBold(titleBold);
    }
    const returnPath: string | undefined = JverifyUIAdapter.stringValue(config, 'privacyNavReturnBtnImage');
    if (returnPath !== undefined) {
      builder.setPrivacyNavReturnBtnPath(returnPath);
    }
  }

  private static applyDialog(config: Map<string, Object>, builder: JVerifyUIConfigBuilder): void {
    const popConfig: Map<string, Object> | undefined = JverifyUIAdapter.mapValue(config, 'popViewConfig');
    if (popConfig === undefined) {
      return;
    }
    const enabled: boolean = JverifyUIAdapter.booleanValue(popConfig, 'isPopViewTheme') ?? true;
    if (!enabled) {
      builder.enableDialogMode(false);
      return;
    }
    const hostPage: Object | undefined = JverifyNavigation.getHostPage();
    if (hostPage === undefined) {
      JverifyLog.warn('HarmonyOS dialog mode ignored: host page is unavailable');
      return;
    }
    builder.enableDialogMode(true).setDialogPage(hostPage);
    const width: number | undefined = JverifyUIAdapter.numberValue(popConfig, 'width');
    if (width !== undefined) {
      builder.setDialogWidth(width);
    }
    const height: number | undefined = JverifyUIAdapter.numberValue(popConfig, 'height');
    if (height !== undefined) {
      builder.setDialogHeight(height);
    }
  }

  private static applyPrivacyCheckDialog(config: Map<string, Object>, builder: JVerifyUIConfigBuilder): void {
    const legacyEnabled: boolean | undefined = JverifyUIAdapter.booleanValue(config, 'isAlertPrivacyVc');
    const dialog: Map<string, Object> | undefined =
      JverifyUIAdapter.mapValue(config, 'privacyCheckDialogConfig');
    if (dialog === undefined && legacyEnabled === undefined) {
      return;
    }
    const enabled: boolean | undefined = dialog === undefined ? legacyEnabled :
      (JverifyUIAdapter.booleanValue(dialog, 'enablePrivacyCheckDialog') ?? legacyEnabled);
    if (enabled !== undefined) {
      builder.setEnablePrivacyCheckDialog(enabled);
    }
    if (dialog === undefined) {
      return;
    }
    const title: string | undefined = JverifyUIAdapter.stringValue(dialog, 'title');
    if (title !== undefined) {
      builder.setPrivacyCheckDialogTitleText(title);
    }
    const loginText: string | undefined = JverifyUIAdapter.stringValue(dialog, 'logBtnText');
    if (loginText !== undefined) {
      builder.setPrivacyCheckDialogLogBtnText(loginText);
    }
    const titleSize: number | undefined = JverifyUIAdapter.numberValue(dialog, 'titleTextSize');
    if (titleSize !== undefined) {
      builder.setPrivacyCheckDialogTitleTextSize(titleSize);
    }
    const titleColor: number | undefined = JverifyUIAdapter.numberValue(dialog, 'titleTextColor');
    if (titleColor !== undefined) {
      builder.setPrivacyCheckDialogTitleTextColor(titleColor);
    }
    const contentGravity: string | undefined = JverifyUIAdapter.stringValue(dialog, 'contentTextGravity');
    if (contentGravity !== undefined) {
      builder.setPrivacyCheckDialogContentTextGravityCenter(contentGravity.toLowerCase() === 'center');
    }
    const contentSize: number | undefined = JverifyUIAdapter.numberValue(dialog, 'contentTextSize');
    if (contentSize !== undefined) {
      builder.setPrivacyCheckDialogContentTextSize(contentSize);
    }
    const imagePath: string | undefined = JverifyUIAdapter.stringValue(dialog, 'logBtnImgPath');
    if (imagePath !== undefined) {
      builder.setPrivacyCheckDialogLogBtnImgPath(imagePath);
    }
    const loginColor: number | undefined = JverifyUIAdapter.numberValue(dialog, 'logBtnTextColor');
    if (loginColor !== undefined) {
      builder.setPrivacyCheckDialoglogBtnTextColor(loginColor);
    }
    const width: number | undefined = JverifyUIAdapter.numberValue(dialog, 'width');
    if (width !== undefined) {
      builder.setPrivacyCheckDialogWidth(width);
    }
    const height: number | undefined = JverifyUIAdapter.numberValue(dialog, 'height');
    if (height !== undefined) {
      builder.setPrivacyCheckDialogHeight(height);
    }
    const loginWidth: number | undefined = JverifyUIAdapter.numberValue(dialog, 'logBtnWidth');
    if (loginWidth !== undefined) {
      builder.setPrivacyCheckDialogLogBtnWidth(loginWidth);
    }
    const loginHeight: number | undefined = JverifyUIAdapter.numberValue(dialog, 'logBtnHeight');
    if (loginHeight !== undefined) {
      builder.setPrivacyCheckDialogLogBtnHeight(loginHeight);
    }
    const backgroundColor: number | undefined = JverifyUIAdapter.numberValue(dialog, 'privacyBackgroundColor');
    if (backgroundColor !== undefined) {
      builder.setPrivacyCheckDialogBackgroundColor(backgroundColor);
    }
    const backgroundPath: string | undefined = JverifyUIAdapter.stringValue(dialog, 'privacyBackgroundPath');
    if (backgroundPath !== undefined) {
      builder.setPrivacyCheckDialogBackgroundImgPath(backgroundPath);
    }

    const contentLeft: number | undefined = JverifyUIAdapter.numberValue(dialog, 'contentTextPaddingL');
    const contentRight: number | undefined = JverifyUIAdapter.numberValue(dialog, 'contentTextPaddingR');
    const contentTop: number | undefined = JverifyUIAdapter.numberValue(dialog, 'contentTextPaddingT');
    const contentBottom: number | undefined = JverifyUIAdapter.numberValue(dialog, 'contentTextPaddingB');
    if (contentLeft !== undefined || contentRight !== undefined ||
      contentTop !== undefined || contentBottom !== undefined) {
      const margin: Margin = {
        left: contentLeft ?? 10,
        right: contentRight ?? 15,
        top: contentTop ?? 30,
        bottom: contentBottom ?? 0,
      };
      builder.setPrivacyCheckDialogContentTextMargin(margin);
    }

    const loginLeft: number | undefined = JverifyUIAdapter.numberValue(dialog, 'logBtnMarginL');
    const loginRight: number | undefined = JverifyUIAdapter.numberValue(dialog, 'logBtnMarginR');
    const loginTop: number | undefined = JverifyUIAdapter.numberValue(dialog, 'logBtnMarginT');
    const loginBottom: number | undefined = JverifyUIAdapter.numberValue(dialog, 'logBtnMarginB');
    if (loginLeft !== undefined || loginRight !== undefined || loginTop !== undefined || loginBottom !== undefined) {
      const margin: Margin = {
        left: loginLeft ?? 25,
        right: loginRight ?? 25,
        top: loginTop ?? 30,
        bottom: loginBottom ?? 0,
      };
      builder.setPrivacyCheckDialogLogBtnMargin(margin);
    }
  }

  private static applyCustomViews(call: MethodCall, config: Map<string, Object>,
    builder: JVerifyUIConfigBuilder, onWidgetClick?: (id: string) => void,
    onDismiss?: () => void, onToast?: (message: string) => void,
    resolveMedia?: (name: string) => string): void {
    const authStyles: Array<JverifyCustomViewStyle> = JverifyUIAdapter.readCustomViewStyles(
      call.argument('widgets') as Object | null, 'callback', onWidgetClick, onDismiss, onToast, resolveMedia);
    if (authStyles.length > 0) {
      configureHarmonyAuthCustomViews(authStyles);
      builder.addCustomView(wrapBuilder(buildHarmonyAuthCustomViews));
    }

    const dialog: Map<string, Object> | undefined =
      JverifyUIAdapter.mapValue(config, 'privacyCheckDialogConfig');
    const dialogStyles: Array<JverifyCustomViewStyle> = dialog === undefined
      ? new Array<JverifyCustomViewStyle>()
      : JverifyUIAdapter.readCustomViewStyles(
        JverifyUIAdapter.value(dialog, 'widgets'), 'closeCheckDialog', onWidgetClick, onDismiss, onToast, resolveMedia);
    if (dialogStyles.length > 0) {
      configureHarmonyCheckDialogCustomViews(dialogStyles);
      builder.addCustomViewToCheckDialog(wrapBuilder(buildHarmonyCheckDialogCustomViews));
    }
  }

  private static readCustomViewStyles(value: Object | null | undefined, defaultAction: string,
    onWidgetClick?: (id: string) => void, onDismiss?: () => void,
    onToast?: (message: string) => void,
    resolveMedia?: (name: string) => string): Array<JverifyCustomViewStyle> {
    const styles: Array<JverifyCustomViewStyle> = new Array<JverifyCustomViewStyle>();
    if (!(value instanceof Array)) {
      return styles;
    }
    let ignoredPressedImages: boolean = false;
    (value as Array<Object>).forEach((item: Object, index: number): void => {
      if (!(item instanceof Map)) {
        return;
      }
      const source: Map<string, Object> = item as Map<string, Object>;
      const style: JverifyCustomViewStyle = new JverifyCustomViewStyle();
      style.id = JverifyUIAdapter.stringValue(source, 'widgetId') ?? 'harmony-widget-' + index;
      style.type = JverifyUIAdapter.stringValue(source, 'type') ?? 'textView';
      style.text = JverifyUIAdapter.stringValue(source, 'title') ?? '';
      style.textSize = JverifyUIAdapter.numberValue(source, 'titleFont') ?? 13;
      style.textColor = JverifyUIAdapter.numberValue(source, 'titleColor') ?? 0xFF000000;
      style.backgroundColor = JverifyUIAdapter.numberValue(source, 'backgroundColor') ?? 0x00000000;
      const width: number = JverifyUIAdapter.numberValue(source, 'width') ?? 0;
      const height: number = JverifyUIAdapter.numberValue(source, 'height') ?? 0;
      style.width = width > 0 ? width : 120;
      style.height = height > 0 ? height : 40;
      style.borderRadius = JverifyUIAdapter.numberValue(source, 'harmonyBorderRadius') ?? 8;
      style.marginLeft = JverifyUIAdapter.numberValue(source, 'left') ?? 0;
      style.marginTop = JverifyUIAdapter.numberValue(source, 'top') ?? 0;
      style.textAlign = JverifyUIAdapter.stringValue(source, 'textAlignment') ?? 'center';
      style.underline = JverifyUIAdapter.booleanValue(source, 'isShowUnderline') ?? false;
      const image: Map<string, Object> | undefined = JverifyUIAdapter.mapValue(source, 'harmonyImage');
      if (image !== undefined) {
        const directSource: string | undefined = JverifyUIAdapter.stringValue(image, 'source');
        const imageName: string | undefined = JverifyUIAdapter.stringValue(image, 'name');
        if (directSource !== undefined) {
          style.imageSource = directSource;
        } else if (imageName !== undefined) {
          style.imageSource = resolveMedia === undefined ? imageName : resolveMedia(imageName);
        }
        style.imageFit = JverifyUIAdapter.stringValue(image, 'fit') ?? 'contain';
      } else {
        const normalImageName: string | undefined =
          JverifyUIAdapter.stringValue(source, 'btnNormalImageName');
        if (normalImageName !== undefined) {
          style.imageSource = resolveMedia === undefined ? normalImageName : resolveMedia(normalImageName);
        }
      }
      style.isClickEnabled = JverifyUIAdapter.booleanValue(source, 'isClickEnable') ?? false;
      const action: string = JverifyUIAdapter.stringValue(source, 'harmonyAction') ?? defaultAction;
      const toastText: string | undefined = JverifyUIAdapter.stringValue(source, 'harmonyToastText');
      style.onClick = (): void => {
        if (style.id.length > 0 && onWidgetClick !== undefined) {
          onWidgetClick(style.id);
        }
        if (toastText !== undefined && toastText.length > 0 && onToast !== undefined) {
          onToast(toastText);
        }
        if (action === 'dismissLoginAuth' && onDismiss !== undefined) {
          onDismiss();
        } else if (action === 'closeCheckDialog') {
          JVerificationInterface.closeCheckDialog();
        }
      };
      if (JverifyUIAdapter.stringValue(source, 'btnPressedImageName') !== undefined) {
        ignoredPressedImages = true;
      }
      if (style.type === 'image' && style.imageSource.length === 0) {
        JverifyLog.warn('HarmonyOS custom image ignored: media source unavailable for id=' + style.id);
        return;
      }
      styles.push(style);
    });
    if (ignoredPressedImages) {
      JverifyLog.warn('HarmonyOS custom button pressed-state images are not switched; normal image is used');
    }
    return styles;
  }

  /** Logs only actively configured values that have no HarmonyOS SDK equivalent. */
  private static warnUnsupportedOptions(call: MethodCall, config: Map<string, Object>): void {
    const groups: Array<string> = new Array<string>();
    const landscape: Object | null = call.argument('landscapeConfig') as Object | null;
    const autorotate: Object | null = call.argument('isAutorotate') as Object | null;
    if (landscape instanceof Map || autorotate === true) {
      groups.push('landscapeConfig/isAutorotate');
    }
    if (JverifyUIAdapter.hasAnyValue(config, [
      'logoOffsetBottomY', 'numberFieldOffsetBottomY', 'logBtnBottomOffsetY',
      'sloganBottomOffsetY', 'privacyMarginT', 'privacyNavTitleTitle',
      'privacyNavTitleTitle1', 'privacyNavTitleTitle2', 'virtualButtonColor',
      'privacyVirtualButtonColor',
    ])) {
      groups.push('iOS/Android-only layout or system-bar fields');
    }
    if (JverifyUIAdapter.hasAnyTrue(config, [
      'privacyCheckboxHidden', 'openPrivacyInBrowser', 'privacyStatusBarColorWithNav',
      'privacyStatusBarDarkMode', 'privacyStatusBarTransparent', 'privacyStatusBarHidden',
      'privacyVirtualButtonTransparent', 'statusBarColorWithNav', 'statusBarDarkMode',
      'statusBarTransparent', 'statusBarHidden', 'virtualButtonTransparent',
      'virtualButtonHidden', 'needStartAnim', 'needCloseAnim',
    ])) {
      groups.push('iOS/Android-only boolean UI fields');
    }
    if (JverifyUIAdapter.hasAnyValue(config, [
      'loginBtnNormalImage', 'loginBtnPressedImage', 'loginBtnUnableImage',
    ])) {
      groups.push('iOS/Android login-button state images');
    }
    if (JverifyUIAdapter.mapValue(config, 'smsUIConfig') !== undefined) {
      groups.push('smsUIConfig');
    }
    if (groups.length > 0) {
      JverifyLog.warn('HarmonyOS ignored unsupported UI options: ' + groups.join(', '));
    }
  }

  private static hasAnyValue(config: Map<string, Object>, keys: Array<string>): boolean {
    for (let index: number = 0; index < keys.length; index++) {
      const value: Object | null | undefined = config.get(keys[index]);
      if (value !== undefined && value !== null) {
        return true;
      }
    }
    return false;
  }

  private static hasAnyTrue(config: Map<string, Object>, keys: Array<string>): boolean {
    for (let index: number = 0; index < keys.length; index++) {
      if (config.get(keys[index]) === true) {
        return true;
      }
    }
    return false;
  }

  private static buildPrivacyBeans(config: Map<string, Object>,
    privacyItems: Array<PrivacyItemConfig>): Array<PrivacyBean> {
    const beans: Array<PrivacyBean> = new Array<PrivacyBean>();
    if (privacyItems.length > 0) {
      privacyItems.forEach((item: PrivacyItemConfig): void => {
        JverifyUIAdapter.appendPrivacyBean(beans, item.name, item.url, item.separator);
      });
      return beans;
    }
    JverifyUIAdapter.appendPrivacyBean(beans,
      JverifyUIAdapter.stringValue(config, 'clauseName'),
      JverifyUIAdapter.stringValue(config, 'clauseUrl'));
    JverifyUIAdapter.appendPrivacyBean(beans,
      JverifyUIAdapter.stringValue(config, 'clauseNameTwo'),
      JverifyUIAdapter.stringValue(config, 'clauseUrlTwo'));
    return beans;
  }

  private static appendPrivacyBean(beans: Array<PrivacyBean>, name?: string, url?: string,
    separator?: string): void {
    if (name === undefined || url === undefined) {
      return;
    }
    const bean: PrivacyBean = new PrivacyBean();
    bean.name = name;
    bean.text = name;
    bean.url = url;
    bean.separator = separator ?? '';
    beans.push(bean);
  }

  private static readPrivacyItems(config: Map<string, Object>): Array<PrivacyItemConfig> {
    const rawItems: string | undefined = JverifyUIAdapter.stringValue(config, 'privacyItem');
    if (rawItems === undefined || rawItems.length === 0) {
      return new Array<PrivacyItemConfig>();
    }
    try {
      const decodedItems: Array<PrivacyItemConfig> = JSON.parse(rawItems);
      if (!(decodedItems instanceof Array)) {
        JverifyLog.warn('privacyItem ignored on HarmonyOS: expected a JSON array');
        return new Array<PrivacyItemConfig>();
      }
      const items: Array<PrivacyItemConfig> = new Array<PrivacyItemConfig>();
      decodedItems.forEach((item: PrivacyItemConfig): void => {
        if (item !== null && typeof item === 'object' &&
          typeof item.name === 'string' && item.name.length > 0 &&
          typeof item.url === 'string' && item.url.length > 0) {
          items.push(item);
        }
      });
      if (items.length !== decodedItems.length) {
        JverifyLog.warn('privacyItem contains invalid entries; HarmonyOS ignored those entries');
      }
      return items;
    } catch (error) {
      JverifyLog.warn('privacyItem ignored on HarmonyOS: invalid JSON');
      return new Array<PrivacyItemConfig>();
    }
  }

  private static readArgumentMap(call: MethodCall, key: string): Map<string, Object> | undefined {
    const value: Object | null = call.argument(key) as Object | null;
    if (value instanceof Map) {
      return value as Map<string, Object>;
    }
    return undefined;
  }

  private static mapValue(map: Map<string, Object>, key: string): Map<string, Object> | undefined {
    const value: Object | null | undefined = JverifyUIAdapter.value(map, key);
    if (value instanceof Map) {
      return value as Map<string, Object>;
    }
    return undefined;
  }

  private static stringValue(map: Map<string, Object>, key: string): string | undefined {
    const value: Object | null | undefined = JverifyUIAdapter.value(map, key);
    return typeof value === 'string' ? value : undefined;
  }

  private static numberValue(map: Map<string, Object>, key: string): number | undefined {
    const value: Object | null | undefined = JverifyUIAdapter.value(map, key);
    return typeof value === 'number' ? value : undefined;
  }

  private static booleanValue(map: Map<string, Object>, key: string): boolean | undefined {
    const value: Object | null | undefined = JverifyUIAdapter.value(map, key);
    return typeof value === 'boolean' ? value : undefined;
  }

  private static stringListValue(map: Map<string, Object>, key: string): Array<string> | undefined {
    const value: Object | null | undefined = JverifyUIAdapter.value(map, key);
    if (!(value instanceof Array)) {
      return undefined;
    }
    const rawValues: Array<Object> = value as Array<Object>;
    const values: Array<string> = new Array<string>();
    rawValues.forEach((item: Object): void => {
      if (typeof item === 'string') {
        values.push(item);
      }
    });
    return values;
  }

  private static value(map: Map<string, Object>, key: string): Object | null | undefined {
    return map.get(key);
  }
}
