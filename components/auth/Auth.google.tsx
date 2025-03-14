
import { supabase } from '../../services/supabase'
import * as Google from 'expo-auth-session/providers/google'
import * as WebBrowser from "expo-web-browser";
import { Button } from 'react-native';


WebBrowser.maybeCompleteAuthSession();
export default function GoogleAuth() {


  const [request, response, promptAsync] = Google.useAuthRequest({
    androidClientId: "",
    iosClientId: "297363518648-p4uvjst5td2qvu7gfmm54netj1cag9bp.apps.googleusercontent.com",
    webClientId: "297363518648-ddbetfva2ht3of4jorkrgn88sp7gm587.apps.googleusercontent.com",
  });

  return (
    <Button
      title="Sign in with Google"
      onPress={async () => {
        try {
          const result = await promptAsync()
          if (result.type === 'success') {
            const { data, error } = await supabase.auth.signInWithIdToken({
              provider: 'google',
              token: result.authentication?.idToken || '',
            })
            console.log(error, data)
          } else {
            throw new Error('no ID token present!')
          }
        } catch (error: any) {
          console.log(error)
        }
      }
      }
    />
  )
}

