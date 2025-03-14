
import React, { useState, useEffect } from 'react';
import { View, Text, Button, StyleSheet, Alert, ActivityIndicator } from 'react-native';
import {
  getNextReviewCard,
  reviewCard,
  initFSRS,
  getRandomUnlearnedVocabularyId,
  addVocabularyCard,
  addSelectedPresetId
} from '@/services/fsrs/fsrs';
import { StoredCard } from '@/services/fsrs/types';
import { Grade, Rating } from 'ts-fsrs';
import { getVocabularyById } from '@/services/local_vocab_db';
import LLMservice from '@/services/LLMservice'
import { ThemedText } from '@/components/ThemedText';
import { loadAllCards } from '@/services/fsrs/storage';


const generateQuestion = async (vocab: string): Promise<{ question: string; choices: string[]; correctAnswer: number }> => {

  const question = await LLMservice.generateVocabQuestion(vocab)
  console.log(question)
  return question;
}

export default function ReviewScreen() {
  const [currentCard, setCurrentCard] = useState<StoredCard | null>(null);
  const [vocabulary, setVocabulary] = useState<string>("");
  const [question, setQuestion] = useState<string>('');
  const [choices, setChoices] = useState<string[]>([]);
  const [correctAnswer, setCorrectAnswer] = useState<number>(0);
  const [userAnswer, setUserAnswer] = useState<number | null>(null);
  const [feedback, setFeedback] = useState<string>('');
  const [loading, setLoading] = useState(true);
  const [isNew, setIsNew] = useState(false); // Track if the card is new


  useEffect(() => {
    const initialize = async () => {
      await initFSRS();
      console.log("Initiali d FSRS")
      await addSelectedPresetId("0ea81186-374c-4a4d-8d47-51ced2403a29")
      await loadNextCard();
      const allCards = await loadAllCards();

      for (const card of allCards) {
        console.log("Card:", card);
      }

      setLoading(false)
    }
    initialize();


  }, []);

  const loadNextCard = async () => {
    setLoading(true); // Start loading before fetching
    try {
      const nextCard = await getNextReviewCard();
      console.log("Next Card: ", nextCard)
      if (nextCard) {
        const vocab = await getVocabularyById(nextCard.id);
        if (vocab) {
          setIsNew(false)
          setVocabulary(vocab.vocab);
          const generated = await generateQuestion(vocab.vocab);
          console.log("Generated: ", generated)
          setQuestion(generated.question);
          setChoices(generated.choices);
          setCorrectAnswer(generated.correctAnswer);
        }
        setCurrentCard(nextCard);
      } else {
        // If there are no cards to review, get a random unlearned word and add it
        const unlearnedVocabId = await getRandomUnlearnedVocabularyId();
        if (unlearnedVocabId) {
          const newCard = await addVocabularyCard(unlearnedVocabId);
          //Set it to the current card
          const vocab = await getVocabularyById(newCard.id);
          if (vocab) {
            setIsNew(true)
            setVocabulary(vocab.vocab);
            const generated = await generateQuestion(vocab.vocab);
            setQuestion(generated.question);
            setChoices(generated.choices);
            setCorrectAnswer(generated.correctAnswer);

          }
          setCurrentCard(newCard); // Set the new card as current
        } else {
          // No unlearned vocabulary words
          console.warn("No unlearned vocabulary available!");
          setQuestion("Congratulations! You have learned all the vocabs from your selected presets.");
          setChoices([]);
          setCorrectAnswer(0);
          setIsNew(false)
        }
      }
    } catch (error) {
      console.log("Error during rendering: ", error)
    }
    finally {
      setLoading(false); // End loading
    }

  };

  const handleAnswer = (choiceIndex: number) => {
    setUserAnswer(choiceIndex);
    if (choiceIndex === correctAnswer) {
      setFeedback('Correct!');
    } else {
      setFeedback(`Incorrect. The correct answer was: ${choices[correctAnswer]}`);
    }
  };

  const handleReview = async (rating: Grade) => {
    if (!currentCard) return;

    try {
      const result = await reviewCard({ cardId: currentCard.id, rating, isNew }); // Pass isNew
      // Get the next card after review
      await loadNextCard();

      setUserAnswer(null); // Reset for the next card
      setFeedback('');
    } catch (error) {
      console.error('Review failed:', error);
      Alert.alert("Error", "Failed to review the card. Please check your connection.")
    }
  };

  const getGrade = (): Grade => {
    if (userAnswer === null) return Rating.Again;

    if (userAnswer === correctAnswer) {
      return Rating.Easy
    } else {
      return Rating.Again
    }
  }

  if (loading) {
    return <View style={styles.container}><ThemedText>Loading...</ThemedText></View>;
  }

  //   if (!currentCard && choices.length === 0) {
  //     return <View><Text>{question}</Text></View>;
  //   } No need to check, question will have text when there is no card.

  return (
    <View style={styles.container}>
      <ThemedText>{question}</ThemedText>

      {choices.map((choice, index) => (
        <Button
          key={index}
          title={choice}
          onPress={() => handleAnswer(index)}
          disabled={userAnswer !== null} // Disable after answering
        />
      ))}

      {userAnswer !== null && <ThemedText>{feedback}</ThemedText>}
      {userAnswer !== null && <Button title={"Review"} onPress={() => handleReview(getGrade())} />}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  buttonContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    width: '100%',
    marginTop: 20,
  },
});


