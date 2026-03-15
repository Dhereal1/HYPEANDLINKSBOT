import { View, StyleSheet, Platform } from "react-native";
import { Stack } from "expo-router";
import { TelegramProvider } from "./components/Telegram";
import { GlobalLogoBarWithFallback } from "./components/GlobalLogoBarWithFallback";
import { SpeedInsights } from "@vercel/speed-insights/react";

export default function RootLayout() {
  return (
    <TelegramProvider>
      <View style={styles.root}>
        <GlobalLogoBarWithFallback />
        <View style={styles.content}>
          <Stack screenOptions={{ headerShown: false }} />
        </View>
        {Platform.OS === "web" && <SpeedInsights />}
      </View>
    </TelegramProvider>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  content: { flex: 1 },
});
