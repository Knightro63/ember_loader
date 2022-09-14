# ember_loader

A Flutter plugin designed for bonfire and ember to allow users to load their creations into the world.

## Getting started

To get started with ember_loader add the package and some assets that work in you game to your pubspec.yaml file.

## Usage

This project loads .ember or .json files made from ember to your bonfire map. 

### BonfireWidget
Add the below code to your bonfire map to get started.

```dart
WorldMapByEmber(
    'levels/test.ember',
    forceTileSize: Vector2(AdventureMap.tileSize, AdventureMap.tileSize),
    objectsBuilder: {
        'Save Point': (properties) => SavePoint(properties.position),
        'Obejct1': (properties) => Object1(properties.position),
        'Object2': (properties) => Object2(properties.position),
        'Object3': (properties) => Object3(properties.position),
    },
)
```

## Contributing

Feel free to propose changes by creating a pull request.

## Additional Information

This plugin is made to be used with bonfire and ember to load levels into the bonfire map.
