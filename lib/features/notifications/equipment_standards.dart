class TempLimits {
  final double min;
  final double max;

  const TempLimits(this.min, this.max);
}

class EquipmentStandards {
  static TempLimits limitsFor(String type) {
    switch (type) {
      case "DEEP_FREEZER":
        return const TempLimits(-45, -20);

      case "BBR":
        return const TempLimits(2, 6);

      case "WALK_IN_COOLER":
        return const TempLimits(2, 8);

      case "PLATELET":
        return const TempLimits(20, 24);

      default:
        return const TempLimits(0, 8);
    }
  }
}
