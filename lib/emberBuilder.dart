import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:bonfire/bonfire.dart';
import 'package:bonfire/tiled/model/tiled_world_data.dart';
import 'package:bonfire/util/collision_game_component.dart';
import 'package:http/http.dart' as http;

import 'package:bonfire/tiled/model/tiled_data_object_collision.dart';
import 'package:bonfire/tiled/model/tiled_item_tile_set.dart';
import 'package:bonfire/tiled/model/tiled_object_properties.dart';

import 'emberReader.dart';

typedef ObjectBuilder = GameComponent Function(TiledObjectProperties properties);

class EmberWorldBuilder extends WorldMap{
  static const TYPE_TILE_ABOVE = 'above';

  final String path;
  final int level;
  final Vector2? forceTileSize;
  final double tileSizeToUpdate;
  late EmberReader _reader;
  late EmberMap _tiledMap;
  List<TileModel> _tiles = [];
  List<GameComponent> _components = [];
  String? _basePath;
  String _basePathFlame = 'assets/images/';
  double _tileWidth = 0;
  double _tileHeight = 0;
  double _tileWidthOrigin = 0;
  double _tileHeightOrigin = 0;
  bool fromServer = false;
  Map<String, Sprite> _spriteCache = Map();
  final ValueChanged<String>? onError;
  Map<String, ObjectBuilder> _objectsBuilder = Map();
  Offset _cameraOffset = Offset(75,45);

  EmberWorldBuilder(
    this.path,{
      this.forceTileSize,
      this.tileSizeToUpdate = 0,
      this.onError,
      this.level = 0,
      Map<String, ObjectBuilder>? objectsBuilder,
    }):super(const []){
    _objectsBuilder = objectsBuilder ?? Map();
    _basePath = path.replaceAll(path.split('/').last, '');
    fromServer = path.contains('http');
    _reader = EmberReader(_basePathFlame + path, level);
  }

  void registerObject(String name, ObjectBuilder builder) {
    _objectsBuilder[name] = builder;
  }

  Future<TiledWorldData> build() async {
    //try {
      _tiledMap = await _readMap();
      _tileWidthOrigin = _tiledMap.tileWidth.toDouble();
      _tileHeightOrigin = _tiledMap.tileHeight.toDouble();
      _tileWidth = forceTileSize?.x ?? _tileWidthOrigin;
      _tileHeight = forceTileSize?.y ?? _tileHeightOrigin;
      await _load(_tiledMap);


    return Future.value(
      TiledWorldData(
        map: WorldMap(
          _tiles,
          tileSizeToUpdate: tileSizeToUpdate
        ),
        components: _components,
      )
    );
  }

  Future<void> _load(EmberMap tiledMap) async{
    if(tiledMap.layers.isNotEmpty){
      tiledMap.layers.forEach((TileLayers layer) async{
        await _addTileLayer(layer);
      });
    }else{
      _addTile(
        TiledItemTileSet(
          sprite: TileModelSprite(
            path: '',
            size: Vector2(1,1),
          ),
          collisions: TiledDataObjectCollision().collisions,
          type: '',
          properties: {}
        ),
        Vector2(0,0),
        Vector2(_tiledMap.width.toDouble(),_tiledMap.height.toDouble())
      );
    }
    if(tiledMap.collisions.isNotEmpty){
      tiledMap.collisions.forEach((Object collider) async{
        await _addCollisions(collider);
      });
    }
    if(tiledMap.objects.isNotEmpty){
      tiledMap.objects.forEach((Object object) async{
        await _addObjects(object);
      });
    }
    if(tiledMap.landScapes.isNotEmpty){
      tiledMap.landScapes.forEach((Object decoration) async{
        await _addDecorations(decoration);
      });
    }
  }

  Future<void> _addTileLayer(TileLayers tileLayer) async{
    if (!tileLayer.visible) return;
    if(tileLayer.tiles.isEmpty){
      _addTile(
        TiledItemTileSet(
          sprite: TileModelSprite(
            path: 'Areas/Beach/Beach_Ground.png',
            size: Vector2(1,1),
          ),
          collisions: TiledDataObjectCollision().collisions,
          type: '',
          properties: {}
        ),
        Vector2(0,0),
        Vector2(_tiledMap.width.toDouble(),_tiledMap.height.toDouble())
      );
    }
    else{
      tileLayer.tiles.forEach((TileRects tile) {
        if (tile.rect != null) {
          TiledItemTileSet? data = _getDataTile(tile);
          if (data != null) {
            _addTile(data,Vector2(tile.rect!.left,tile.rect!.top));
          }
        }
      });
    }
  }
  Future<void> _addTile(
    TiledItemTileSet data,
    Vector2 position,
    [Vector2? size]
  ) async{
    _tiles.add(
      TileModel(
        x: position.x,
        y: position.y,
        offsetX: 0,
        offsetY: 0,
        collisions: data.collisions,
        height: size != null?size.y:_tileHeight,
        width: size != null?size.x:_tileWidth,
        animation: data.animation,
        sprite: data.sprite,
        properties: data.properties,
        type: data.type,
        angle: 0,
        isFlipVertical: false,
        isFlipHorizontal: false,
      ),
    );
  }

  TiledItemTileSet? _getDataTile(TileRects rect) {
    int set = rect.tileSet;
    int ani = rect.useAnimation;
    TileImage tileSetContain = _tiledMap.tileSets[set];
    final int widthCount = tileSetContain.width ~/ tileSetContain.width;

    final animation = rect.isAnimation? _getAnimation(
      _tiledMap.animations[ani],
      ani,
      widthCount,
    ):null;

    TiledDataObjectCollision object = _getCollision(
      tileSetContain,
      0//fixthis
    );

      TiledItemTileSet(
        animation: animation,
        sprite: TileModelSprite(
          path: '$_basePath${tileSetContain.path}',
          size: Vector2(rect.rect!.width,rect.rect!.height),
        ),
        type: object.type,
        collisions: object.collisions,
    );
  }

  Future<void> _addObjects(Object object) async{
    if (!object.visible) return;
    if (_objectsBuilder[object.name] != null) {
      double x = ((object.position.x*100 * _tileWidth) / _tileWidthOrigin)+_cameraOffset.dx;
      double y = ((object.position.y*-100 * _tileHeight) / _tileHeightOrigin)+_cameraOffset.dy;
      double width = (object.width * _tileWidth) / _tileWidthOrigin*object.scale.y*100;
      double height = (object.height * _tileHeight) / _tileHeightOrigin*object.scale.y*100;

      final obj = _objectsBuilder[object.name]?.call(
        TiledObjectProperties(
          Vector2(x, y),
          Vector2(width, height),
          object.type.toString(),
          object.rotate*pi/180,
          {},
          object.name,
          object.imageLocation,
        )
      );

      _components.add(obj!);
    }
  }
  Vector2 _getPoint(Offset point, Offset center, double angle){
    //TRANSLATE TO ORIGIN
    double x = point.dx - center.dx;
    double y = point.dy - center.dy;

    //APPLY ROTATION
    double newX = x * cos(angle) - y * sin(angle);
    double newY = x * sin(angle) + y * cos(angle);

    //TRANSLATE BACK
    return Vector2(newX + center.dx, newY + center.dy);
  }
  Future<void> _addCollisions(Object object) async{
    if (!object.visible) return;
    double width = ((object.width * _tileWidth) / _tileWidthOrigin).abs()*object.scale.x*100;
    double height = ((object.height * _tileHeight) / _tileHeightOrigin).abs()*object.scale.y*100;
    double x = ((object.position.x*100 * _tileWidth) / _tileWidthOrigin)+_cameraOffset.dx;
    double y = ((object.position.y*-100 * _tileHeight) / _tileHeightOrigin)+_cameraOffset.dy;

    List<CollisionArea> collider = [CollisionArea.rectangle(size: Vector2(width,height))];
    double angle = object.rotate*pi/180;

    if(object.rotate != 0){
      Offset center = const Offset(0,0);
      //double h = cos(angle)*width/6;
      y = ((object.position.y*-100 * _tileHeight) / _tileHeightOrigin)+_cameraOffset.dy;
      Vector2 topLeft = _getPoint(const Offset(0,0),center, angle);
      Vector2 topRight = _getPoint(Offset(width,0),center, angle);
      Vector2 bottomRight = _getPoint(Offset(width,height),center, angle);
      Vector2 bottomLeft = _getPoint(Offset(0,height),center, angle);
      
      collider = [CollisionArea.polygon(
        points:[
          topLeft,
          topRight,
          bottomRight,
          bottomLeft,
      ])];
    }
    
    _components.add(
      CollisionGameComponent(
        position: Vector2(x,y),
        size: Vector2(width,height),
        collisions: collider,
        properties: {
          'angle': angle,
          'collider': true
        }
      )
      ..aboveComponents = true
    );
  }
  Future<void> _addDecorations(Object object) async{
    if (!object.visible) return;
    int loc = object.imageLocation;
    double x = ((object.position.x*100 * _tileWidth) / _tileWidthOrigin)+_cameraOffset.dx;
    double y = ((object.position.y*-100 * _tileHeight) / _tileHeightOrigin)+_cameraOffset.dy;
    double width = ((object.width * _tileWidth) / _tileWidthOrigin).abs()*object.scale.x*100;
    double height = ((object.height * _tileHeight) / _tileHeightOrigin).abs()*object.scale.y*100;
    bool flipX = false;
    bool flipY = false;

    if(object.scale.y < 0){
      flipY = true;
      y = ((object.position.y*-100 * _tileHeight) / _tileHeightOrigin)+_cameraOffset.dy;
      height = ((object.height * _tileHeight) / _tileHeightOrigin).abs()*object.scale.y*-100;
    }
    if(object.scale.x < 0){
      flipX = true;
      width = ((object.width * _tileWidth) / _tileWidthOrigin).abs()*object.scale.x*-100;
      x = (((object.position.x)*100 * _tileWidth) / _tileWidthOrigin)+75-width;
    }

    if(object.type == SelectedType.Object){
      _components.add(
        BackGround(
          size: Vector2(width,height),
          position: Vector2(x,y),
          layer: object.layer,
          color: object.color,
        )
        ..angle = object.rotate*pi/180
        ..isFlipHorizontal = flipX
        ..isFlipVertical = flipY
      );
    }
    else{
      _components.add(
        LandScape(
          sprite: Sprite.load(
            _tiledMap.objectImages[loc].path,
            srcPosition: Vector2(object.atlasPosition.left, object.atlasPosition.top-_tiledMap.objectImages[loc].offsetHeight),
            srcSize: Vector2(object.atlasPosition.width,object.atlasPosition.height)
          ), 
          size: Vector2(width,height),
          position: Vector2(x,y),
          layer: object.layer
        )
        ..angle = object.rotate*pi/180
        ..isFlipHorizontal = flipX
        ..isFlipVertical = flipY
      );
    }
  }

  TiledDataObjectCollision _getCollision(TileImage tileSetContain, int index) {
    List<CollisionArea> collisions = [];
    if (tileSetContain.collisions != null) {
      tileSetContain.collisions!.forEach((collider) {
        double width = (collider.width * _tileWidth) / _tileWidthOrigin;
        double height = (collider.height * _tileHeight) / _tileHeightOrigin;

        double x = (collider.left * _tileWidth) / _tileWidthOrigin;
        double y = (collider.top * _tileHeight) / _tileHeightOrigin;

        collisions.add(CollisionArea.rectangle(size: Vector2(width,height),align: Vector2(x, y)));
      });
      return TiledDataObjectCollision(collisions: collisions, type: '',);
    }
    return TiledDataObjectCollision();
  }

  TileModelAnimation? _getAnimation(
    TileAnimations animation,
    int index,
    int widthCount,
  ) {
    try {
      int set = animation.tileSet;
      TileImage tileSetContain = _tiledMap.tileSets[set];

      if(animation.rects.isNotEmpty) {
        List<TileModelSprite> frames = [];
        double stepTime = animation.timing;

        animation.rects.forEach((Rect rect){
          final spritePath = '$_basePath${tileSetContain.path}';
          TileModelSprite sprite = TileModelSprite(
            path: spritePath,
            size: Vector2(rect.width,rect.height),
          );
          frames.add(sprite);
          // Sprite sprite = await _getSprite(
          //   '$_basePath${tileSetContain.path}',
          //   rect.left,
          //   rect.top,
          //   rect.width,
          //   rect.height,
          // );
        });

        return TileModelAnimation(
          stepTime: stepTime,
          frames: frames,
        );
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<EmberMap> _readMap() async {
    if (fromServer) {
      try {
        EmberMap tiledMap;
        final mapResponse = await http.get(Uri.parse(path));
        tiledMap = EmberMap.fromJSON(jsonDecode(mapResponse.body));
        return Future.value(tiledMap);
      } catch (e) {
        print('(TiledWorldMap) Error: $e');
        return Future.value(EmberMap());
      }
    } 
    else {
      return _reader.read(level);
    }
  }
}

//UseSpriteAnimation, Vision, UseSprite, UseAssetsLoader
class LandScape extends GameComponent with UseAssetsLoader, UseSprite{
  LandScape({
    required Vector2 position, 
    required Vector2 size, 
    required FutureOr<Sprite> sprite, 
    this.layer = 0
  }){
    loader?.add(AssetToLoad(sprite, (value) => this.sprite = value));
    applyBleedingPixel(position: position, size: size);
  }

  int layer;

  @override
  int get priority => LayerPriority.BACKGROUND+layer+5;
}

//UseSpriteAnimation, Vision, UseSprite, UseAssetsLoader
class BackGround extends GameComponent{
  BackGround({
    required Vector2 position, 
    required Vector2 size, 
    required this.color, 
    this.layer = 0
  }){
    applyBleedingPixel(position: position, size: size);
  }

  int layer;
  Color color;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(position.x, position.y, size.x, size.y),paint);
  }

  @override
  int get priority => LayerPriority.BACKGROUND+layer+5;
}