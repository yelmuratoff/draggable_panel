/// Defines how the draggable panel button docks to screen edges.
///
/// - [inside]: The button docks closer to the screen edge (negative offset).
/// - [outside]: The button docks slightly away from the screen edge (positive offset).
enum DockType {
  /// Button docks inside the screen boundary with negative offset.
  inside,

  /// Button docks outside the typical boundary with positive offset.
  outside,
}
