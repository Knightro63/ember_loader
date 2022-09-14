import 'package:flutter/material.dart' hide Image;
import 'package:vector_math/vector_math_64.dart' hide Triangle hide Colors;

enum ObjectType{landscape,charcter,item}
enum SelectedType{Rect,Image,Tile,Collision,Atlas,Animation,Object}

class TileImage{
  TileImage({
    required this.height,
    required this.width,
    this.name = '',
    this.path = '',
    this.collisions
  });

  int height;
  int width;
  String name;
  String path;
  List<Rect>? collisions;
}
class Object {
  Object({
    Vector2? position,
    required this.atlasPosition,
    this.rotate = 0,
    Vector3? scale,
    Vector2? size,
    this.name = 'Object',
    this.visible = true,
    this.imageLocation = 0,
    this.type = SelectedType.Image,
    this.layer = 1,
    this.color = Colors.white
  }){
    this.position = position ?? Vector2(0.0, 0.0);
    this.size = size ?? Vector2(50,50);
    this.scale = scale ?? Vector3(1,1,1);
  }

  late Vector2 position;
  Rect atlasPosition;
  double rotate;
  bool visible;
  String name;
  Color color;
  late Vector2 size;
  late Vector3 scale;
  double get width => size.x;
  double get height => size.y;
  //Image image;
  int imageLocation;
  SelectedType type;
  int layer;
}
class TileAnimations{
  TileAnimations({
    this.tileSet = 0,
    this.rects = const [],
    this.timing = 0.4,
    this.useFrame = 0
  });

  double timing;
  int tileSet;
  List<Rect> rects;
  int useFrame;
}
class TileRects{
  TileRects({
    this.tileSet = 0,
    this.column,
    this.isAnimation = false,
    this.useAnimation = 0,
    this.position,
    this.transform,
    this.rect
  });

  int? row;
  int? column;
  int tileSet;
  Rect? rect;
  bool isAnimation;
  int useAnimation;
  //bool hasCollisions;
  List<int>? position;
  RSTransform? transform;
}
class TileLayers{
  TileLayers({
    this.visible = true,
    this.tiles = const [],
    this.width,
    required this.length,
    String? name
  }){
    this.name = name ?? 'Layer';
    //tiles = this.tiles!=null?this.tiles:List<TileRects>.filled(length, TileRects(),growable: true);
  }

  bool visible;
  late String name;
  int? width;
  int length;
  List<TileRects> tiles;
}
class ObjectImages{
  ObjectImages({
    required this.size,
    this.objectScale,
    this.objectType = ObjectType.landscape,
    this.path = '',
    this.spriteLocations,
    this.spriteNames,
    this.show = true,
    this.offsetHeight = 0
  });

  Size size;
  double offsetHeight;
  String path;
  ObjectType objectType;
  List<Rect>? spriteLocations;
  List<String>? spriteNames;
  bool show;
  List<double>? objectScale;
}

class EmberMap{
  String? name;
  List<TileImage> tileSets = [];
  List<TileAnimations> animations = [];
  List<Object> objects = [];
  List<Object> collisions = [];
  List<Object> landScapes = []; 
  List<TileLayers> layers = [];
  List<ObjectImages> objectImages = [];
  
  int height = 0;
  int width = 0;
  int tileHeight = 0;
  int tileWidth = 0;

  EmberMap({
    this.height = 0,
    this.layers = const [],
    this.tileSets = const [],
    this.objectImages = const [],
    this.animations = const [],
    this.objects = const [],
    this.landScapes = const [],
    this.collisions = const [],
    this.tileHeight = 0,
    this.tileWidth = 0,
    this.width = 0,
    this.name,
  });

  static List<TileAnimations> _getAnimations(dynamic animationList){
    List<TileAnimations> animations = [];
    if(animationList != null){
      for(String animation in animationList.keys){
        List<Rect> rects = [];
        for(String rect in animationList[animation]['rects'].keys){
          rects.add(
            Rect.fromLTWH(
              animationList[animation]['rects'][rect]['x'], 
              animationList[animation]['rects'][rect]['y'], 
              animationList[animation]['rects'][rect]['w'], 
              animationList[animation]['rects'][rect]['h']
            )
          );
        }
        animations.add(
          TileAnimations(
            tileSet: animationList[animation]['set'],
            rects: rects,
            timing: animationList[animation]['timing'],
          )
        );
      }
    }

    return animations;
  }
  static List<TileLayers> _getTileLayers(dynamic layerList){
    List<TileLayers> layers = [];
    if(layerList != null){
      for(String layer in layerList.keys){
        int length = layerList[layer]['length'];
        List<TileRects> tiles = [];
        if(layerList[layer]['tiles'] != null){
          for(String tile in layerList[layer]['tiles'].keys){
            dynamic temp = layerList[layer]['tiles'][tile]['position'];
            List<int> positon = [];

            if(temp.isNotEmpty){
              positon = [temp[0],temp[1]];
            }

            tiles.add(TileRects(//[layerList[layer]['tiles'][tile]['location']]
              tileSet: layerList[layer]['tiles'][tile]['set'],
              isAnimation: layerList[layer]['tiles'][tile]['isAnimation'],
              useAnimation: layerList[layer]['tiles'][tile]['useAnimation'],
              rect: Rect.fromLTWH(
                layerList[layer]['tiles'][tile]['rect']['x'], 
                layerList[layer]['tiles'][tile]['rect']['y'], 
                layerList[layer]['tiles'][tile]['rect']['w'], 
                layerList[layer]['tiles'][tile]['rect']['h']
              ),
              position: positon,
              transform: RSTransform(
                layerList[layer]['tiles'][tile]['transform']['scos'], 
                layerList[layer]['tiles'][tile]['transform']['ssin'], 
                layerList[layer]['tiles'][tile]['transform']['tx'], 
                layerList[layer]['tiles'][tile]['transform']['ty']
              )
            ));
          }
        }
        layers.add(
          TileLayers(
            name: layerList['name'],
            length: length,
            tiles: tiles,
          )
        );
      }
    }

    return layers;
  }
  void _setObjects(dynamic objectList){
    List<Object> _objects = [];
    List<Object> _collisions = [];
    List<Object> _landScapes = []; 

    if(objectList != null){
      for(String object in objectList.keys){

        Rect atlas = Rect.zero;
        Vector2 size = Vector2(
          objectList[object]['size']['w'],
          objectList[object]['size']['h']
        );
        Vector3 scale = Vector3(
          objectList[object]['scale']['x'],
          objectList[object]['scale']['y'],
          objectList[object]['scale']['z'],
        );
        Vector2 position = Vector2(
          objectList[object]['position']['x'],
          objectList[object]['position']['y'],
        );
        if(objectList[object]['atlas'] != null){
          atlas = Rect.fromLTWH(
            objectList[object]['atlas']['x'], 
            objectList[object]['atlas']['y'], 
            objectList[object]['atlas']['w'], 
            objectList[object]['atlas']['h']
          );
        }
        if(SelectedType.values[objectList[object]['type']] == SelectedType.Collision){
          _collisions.add(
            Object(
              position: position,
              atlasPosition: atlas,
              rotate: objectList[object]['rotate'] ?? objectList[object]['rotation']['z'],
              size: size,
              scale: scale,
              name: objectList[object]['name'],
              layer: objectList[object]['layer'],
              imageLocation: objectList[object]['image'],
              type: SelectedType.values[objectList[object]['type']],
              color: Color(objectList[object]['color'])
            )
          );
        }
        else{
          if(objectImages[objectList[object]['image']].objectType == ObjectType.landscape){
            _landScapes.add(
              Object(
                position: position,
                atlasPosition: atlas,
                rotate: objectList[object]['rotate'] ?? objectList[object]['rotation']['z'],
                size: size,
                scale: scale,
                name: objectList[object]['name'],
                layer: objectList[object]['layer'],
                imageLocation: objectList[object]['image'],
                type: SelectedType.values[objectList[object]['type']],
                color: Color(objectList[object]['color'])
              )
            );
          }
          else{
            if(objectList[object]['name'] != 'Main' && objectList[object]['name'] != "Player"){
              _objects.add(
                Object(
                  position: position,
                  atlasPosition: atlas,
                  rotate: objectList[object]['rotate'] ?? objectList[object]['rotation']['y'],
                  size: size,
                  scale: scale,
                  name: objectList[object]['name'],
                  layer: objectList[object]['layer'],
                  imageLocation: objectList[object]['image'],
                  type: SelectedType.values[objectList[object]['type']],
                  color: Color(objectList[object]['color'])
                )
              );
            }
          }
        }
      }
    }

    collisions = _collisions;
    landScapes = _landScapes;
    objects = _objects;
  }

  EmberMap.fromJSON(dynamic convert){
    _convert(convert, 'json');
  }
  EmberMap.fromEmber(dynamic convert, int level){
    _convert(convert, 'spark', level);
  }
  void _convert(dynamic convert, String type, [int level = 0]){
    double offsetHeight = 0;
    void getLevel(dynamic levelData){
      if(levelData['tileLayer'] != null){
        layers = _getTileLayers(levelData['tileLayer']);
      }
      name = levelData['name'];
      if(levelData['animations'] != null){
        animations = _getAnimations(levelData['animations']);
      }
      tileHeight = levelData['grid']['height'].toInt();
      tileWidth = levelData['grid']['width'].toInt();
      width = levelData['grid']['x']*tileWidth;
      height = levelData['grid']['y']*tileHeight;
      if(levelData['objects'] != null){
        _setObjects(levelData['objects']);
      }
    }

    for(String keys in convert.keys){
      switch (keys) {
        case 'tileSets':
        if(convert[keys] == null) break;
          List<TileImage> _tileSets = [];
          for(String set in convert[keys].keys){
            _tileSets.add(TileImage(
              height: convert[keys][set]['size']['h'].toInt(),
              width: convert[keys][set]['size']['w'].toInt(),
              name: convert[keys][set]['name'],
              path: convert[keys][set]['image']
            ));
          }
          tileSets = _tileSets;
          break;
        case 'loadedObjects':
          if(convert[keys] == null) break;
          List<ObjectImages> objs = [];
          for(String set in convert[keys].keys){
            List<Rect> locations = [];
            List<String> names = [];
            List<double> scales = [];

            if(convert[keys][set]['objectScale'] != null){
              List<dynamic> temp = convert[keys][set]['objectScale'];
              for(int i = 0; i < temp.length; i++){
                scales.add(double.parse(temp[i].toString()));
              }
            }
            else{
              scales = [];
            }

            if(convert[keys][set]['spriteNames'] != null){
              List<dynamic> temp = convert[keys][set]['spriteNames'];
              for(int i = 0; i < temp.length; i++){
                names.add(temp[i].toString());
              }
            }
            else{
              names = [];
            }

            if(convert[keys][set]['spriteLocations'] != null){
              for(String location in convert[keys][set]['spriteLocations'].keys){
                locations.add(
                  Rect.fromLTWH(
                    convert[keys][set]['spriteLocations'][location]['x'], 
                    convert[keys][set]['spriteLocations'][location]['y'], 
                    convert[keys][set]['spriteLocations'][location]['w'], 
                    convert[keys][set]['spriteLocations'][location]['h']
                  )
                );
              }
            }
            objs.add(ObjectImages(
              objectType: ObjectType.values[convert[keys][set]['objectType']],
              size: Size(convert[keys][set]['size']['w'],convert[keys][set]['size']['h']),
              objectScale: scales,
              spriteLocations: locations,
              show: convert[keys][set]['visible'],
              spriteNames: names,
              path: convert[keys][set]['image'],
              offsetHeight: offsetHeight
            ));
            offsetHeight += convert[keys][set]['size']['h'];
          }
          objectImages = objs;
          break;
        case 'levels':
          getLevel(convert[keys]['level_$level']);
          break;
        case 'level':
          getLevel(convert[keys]);
          break;
        default:
      }
    }
  }

   dynamic toJSON(){

  }
}