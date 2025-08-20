import React from 'react';
import {
  Text,
  View,
  StyleSheet,
  Image,
  TouchableOpacity,
  ScrollView,
} from 'react-native';
import { getColorPalette, type ColorPalette } from 'react-native-dominant-color';

const IMAGES: string[] = [
  'https://images.unsplash.com/photo-1503023345310-bd7c1de61c7d?q=80&w=1200&auto=format&fit=crop',
  'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?q=80&w=1200&auto=format&fit=crop',
  'https://images.unsplash.com/photo-1505935428862-770b6f24f629?q=80&w=1200&auto=format&fit=crop',
  'https://images.unsplash.com/photo-1520975682031-a7120f6c4f54?q=80&w=1200&auto=format&fit=crop',
  'https://images.unsplash.com/photo-1517331156700-3c241d2b4d83?q=80&w=1200&auto=format&fit=crop',
  'https://images.unsplash.com/photo-1482192596544-9eb780fc7f66?q=80&w=1200&auto=format&fit=crop',
];

function pickRandomIndex(): number {
  return Math.floor(Math.random() * IMAGES.length);
}

export default function App() {
  const [index, setIndex] = React.useState<number>(pickRandomIndex());
  const [palette, setPalette] = React.useState<ColorPalette | null>(null);

  const uri = IMAGES[index];

  const extract = React.useCallback(() => {
    try {
      const result = getColorPalette(uri);
      setPalette(result);
    } catch (e) {
      console.warn('Failed to get palette', e);
      setPalette(null);
    }
  }, [uri]);

  React.useEffect(() => {
    extract();
  }, [extract]);

  return (
    <View style={styles.container}>
      <Text style={styles.title}>react-native-dominant-color</Text>
      <Image source={{ uri }} style={styles.image} resizeMode="cover" />

      <TouchableOpacity
        onPress={() => setIndex(pickRandomIndex())}
        style={styles.button}
        activeOpacity={0.8}
      >
        <Text style={styles.buttonText}>Random image</Text>
      </TouchableOpacity>

      <ScrollView style={styles.paletteContainer} contentContainerStyle={styles.paletteContent}>
        <Text style={styles.subtitle}>Palette</Text>
        {palette ? (
          <View style={styles.colorsRow}>
            {(['background', 'primary', 'secondary', 'detail'] as const).map((k) => (
              <View key={k} style={styles.colorItem}>
                <View style={[styles.colorSwatch, { backgroundColor: palette[k] }]} />
                <Text style={styles.colorLabel}>{k}</Text>
                <Text style={styles.colorHex}>{palette[k]}</Text>
              </View>
            ))}
          </View>
        ) : (
          <Text style={styles.placeholder}>No palette</Text>
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingTop: 64,
    paddingHorizontal: 16,
    backgroundColor: '#0F1115',
  },
  title: {
    fontSize: 18,
    fontWeight: '600',
    color: '#fff',
    marginBottom: 12,
    textAlign: 'center',
  },
  image: {
    width: '100%',
    height: 240,
    borderRadius: 12,
    backgroundColor: '#111',
  },
  button: {
    marginTop: 16,
    alignSelf: 'center',
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 8,
    backgroundColor: '#2563eb',
  },
  buttonText: {
    color: '#fff',
    fontWeight: '600',
  },
  paletteContainer: {
    marginTop: 24,
  },
  paletteContent: {
    paddingBottom: 48,
  },
  subtitle: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 12,
  },
  colorsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  colorItem: {
    flex: 1,
    alignItems: 'center',
  },
  colorSwatch: {
    width: 60,
    height: 60,
    borderRadius: 8,
    marginBottom: 8,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: '#fff3',
  },
  colorLabel: {
    color: '#fff',
    fontSize: 12,
  },
  colorHex: {
    color: '#9ca3af',
    fontSize: 12,
  },
  placeholder: {
    color: '#9ca3af',
  },
});
