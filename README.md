## react-native-dominant-color

Get a color palette (background, primary, secondary, detail) from an image on iOS and Android.

### Installation

1) Add the dependency

```bash
yarn add react-native-dominant-color
# or
npm i react-native-dominant-color
```

2) iOS

```bash
cd ios && pod install && cd -
```

### API

```ts
import { getColorPalette } from 'react-native-dominant-color';

type ColorPalette = {
  platform: 'ios' | 'android';
  background: string;
  primary: string;
  secondary: string;
  detail: string;
};

const palette = getColorPalette('https://example.com/image.jpg');
// => { platform: 'ios', background: '#112233', primary: '#aabbcc', ... }
```

The input can be:
- Remote URL (http/https)
- Local file path or file:// URL
- Data URI (data:image/...;base64,...) 
- Bundle image name (require()-ed assets)

### Example app

The example app shows a random Unsplash image and its extracted palette with a button to shuffle.

Run it:

```bash
yarn
yarn example ios   # or: yarn example android
```

Open `example/src/App.tsx` to see how it works.

### License

MIT
