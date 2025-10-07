import { WifiOff, RefreshCw } from 'lucide-react';
import { Alert, AlertDescription } from './ui/alert';

interface OfflineBannerProps {
  isOffline: boolean;
  language: 'en' | 'hi' | 'mr';
}

export function OfflineBanner({ isOffline, language }: OfflineBannerProps) {
  const texts = {
    en: "Offline - Your actions will sync when connected",
    hi: "ऑफ़लाइन - जुड़ने पर आपकी कार्रवाइयां सिंक हो जाएंगी",
    mr: "ऑफलाइन - जोडल्यावर तुमच्या क्रिया सिंक होतील"
  };

  if (!isOffline) return null;

  return (
    <Alert className="bg-orange-50 border-orange-200 mb-4">
      <WifiOff className="h-4 w-4 text-orange-600" />
      <AlertDescription className="text-orange-800">
        {texts[language]}
      </AlertDescription>
    </Alert>
  );
}