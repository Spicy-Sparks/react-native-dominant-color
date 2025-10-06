import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export type ColorPalette = {
  platform: 'ios' | 'android';
  background: string;
  primary: string;
  secondary: string;
  detail: string;
};

export interface Spec extends TurboModule {
  getColorPalette(imagePath: string): Promise<ColorPalette | null>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('DominantColor');
