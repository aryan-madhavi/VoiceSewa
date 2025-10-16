import { Wrench, Home } from 'lucide-react';
import { Button } from '../ui/button';
import { Card, CardContent } from '../ui/card';
import { VoiceButton } from '../VoiceButton';

interface RoleSelectionProps {
  language: 'en' | 'hi' | 'mr';
  onRoleSelect: (role: 'worker' | 'client') => void;
  onVoiceCommand: () => void;
}

export function RoleSelection({ language, onRoleSelect, onVoiceCommand }: RoleSelectionProps) {
  const texts = {
    en: {
      title: "Welcome to VoiceSewa",
      subtitle: "Choose your role to get started",
      worker: "I'm a Worker",
      workerDesc: "Find jobs in your area",
      client: "I'm a Client",
      clientDesc: "Find skilled workers",
      voiceHint: "Say 'Worker' or 'Client'"
    },
    hi: {
      title: "VoiceSewa में आपका स्वागत है",
      subtitle: "शुरू करने के लिए अपनी भूमिका चुनें",
      worker: "मैं एक कामगार हूँ",
      workerDesc: "अपने क्षेत्र में काम खोजें",
      client: "मैं एक ग्राहक हूँ",
      clientDesc: "कुशल कामगार खोजें",
      voiceHint: "'कामगार' या 'ग्राहक' कहें"
    },
    mr: {
      title: "VoiceSewa मध्ये तुमचे स्वागत आहे",
      subtitle: "सुरुवात करण्यासाठी तुमची भूमिका निवडा",
      worker: "मी एक कामगार आहे",
      workerDesc: "तुमच्या भागात काम शोधा",
      client: "मी एक ग्राहक आहे",
      clientDesc: "कुशल कामगार शोधा",
      voiceHint: "'कामगार' किंवा 'ग्राहक' म्हणा"
    }
  };

  const t = texts[language];

  return (
    <div className="min-h-screen bg-gradient-to-br from-orange-50 via-white to-orange-50 flex flex-col items-center justify-center p-6">
      <div className="w-full max-w-md space-y-8">
        {/* Header */}
        <div className="text-center space-y-4">
          <div className="w-20 h-20 mx-auto bg-primary rounded-2xl flex items-center justify-center shadow-lg">
            <span className="text-white text-3xl">🤝</span>
          </div>
          <div className="space-y-2">
            <h1 className="text-2xl text-gray-800">{t.title}</h1>
            <p className="text-sm text-gray-600">{t.subtitle}</p>
          </div>
        </div>

        {/* Role Cards */}
        <div className="space-y-4">
          <Card className="transition-all hover:shadow-lg hover:scale-105 cursor-pointer" 
                onClick={() => onRoleSelect('worker')}>
            <CardContent className="p-6">
              <div className="flex items-center space-x-4">
                <div className="w-16 h-16 bg-primary/10 rounded-xl flex items-center justify-center">
                  <Wrench className="w-8 h-8 text-primary" />
                </div>
                <div className="flex-1">
                  <h3 className="text-lg text-gray-800">{t.worker}</h3>
                  <p className="text-sm text-gray-600">{t.workerDesc}</p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="transition-all hover:shadow-lg hover:scale-105 cursor-pointer" 
                onClick={() => onRoleSelect('client')}>
            <CardContent className="p-6">
              <div className="flex items-center space-x-4">
                <div className="w-16 h-16 bg-accent/10 rounded-xl flex items-center justify-center">
                  <Home className="w-8 h-8 text-accent" />
                </div>
                <div className="flex-1">
                  <h3 className="text-lg text-gray-800">{t.client}</h3>
                  <p className="text-sm text-gray-600">{t.clientDesc}</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Voice Command */}
        <div className="text-center space-y-3">
          <p className="text-sm text-gray-600">Or use voice command</p>
          <VoiceButton onClick={onVoiceCommand} size="lg" />
          <p className="text-xs text-gray-500">{t.voiceHint}</p>
        </div>

        {/* Cultural Element */}
        <div className="text-center pt-4">
          <div className="w-12 h-12 mx-auto opacity-20">
            <svg viewBox="0 0 48 48" className="w-full h-full text-primary">
              <path d="M24 4L6 12v10c0 11 7.8 21.3 18 24 10.2-2.7 18-13 18-24V12L24 4z" 
                    fill="none" stroke="currentColor" strokeWidth="2"/>
            </svg>
          </div>
        </div>
      </div>
    </div>
  );
}