import DominantColor, { type ColorPalette } from './NativeDominantColor';

export function getColorPalette(imagePath: string): ColorPalette | null {
  return DominantColor.getColorPalette(imagePath);
}
