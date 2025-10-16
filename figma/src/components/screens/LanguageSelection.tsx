import { Button } from '../ui/button';
import { Card } from '../ui/card';
import { VoiceButton } from '../VoiceButton';

interface LanguageSelectionProps {
  onLanguageSelect: (language: 'en' | 'hi' | 'mr') => void;
  onVoiceCommand: () => void;
}

export function LanguageSelection({ onLanguageSelect, onVoiceCommand }: LanguageSelectionProps) {
  const languages = [
    { code: 'en' as const, name: 'English', nativeName: 'English' },
    { code: 'hi' as const, name: 'Hindi', nativeName: 'हिन्दी' },
    { code: 'mr' as const, name: 'Marathi', nativeName: 'मराठी' }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-orange-50 via-white to-orange-50 flex flex-col items-center justify-center p-6">
      <div className="w-full max-w-md space-y-8">
        {/* Header */}
        <div className="text-center space-y-4">
          <div className="w-16 h-16 mx-auto bg-primary rounded-2xl flex items-center justify-center">
            <span className="text-white text-2xl">🗣️</span>
          </div>
          <div className="space-y-2">
            <h1 className="text-2xl text-gray-800">Select Your Language</h1>
            <p className="text-sm text-gray-600">अपनी भाषा चुनें • तुमची भाषा निवडा</p>
          </div>
        </div>

        {/* Language Options */}
        <div className="space-y-3">
          {languages.map((lang) => (
            <Card key={lang.code} className="p-1">
              <Button
                onClick={() => onLanguageSelect(lang.code)}
                variant="ghost"
                className="w-full h-16 justify-start text-left hover:bg-primary/5 transition-colors"
              >
                <div className="flex items-center space-x-4">
                  <div className="w-12 h-12 bg-primary/10 rounded-lg flex items-center justify-center">
                    <span className="text-xl">🌐</span>
                  </div>
                  <div>
                    <p className="text-base">{lang.name}</p>
                    <p className="text-lg text-primary">{lang.nativeName}</p>
                  </div>
                </div>
              </Button>
            </Card>
          ))}
        </div>

        {/* Voice Command */}
        <div className="text-center space-y-3">
          <p className="text-sm text-gray-600">Or speak to select</p>
          <VoiceButton onClick={onVoiceCommand} size="lg" />
          <p className="text-xs text-gray-500">Say "Hindi", "English", or "Marathi"</p>
        </div>

        {/* Footer */}
        <div className="text-center pt-4">
          <p className="text-xs text-gray-500">
            Powered by Digital India Initiative
          </p>
        </div>
      </div>
    </div>
  );
}