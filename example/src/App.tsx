import { useState } from 'react';
import {
  View,
  StyleSheet,
  Text,
  SafeAreaView,
  ScrollView,
  Dimensions,
} from 'react-native';
import { MediaView } from 'react-native-media-view';

const { width: screenWidth } = Dimensions.get('window');

const sampleVideo = require('./assets/sample.mp4');

export default function App() {
  const [error, setError] = useState<string | null>(null);
  const handleLoad = () => {
    setError(null);
    console.log('AVIF loaded');
  };

  const handleError = (event: any) => {
    const { error: errorMessage } = event.nativeEvent;
    setError(errorMessage);
    console.error('AVIF error:', errorMessage);
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <Text style={styles.title}>React Native Media Viewer</Text>

        {/* Image Display */}
        <View style={styles.imageContainer}>
          <MediaView
            style={styles.mediaImage}
            source={sampleVideo}
            resizeMode="contain"
            onLoad={handleLoad}
            onError={handleError}
          />
          {error && <Text style={styles.errorText}>{error}</Text>}
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollContent: {
    alignItems: 'center',
    padding: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
  },
  imageContainer: {
    width: screenWidth - 40,
    height: screenWidth - 40,
    backgroundColor: '#eee',
    borderRadius: 12,
    justifyContent: 'center',
    alignItems: 'center',
    overflow: 'hidden',
    marginBottom: 20,
  },
  mediaImage: {
    width: '100%',
    height: '100%',
  },
  errorText: {
    position: 'absolute',
    color: '#ff6b6b',
    fontSize: 14,
    textAlign: 'center',
    padding: 10,
  },
  controlContainer: {
    marginBottom: 20,
  },
  button: {
    backgroundColor: '#4a69bd',
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 8,
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  sectionTitle: {
    color: '#fff',
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 12,
  },
  infoContainer: {
    backgroundColor: '#16213e',
    borderRadius: 8,
    padding: 12,
    width: '100%',
  },
  infoText: {
    color: '#a0a0a0',
    fontSize: 14,
    marginBottom: 4,
  },
});
