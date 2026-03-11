import "../global.css";
import { View, StyleSheet } from "react-native";
import { Stack } from "expo-router";
import { TelegramProvider } from "./components/Telegram";
import { GlobalLogoBarWithFallback } from "./components/GlobalLogoBarWithFallback";
import { GlobalBottomBar } from "./components/GlobalBottomBar";

/**
 * Three-block column layout (same as Flutter):
 * 1. Logo bar (optional in TMA when not fullscreen)
 * 2. Main area (flex, scrollable per screen) – Stack updates on route change
 * 3. AI & Search bar (fixed at bottom)
 */
export default function RootLayout() {
  return (
    <TelegramProvider>
      <View style={styles.root}>
        <GlobalLogoBarWithFallback />
        <View style={styles.main}>
          <Stack screenOptions={{ headerShown: false }} />
        </View>
        <GlobalBottomBar />
      </View>
    </TelegramProvider>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    flexDirection: "column",
  },
  main: {
    flex: 1,
    minHeight: 0,
  },
});
