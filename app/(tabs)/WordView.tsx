import { Auth } from "@/components/auth/Auth.apple";
import { ThemedText } from "@/components/ThemedText";
import WordCard from "@/components/WordCard";
import SupabaseService from "@/services/supabase";
import { useEffect, useState } from "react";
import { View, StyleSheet, ScrollView, ActivityIndicator, RefreshControl, Vibration, Modal, TouchableOpacity } from "react-native";
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { WebView } from 'react-native-webview';
import { Ionicons } from '@expo/vector-icons';

export default function WordView() {
  // Use try-catch to handle potential errors with safe area hooks
  let topInset = 0;
  try {
    const insets = useSafeAreaInsets();
    topInset = insets.top;
  } catch (e) {
    console.warn("Safe area context not available");
  }

  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [wordIds, setWordIds] = useState<number[]>([]);
  const [error, setError] = useState<string | null>(null);

  // New state for dictionary modal
  const [dictionaryModalVisible, setDictionaryModalVisible] = useState(false);
  const [selectedWord, setSelectedWord] = useState<string>("");

  const loadWords = async () => {
    try {
      setError(null);
      await SupabaseService.fetchUserWords();
      const userWords = SupabaseService.userWords;
      const ids = Object.keys(userWords).map(id => parseInt(id));
      setWordIds(ids);
    } catch (error) {
      setError('Failed to load words. Pull down to retry.');
      console.error("Error loading words:", error);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const onRefresh = async () => {
    setRefreshing(true);
    Vibration.vibrate(50); // Short vibration feedback
    await loadWords();
  };

  useEffect(() => {
    loadWords();
  }, []);

  // Handler for opening the dictionary
  const handleOpenDictionary = (word: string) => {
    setSelectedWord(word);
    setDictionaryModalVisible(true);
  };

  if (loading) {
    return (
      <View style={[styles.container, { paddingTop: topInset }]}>
        <ActivityIndicator size="large" color="#4CAF50" />
      </View>
    );
  }

  return (
    <View style={[styles.container, { paddingTop: topInset }]}>
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={[
          styles.scrollContent,
          !wordIds.length && styles.centerContent
        ]}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={onRefresh}
            tintColor="#FFFFFF"
            colors={["#4CAF50"]}
            progressBackgroundColor="#242424"
            progressViewOffset={10 + topInset}
          />
        }
      >
        {error ? (
          <ThemedText style={styles.errorText}>{error}</ThemedText>
        ) : wordIds.length === 0 ? (
          <ThemedText style={styles.emptyText}>No words added yet</ThemedText>
        ) : (
          <View style={styles.cardsContainer}>
            {wordIds.map((wordId) => (
              <WordCard
                key={wordId}
                wordId={wordId}
                onPress={(word) => handleOpenDictionary(word)}
              />
            ))}
          </View>
        )}
      </ScrollView>

      {/* Dictionary Modal */}
      <Modal
        animationType="slide"
        transparent={false}
        visible={dictionaryModalVisible}
        onRequestClose={() => setDictionaryModalVisible(false)}
      >
        <View style={[styles.modalContainer, { paddingTop: topInset }]}>
          <View style={styles.modalHeader}>
            <TouchableOpacity
              style={styles.closeButton}
              onPress={() => setDictionaryModalVisible(false)}
            >
              <Ionicons name="close" size={28} color="#FFFFFF" />
            </TouchableOpacity>
            <ThemedText style={styles.modalTitle}>{selectedWord}</ThemedText>
          </View>
          <WebView
            source={{ uri: `https://dictionary.cambridge.org/dictionary/english/${encodeURIComponent(selectedWord)}` }}
            style={styles.webView}
            startInLoadingState={true}
            renderLoading={() => (
              <View style={styles.loaderContainer}>
                <ActivityIndicator size="large" color="#4CAF50" />
              </View>
            )}
          />
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000',
  },
  scrollView: {
    flex: 1,
    backgroundColor: '#000',
  },
  scrollContent: {
    flexGrow: 1,
    padding: 16,
  },
  cardsContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  headerImage: {
    color: '#808080',
    bottom: -90,
    left: -35,
    position: 'absolute',
  },
  titleContainer: {
    flexDirection: 'row',
    gap: 8,
  },
  centerContent: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  errorText: {
    textAlign: 'center',
    color: '#ff6b6b',
    marginTop: 20,
  },
  emptyText: {
    textAlign: 'center',
    color: '#808080',
    marginTop: 20,
  },
  // New styles for the dictionary modal
  modalContainer: {
    flex: 1,
    backgroundColor: '#000',
  },
  modalHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#333',
    backgroundColor: '#121212',
  },
  closeButton: {
    padding: 8,
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginLeft: 16,
  },
  webView: {
    flex: 1,
  },
  loaderContainer: {
    position: 'absolute',
    width: '100%',
    height: '100%',
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#000',
  },
});
