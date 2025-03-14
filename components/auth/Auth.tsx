import { Platform, View, StyleSheet } from 'react-native'
import { Auth as AppleAuth } from './Auth.apple'
import GoogleAuth from './Auth.google'
import { AuthAnon } from './Auth.anon'

export function Auth() {
  return (
    <View style={styles.container}>
      {Platform.OS === 'ios' && <AppleAuth />}
      <GoogleAuth />
      {(Platform.OS === 'ios' || Platform.OS === 'android') && <AuthAnon />}
    </View>
  )
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    gap: 10,
  },
}) 
