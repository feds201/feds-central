// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'AutonPoints.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AutonPointsAdapter extends TypeAdapter<AutonPoints> {
  @override
  final int typeId = 0;

  @override
  AutonPoints read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AutonPoints(
      fields[0] as int,
      fields[1] as int,
      fields[2] as int,
      fields[3] as int,
      fields[4] as bool,
      fields[5] as int,
      fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AutonPoints obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.CoralScoringLevel1)
      ..writeByte(1)
      ..write(obj.CoralScoringLevel2)
      ..writeByte(2)
      ..write(obj.CoralScoringLevel3)
      ..writeByte(3)
      ..write(obj.CoralScoringLevel4)
      ..writeByte(4)
      ..write(obj.LeftBarge)
      ..writeByte(5)
      ..write(obj.AlgaeScoringProcessor)
      ..writeByte(6)
      ..write(obj.AlgaeScoringBarge);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AutonPointsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
