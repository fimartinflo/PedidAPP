import 'package:flutter_test/flutter_test.dart';
import 'package:pedidapp/models/category.dart';

void main() {
  group('Category', () {
    test('constructor sets default values', () {
      final cat = Category(id: 'c1', name: 'Test');
      expect(cat.icon, 'category');
      expect(cat.color, '#4CAF50');
      expect(cat.sortOrder, 0);
    });

    group('serialization', () {
      test('toMap produces correct map', () {
        final cat = Category(
          id: 'cat_1',
          name: 'Alimentos',
          icon: 'restaurant',
          color: '#FF9800',
          sortOrder: 0,
        );
        final map = cat.toMap();
        expect(map['id'], 'cat_1');
        expect(map['name'], 'Alimentos');
        expect(map['icon'], 'restaurant');
        expect(map['color'], '#FF9800');
        expect(map['sortOrder'], 0);
      });

      test('fromMap roundtrips correctly', () {
        final cat = Category(
          id: 'cat_1',
          name: 'Bebidas',
          icon: 'local_drink',
          color: '#2196F3',
          sortOrder: 1,
        );
        final restored = Category.fromMap(cat.toMap());
        expect(restored.id, cat.id);
        expect(restored.name, cat.name);
        expect(restored.icon, cat.icon);
        expect(restored.color, cat.color);
        expect(restored.sortOrder, cat.sortOrder);
      });

      test('fromMap handles null optional fields', () {
        final map = {'id': 'x', 'name': 'Test'};
        final cat = Category.fromMap(map);
        expect(cat.icon, 'category');
        expect(cat.color, '#4CAF50');
        expect(cat.sortOrder, 0);
      });
    });

    group('copyWith', () {
      test('updates specified fields', () {
        final cat = Category(id: 'c1', name: 'Old');
        final copy = cat.copyWith(name: 'New', color: '#000000');
        expect(copy.name, 'New');
        expect(copy.color, '#000000');
        expect(copy.id, 'c1');
        expect(copy.icon, cat.icon);
      });
    });

    test('defaultCategories returns 10 categories', () {
      final defaults = Category.defaultCategories();
      expect(defaults.length, 10);
      expect(defaults.first.name, 'Alimentos');
      expect(defaults.last.name, 'Otros');
    });
  });
}
