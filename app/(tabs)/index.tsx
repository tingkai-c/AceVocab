import { Image, StyleSheet, Platform, View, Button, ActivityIndicator } from 'react-native';

import { HelloWave } from '@/components/HelloWave';
import ParallaxScrollView from '@/components/ParallaxScrollView';
import { ThemedText } from '@/components/ThemedText';
import { Auth } from '@/components/auth/Auth.apple';
import { ThemedView } from '@/components/ThemedView';
import { useEffect, useState } from 'react';
import { Session } from '@supabase/supabase-js';
import { WordScheduler } from '@/services/WordScheduler';
import WordCard from '@/components/WordCard';
import * as WebBrowser from 'expo-web-browser';
import { supabase } from '@/services/supabase';


WebBrowser.maybeCompleteAuthSession();

export default function HomeScreen() {
  const [session, setSession] = useState<Session | null>(null)
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session)
    })

    supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session)
    })
    setLoading(false)
  }, [])


  if (loading) {
    return (
      <View><ActivityIndicator size="large" color="#0000ff" /></View>
    )
  } else {
    return (
      //Make it in the center
      <ThemedView style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
        <ThemedText style={{ fontSize: 18, marginBottom: 20 }}>Welcomesad</ThemedText>

        <ThemedText style={{ fontSize: 18, marginBottom: 70 }}>{session ? session.user?.email : 'No user'}</ThemedText>

      </ThemedView>
    );
  }
}

const styles = StyleSheet.create({
  titleContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  stepContainer: {
    gap: 8,
    marginBottom: 8,
  },
  reactLogo: {
    height: 178,
    width: 290,
    bottom: 0,
    left: 0,
    position: 'absolute',
  },
});
