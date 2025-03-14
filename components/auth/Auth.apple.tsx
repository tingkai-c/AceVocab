import { Platform, View, StyleSheet } from 'react-native'
import * as AppleAuthentication from 'expo-apple-authentication'
import { supabase } from '../../services/supabase'
// import { GoogleSignin } from '@react-native-google-signin/google-signin'


export function Auth() {
  // GoogleSignin.configure({
  //   scopes: ['https://www.googleapis.com/auth/drive.readonly'],
  //   webClientId: '297363518648-p4uvjst5td2qvu7gfmm54netj1cag9bp.apps.googleusercontent.com',
  // })
  return (
    <AppleAuthentication.AppleAuthenticationButton
      buttonType={AppleAuthentication.AppleAuthenticationButtonType.SIGN_IN}
      buttonStyle={AppleAuthentication.AppleAuthenticationButtonStyle.BLACK}
      cornerRadius={5}
      style={{ width: 200, height: 64 }}
      onPress={async () => {
        try {
          const credential = await AppleAuthentication.signInAsync({
            requestedScopes: [
              AppleAuthentication.AppleAuthenticationScope.FULL_NAME,
              AppleAuthentication.AppleAuthenticationScope.EMAIL,
            ],
          })
          console.log(credential)
          // Sign in via Supabase Auth.
          if (credential.identityToken) {
            const {
              error,
              data: { user },
            } = await supabase.auth.signInWithIdToken({
              provider: 'apple',
              token: credential.identityToken,
            })
            console.log(JSON.stringify({ error, user }, null, 2))
            if (!error) {

            }
          } else {
            throw new Error('No identityToken.')
          }
        } catch (e) {
          if (e.code === 'ERR_REQUEST_CANCELED') {
            // handle that the user canceled the sign-in flow
          } else {
            // handle other errors
          }
        }
      }}
    />)
}
const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  button: {
    width: 200,
    height: 44,
  },
});
