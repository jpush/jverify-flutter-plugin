import { JverifyLog } from './JverifyLog';

/**
 * Shares the host Navigation stack with the native JVerification SDK.
 *
 * HarmonyOS applications must attach a NavPathStack that is also mounted by
 * Navigation(navPathStack). Creating an unattached stack inside the plugin is
 * not sufficient for @jg/verify 1.2.2.
 */
export class JverifyNavigation {
  private static navPathStack?: NavPathStack;
  private static hostPage?: Object;

  static attachNavPathStack(navPathStack: NavPathStack, hostPage?: Object): void {
    JverifyNavigation.navPathStack = navPathStack;
    JverifyNavigation.hostPage = hostPage;
    JverifyLog.info('host NavPathStack attached');
  }

  static detachNavPathStack(navPathStack: NavPathStack): void {
    if (JverifyNavigation.navPathStack === navPathStack) {
      JverifyNavigation.navPathStack = undefined;
      JverifyNavigation.hostPage = undefined;
      JverifyLog.info('host NavPathStack detached');
    }
  }

  static getNavPathStack(): NavPathStack | undefined {
    JverifyLog.info(JverifyNavigation.navPathStack === undefined
      ? 'host NavPathStack lookup: unavailable'
      : 'host NavPathStack lookup: ready');
    return JverifyNavigation.navPathStack;
  }

  static getHostPage(): Object | undefined {
    return JverifyNavigation.hostPage;
  }
}
