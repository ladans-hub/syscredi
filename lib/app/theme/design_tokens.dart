import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';

/// Shared Fluent 2 tokens. Product widgets should consume these values rather
/// than introducing local spacing, shape, elevation or motion constants.
abstract final class FluentTokens {
  static const space2 = 2.0;
  static const space4 = 4.0;
  static const space8 = 8.0;
  static const space12 = 12.0;
  static const space16 = 16.0;
  static const space20 = 20.0;
  static const space24 = 24.0;
  static const space32 = 32.0;
  static const radius2 = 2.0;
  static const radius4 = 4.0;
  static const radius6 = 6.0;
  static const radius8 = 8.0;
  static const radius12 = 12.0;
  static const iconSmall = 16.0;
  static const iconMedium = 20.0;
  static const iconLarge = 24.0;
  static const controlHeight = 40.0;
  static const navigationWidth = 272.0;
  static const fast = Duration(milliseconds: 167);
  static const normal = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 358);
  static const curve = Curves.easeOutCubic;

  static List<BoxShadow> elevation(BuildContext context, {int level = 1}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final blur = switch (level) {
      0 => 0.0,
      1 => 8.0,
      2 => 16.0,
      _ => 28.0,
    };
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? .28 : .12),
        blurRadius: blur,
        offset: Offset(0, level * 2),
      ),
    ];
  }
}

/// Semantic Microsoft Fluent System Icons for shared product chrome.
abstract final class FluentSystemIcons {
  static const search = fluent.FluentIcons.search;
  static const home = fluent.FluentIcons.home;
  static const dashboard = fluent.FluentIcons.view_dashboard;
  static const people = fluent.FluentIcons.people;
  static const person = fluent.FluentIcons.contact;
  static const mail = fluent.FluentIcons.mail;
  static const phone = fluent.FluentIcons.phone;
  static const business = fluent.FluentIcons.business_center_logo;
  static const document = fluent.FluentIcons.document;
  static const documentSearch = fluent.FluentIcons.document_search;
  static const analytics = fluent.FluentIcons.analytics_view;
  static const settings = fluent.FluentIcons.settings;
  static const apps = fluent.FluentIcons.apps_content;
  static const payments = fluent.FluentIcons.payment_card;
  static const wallet = fluent.FluentIcons.financial;
  static const history = fluent.FluentIcons.history;
  static const notifications = fluent.FluentIcons.ringer;
  static const pending = fluent.FluentIcons.clock;
  static const calendar = fluent.FluentIcons.calendar;
  static const brightness = fluent.FluentIcons.brightness;
  static const light = fluent.FluentIcons.light;
  static const account = fluent.FluentIcons.contact_card;
  static const add = fluent.FluentIcons.add;
  static const edit = fluent.FluentIcons.edit;
  static const delete = fluent.FluentIcons.delete;
  static const close = fluent.FluentIcons.chrome_close;
  static const check = fluent.FluentIcons.check_mark;
  static const arrowBack = fluent.FluentIcons.back;
  static const arrowForward = fluent.FluentIcons.forward;
  static const chevronRight = fluent.FluentIcons.chevron_right;
  static const more = fluent.FluentIcons.more;
  static const refresh = fluent.FluentIcons.refresh;
  static const filter = fluent.FluentIcons.filter;
  static const upload = fluent.FluentIcons.upload;
  static const download = fluent.FluentIcons.download;
  static const help = fluent.FluentIcons.help;
  static const warning = fluent.FluentIcons.warning;
  static const error = fluent.FluentIcons.error;
  static const lock = fluent.FluentIcons.lock;
  static const shield = fluent.FluentIcons.shield;
  static const sync = fluent.FluentIcons.sync;
}
