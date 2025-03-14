import { Button, Platform } from 'react-native';
import { supabase } from '../../services/supabase';

export function AuthAnon() {
  return (
    <Button
      title="Sign In Anonymously"
      onPress={async () => {
        try {
          const { error } = await supabase.auth.signInAnonymously();
          if (error) {
            throw error;
          }
        } catch (error: any) {
          console.error("Anonymous sign-in error:", error.message);
          alert(error.message);
        }
      }}
    />
  );
}


