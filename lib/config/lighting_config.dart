// Flutter-side lighting configuration: the things HA cannot tell us.
//
// Lighting role itself lives in HA as a `role:<name>` entity label — this file
// only supplies the *presentation* of roles (which layers render and in what
// order) and the quantised ranges HA has no way to advertise.

/// Prefixes that mark a lighting-role label.
///
/// The entity registry reports label **ids**, and Home Assistant slugifies label
/// names into ids (the existing "Matterbridge" label has id `matterbridge`), so a
/// label named `role:overhead` arrives as `role_overhead`. Both separators are
/// accepted so the convention works however the label was named.
const roleLabelPrefixes = <String>['role:', 'role_'];

/// The canonical prefix to show users when documenting the convention.
const roleLabelPrefix = 'role:';

/// Default ordered role taxonomy. Rooms without an override render these layers
/// in this order; roles found on labels but absent here are appended after.
const defaultRoleOrder = <String>['overhead', 'task', 'ambient'];

/// Display names for known roles. Unknown roles fall back to a title-cased
/// version of the role name.
const roleDisplayNames = <String, String>{
  'overhead': 'Overhead',
  'task': 'Task',
  'ambient': 'Ambient',
};

/// Discrete colour temperatures (kelvin) for fixtures whose range is quantised.
///
/// Home Assistant advertises `min_color_temp_kelvin` / `max_color_temp_kelvin`
/// as a continuous range even when the underlying device only accepts a handful
/// of values, so stepped fixtures must be declared here. These two are template
/// lights wrapping fan/light combos that accept exactly three temperatures.
const steppedColorTempKelvins = <String, List<int>>{
  'light.bedroom_light': [2700, 4000, 6500],
  'light.study_light': [2700, 4000, 6500],
};

/// Human-facing label for a role name.
String roleDisplayName(String role) {
  final known = roleDisplayNames[role];
  if (known != null) return known;
  if (role.isEmpty) return role;
  return role[0].toUpperCase() + role.substring(1);
}
