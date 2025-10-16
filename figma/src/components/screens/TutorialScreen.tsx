import { useState } from 'react';
import { ChevronLeft, ChevronRight, Play, Volume2, SkipForward } from 'lucide-react';
import { Button } from '../ui/button';
import { Card, CardContent } from '../ui/card';

interface TutorialScreenProps {
  language: 'en' | 'hi' | 'mr';
  role: 'worker' | 'client';
  onComplete: () => void;
  onSkip: () => void;
}

export function TutorialScreen({ language, role, onComplete, onSkip }: TutorialScreenProps) {
  const [currentStep, setCurrentStep] = useState(0);
  const [isPlaying, setIsPlaying] = useState(false);

  const texts = {
    en: {
      title: "Quick Tutorial",
      subtitle: "Learn how to use VoiceSewa in 3 easy steps",
      skip: "Skip Tutorial",
      next: "Next",
      previous: "Previous",
      finish: "Get Started",
      playAudio: "Play Audio Guide",
      worker: {
        steps: [
          {
            title: "Find Jobs Near You",
            description: "Get notified about work opportunities in your area. Accept jobs that match your skills.",
            icon: "📍"
          },
          {
            title: "Use Voice Commands",
            description: "Tap the microphone button to speak. Say 'Accept job' or 'Show my earnings' to navigate.",
            icon: "🎤"
          },
          {
            title: "Get Paid Safely",
            description: "Complete work, get OTP from client, and receive payment directly to your account.",
            icon: "💰"
          }
        ]
      },
      client: {
        steps: [
          {
            title: "Post Your Requirements",
            description: "Tell us what work you need done. Use voice or type your requirements clearly.",
            icon: "📝"
          },
          {
            title: "Choose Your Worker",
            description: "Browse verified workers nearby. Check ratings and experience before booking.",
            icon: "👥"
          },
          {
            title: "Track & Pay",
            description: "Track worker arrival, provide OTP when work starts, and pay securely through the app.",
            icon: "✅"
          }
        ]
      }
    },
    hi: {
      title: "त्वरित ट्यूटोरियल",
      subtitle: "3 आसान चरणों में VoiceSewa का उपयोग सीखें",
      skip: "ट्यूटोरियल छोड़ें",
      next: "आगे",
      previous: "पिछला",
      finish: "शुरू करें",
      playAudio: "ऑडियो गाइड चलाएं",
      worker: {
        steps: [
          {
            title: "अपने पास काम खोजें",
            description: "अपने क्षेत्र में काम के अवसरों की सूचना पाएं। अपने कौशल के अनुकूल काम स्वीकार करें।",
            icon: "📍"
          },
          {
            title: "आवाज़ कमांड का उपयोग करें",
            description: "बोलने के लिए माइक्रोफोन बटन दबाएं। 'काम स्वीकार करें' या 'मेरी कमाई दिखाएं' कहें।",
            icon: "🎤"
          },
          {
            title: "सुरक्षित भुगतान पाएं",
            description: "काम पूरा करें, ग्राहक से OTP लें, और सीधे अपने खाते में भुगतान प्राप्त करें।",
            icon: "💰"
          }
        ]
      },
      client: {
        steps: [
          {
            title: "अपनी आवश्यकताएं पोस्ट करें",
            description: "बताएं कि आपको क्या काम करवाना है। आवाज़ या टाइप करके अपनी आवश्यकताएं स्पष्ट करें।",
            icon: "📝"
          },
          {
            title: "अपना कामगार चुनें",
            description: "आस-पास के सत्यापित कामगारों को देखें। बुकिंग से पहले रेटिंग और अनुभव जांचें।",
            icon: "👥"
          },
          {
            title: "ट्रैक करें और भुगतान करें",
            description: "कामगार के आने को ट्रैक करें, काम शुरू होने पर OTP दें, और ऐप के माध्यम से सुरक्षित भुगतान करें।",
            icon: "✅"
          }
        ]
      }
    },
    mr: {
      title: "त्वरित ट्यूटोरियल",
      subtitle: "3 सोप्या पायऱ्यांमध्ये VoiceSewa वापरायला शिका",
      skip: "ट्यूटोरियल वगळा",
      next: "पुढे",
      previous: "मागे",
      finish: "सुरुवात करा",
      playAudio: "ऑडिओ गाइड चालवा",
      worker: {
        steps: [
          {
            title: "तुमच्या जवळचे काम शोधा",
            description: "तुमच्या भागात कामाच्या संधींची माहिती मिळवा. तुमच्या कौशल्याप्रमाणे काम स्वीकारा.",
            icon: "📍"
          },
          {
            title: "आवाज कमांड वापरा",
            description: "बोलण्यासाठी मायक्रोफोन बटण दाबा. 'काम स्वीकारा' किंवा 'माझी कमाई दाखवा' म्हणा.",
            icon: "🎤"
          },
          {
            title: "सुरक्षित पेमेंट मिळवा",
            description: "काम पूर्ण करा, ग्राहकाकडून OTP घ्या, आणि थेट तुमच्या खात्यात पेमेंट मिळवा.",
            icon: "💰"
          }
        ]
      },
      client: {
        steps: [
          {
            title: "तुमच्या गरजा पोस्ट करा",
            description: "तुम्हाला काय काम करायचे आहे ते सांगा. आवाज किंवा टाइप करून तुमच्या गरजा स्पष्ट करा.",
            icon: "📝"
          },
          {
            title: "तुमचा कामगार निवडा",
            description: "जवळपासचे सत्यापित कामगार पहा. बुकिंगपूर्वी रेटिंग आणि अनुभव तपासा.",
            icon: "👥"
          },
          {
            title: "ट्रॅक करा आणि पेमेंट करा",
            description: "कामगाराचे आगमन ट्रॅक करा, काम सुरू झाल्यावर OTP द्या, आणि अॅपद्वारे सुरक्षित पेमेंट करा.",
            icon: "✅"
          }
        ]
      }
    }
  };

  const t = texts[language];
  const steps = t[role].steps;

  const handleNext = () => {
    if (currentStep < steps.length - 1) {
      setCurrentStep(currentStep + 1);
    } else {
      onComplete();
    }
  };

  const handlePrevious = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1);
    }
  };

  const handlePlayAudio = () => {
    setIsPlaying(true);
    // Simulate audio playback
    setTimeout(() => {
      setIsPlaying(false);
    }, 3000);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-orange-50 via-white to-orange-50 flex flex-col items-center justify-center p-6">
      <div className="w-full max-w-md space-y-8">
        {/* Header */}
        <div className="text-center space-y-4">
          <div className="w-16 h-16 mx-auto bg-primary rounded-2xl flex items-center justify-center">
            <Play className="w-8 h-8 text-white" />
          </div>
          <div className="space-y-2">
            <h1 className="text-gray-800">{t.title}</h1>
            <p className="text-gray-600">{t.subtitle}</p>
          </div>
        </div>

        {/* Progress Indicator */}
        <div className="flex space-x-2 justify-center">
          {steps.map((_, index) => (
            <div
              key={index}
              className={`w-3 h-3 rounded-full transition-colors ${
                index <= currentStep ? 'bg-primary' : 'bg-gray-300'
              }`}
            />
          ))}
        </div>

        {/* Tutorial Step */}
        <Card className="shadow-lg">
          <CardContent className="p-6 text-center space-y-6">
            <div className="text-5xl">{steps[currentStep].icon}</div>
            <div className="space-y-3">
              <h3 className="text-gray-800">{steps[currentStep].title}</h3>
              <p className="text-gray-600 leading-relaxed">{steps[currentStep].description}</p>
            </div>
            
            {/* Audio Guide */}
            <Button
              variant="outline"
              onClick={handlePlayAudio}
              disabled={isPlaying}
              className="w-full"
            >
              {isPlaying ? (
                <>
                  <Volume2 className="w-4 h-4 mr-2 animate-pulse" />
                  Playing...
                </>
              ) : (
                <>
                  <Volume2 className="w-4 h-4 mr-2" />
                  {t.playAudio}
                </>
              )}
            </Button>
          </CardContent>
        </Card>

        {/* Navigation */}
        <div className="flex justify-between space-x-4">
          <Button
            variant="outline"
            onClick={handlePrevious}
            disabled={currentStep === 0}
            className="flex-1"
          >
            <ChevronLeft className="w-4 h-4 mr-2" />
            {t.previous}
          </Button>
          
          <Button
            onClick={handleNext}
            className="flex-1 bg-primary hover:bg-primary/90"
          >
            {currentStep === steps.length - 1 ? t.finish : t.next}
            {currentStep !== steps.length - 1 && <ChevronRight className="w-4 h-4 ml-2" />}
          </Button>
        </div>

        {/* Skip Option */}
        <div className="text-center">
          <Button variant="ghost" onClick={onSkip} className="text-gray-500 hover:text-gray-700">
            <SkipForward className="w-4 h-4 mr-2" />
            {t.skip}
          </Button>
        </div>
      </div>
    </div>
  );
}