import 'package:bonfire/bonfire.dart';
import 'package:flutter/widgets.dart';

import 'emberBuilder.dart';

class WorldMapByEmber extends WorldMap {
  late EmberWorldBuilder _builder;
  WorldMapByEmber(
    String path, {
    Vector2? forceTileSize,
    ValueChanged<Object>? onError,
    double tileSizeToUpdate = 0,
    Map<String, ObjectBuilder>? objectsBuilder,
    int level = 0,
  }) : super(const []) {
    this.tileSizeToUpdate = tileSizeToUpdate;
    _builder = EmberWorldBuilder(
      path,
      forceTileSize: forceTileSize,
      onError: onError,
      tileSizeToUpdate: tileSizeToUpdate,
      objectsBuilder: objectsBuilder,
      level: level
    );
  }

  @override
  Future<void>? onLoad() async {
    final map = await _builder.build();
    tiles = map.map.tiles;
    gameRef.addAll(map.components ?? []);
    return super.onLoad();
  }
}
