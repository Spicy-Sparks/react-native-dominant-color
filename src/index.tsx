import DominantColor, { type ColorPalette } from './NativeDominantColor';

export function getColorPalette(
  imagePath: string
): Promise<ColorPalette | null> {
  return DominantColor.getColorPalette(imagePath);
}
