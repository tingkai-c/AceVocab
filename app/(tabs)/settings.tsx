import React from 'react';
import { StyleSheet, View } from 'react-native';
import { ThemedText } from '@/components/ThemedText';
import { ThemedView } from '@/components/ThemedView';
import { Auth } from '@/components/auth/Auth';
import { supabase } from '@/services/supabase';
import { useEffect, useState } from 'react';
import { Session } from '@supabase/supabase-js';

export default function SettingsScreen() {
  const [session, setSession] = useState<Session | null>(null);

  useEffect(() => {
    // Get initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
    });

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
    });

    return () => subscription.unsubscribe();
  }, []);

  return (
    <ThemedView style={styles.container}>
      <ThemedText style={styles.title}>Settings</ThemedText>

      {session ? (
        <>
          <ThemedText style={styles.email}>{session.user.email}</ThemedText>
          <ThemedText
            style={styles.signOut}
            onPress={() => supabase.auth.signOut()}
          >
            Sign Out
          </ThemedText>
        </>
      ) : (
        <Auth />
      )}

      <ThemedText style={styles.sectionTitle}>Select Vocab Presets</ThemedText>
    </ThemedView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
  },
  email: {
    fontSize: 16,
    marginBottom: 10,
  },
  signOut: {
    fontSize: 16,
    color: '#FF3B30',
    marginBottom: 30,
  },
  sectionTitle: {
    fontSize: 18,
    marginBottom: 20,
  },
  text: {
    fontSize: 16,
    textAlign: 'center',
  },
});
