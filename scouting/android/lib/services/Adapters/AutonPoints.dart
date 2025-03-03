import 'package:hive/hive.dart';

part 'AutonPoints.g.dart';

@HiveType(typeId: 0)
class AutonPoints {
  @HiveField(0)
  final int CoralScoringLevel1;
  @HiveField(1)
  final int CoralScoringLevel2;
  @HiveField(2)
  final int CoralScoringLevel3;
  @HiveField(3)
  final int CoralScoringLevel4;
  @HiveField(4)
  final bool LeftBarge;
  @HiveField(5)
  final int AlgaeScoringProcessor;
  @HiveField(6)
  final int AlgaeScoringBarge;

  AutonPoints(
    this.CoralScoringLevel1,
    this.CoralScoringLevel2,
    this.CoralScoringLevel3,
    this.CoralScoringLevel4,
    this.LeftBarge,
    this.AlgaeScoringProcessor,
    this.AlgaeScoringBarge,
  );

  Map<String, dynamic> toJson() {
    return {
      'CoralScoringLevel1': CoralScoringLevel1,
      'CoralScoringLevel2': CoralScoringLevel2,
      'CoralScoringLevel3': CoralScoringLevel3,
      'CoralScoringLevel4': CoralScoringLevel4,
      'LeftBarge': LeftBarge,
      'AlgaeScoringProcessor': AlgaeScoringProcessor,
      'AlgaeScoringBarge': AlgaeScoringBarge,
    };
  }
}
