enum UnitType {
  service('service', 'Services'),
  socket('socket', 'Sockets'),
  target('target', 'Targets'),
  device('device', 'Devices'),
  mount('mount', 'Mounts'),
  automount('automount', 'Automounts'),
  swap('swap', 'Swaps'),
  timer('timer', 'Timers'),
  path('path', 'Paths'),
  slice('slice', 'Slices'),
  scope('scope', 'Scopes');

  const UnitType(this.suffix, this.displayName);

  final String suffix;

  final String displayName;

  static UnitType? fromUnitName(String unitName) =>
      UnitType.values.where((t) => unitName.endsWith('.${t.suffix}')).firstOrNull;
}

enum UnitLoadState {
  loaded('loaded'),
  notFound('not-found'),
  badSetting('bad-setting'),
  error('error'),
  masked('masked');

  const UnitLoadState(this.value);
  final String value;

  static UnitLoadState fromString(String value) => UnitLoadState.values.firstWhere(
        (e) => e.value == value.toLowerCase(),
        orElse: () => UnitLoadState.error,
      );
}

enum UnitActiveState {
  active('active'),
  reloading('reloading'),
  inactive('inactive'),
  failed('failed'),
  activating('activating'),
  deactivating('deactivating'),
  maintenance('maintenance');

  const UnitActiveState(this.value);
  final String value;

  static UnitActiveState fromString(String value) =>
      UnitActiveState.values.firstWhere(
        (e) => e.value == value.toLowerCase(),
        orElse: () => UnitActiveState.inactive,
      );

  bool get isRunning =>
      this == UnitActiveState.active || this == UnitActiveState.reloading;
  bool get isFailed => this == UnitActiveState.failed;
  bool get isInactive => this == UnitActiveState.inactive;
}

enum UnitFileState {
  enabled('enabled'),
  enabledRuntime('enabled-runtime'),
  linked('linked'),
  linkedRuntime('linked-runtime'),
  alias('alias'),
  masked('masked'),
  maskedRuntime('masked-runtime'),
  static_('static'),
  disabled('disabled'),
  indirect('indirect'),
  generated('generated'),
  transient('transient'),
  bad('bad');

  const UnitFileState(this.value);
  final String value;

  static UnitFileState fromString(String value) => UnitFileState.values.firstWhere(
        (e) => e.value == value.toLowerCase(),
        orElse: () => UnitFileState.disabled,
      );

  bool get isEnabled =>
      this == UnitFileState.enabled ||
      this == UnitFileState.enabledRuntime ||
      this == UnitFileState.alias ||
      this == UnitFileState.static_ ||
      this == UnitFileState.indirect ||
      this == UnitFileState.generated;

  bool get canBeEnabled =>
      this != UnitFileState.static_ &&
      this != UnitFileState.masked &&
      this != UnitFileState.maskedRuntime;
}
