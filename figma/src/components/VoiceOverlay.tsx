import { useState, useEffect } from 'react';
import { Mic, MicOff, Volume2, RotateCcw } from 'lucide-react';
import { Button } from './ui/button';
import { Card } from './ui/card';

interface VoiceOverlayProps {
  isOpen: boolean;
  onClose: () => void;
  onCommand: (command: string) => void;
  language: 'en' | 'hi' | 'mr';
}

export function VoiceOverlay({ isOpen, onClose, onCommand, language }: VoiceOverlayProps) {
  const [isListening, setIsListening] = useState(false);
  const [transcript, setTranscript] = useState('');
  const [isProcessing, setIsProcessing] = useState(false);

  const promptTexts = {
    en: {
      listening: "Listening... Speak now",
      processing: "Processing your command...",
      tryAgain: "Try Again",
      confirm: "Confirm",
      cancel: "Cancel"
    },
    hi: {
      listening: "सुन रहे हैं... अब बोलें",
      processing: "आपके आदेश को समझ रहे हैं...",
      tryAgain: "फिर कोशिश करें",
      confirm: "पुष्टि करें",
      cancel: "रद्द करें"
    },
    mr: {
      listening: "ऐकत आहे... आता बोला",
      processing: "तुमचा आदेश समजत आहे...",
      tryAgain: "पुन्हा प्रयत्न करा",
      confirm: "पुष्टी करा",
      cancel: "रद्द करा"
    }
  };

  const texts = promptTexts[language];

  useEffect(() => {
    if (isOpen) {
      setIsListening(true);
      // Simulate listening for 3 seconds, then show a mock transcript
      const timer = setTimeout(() => {
        setIsListening(false);
        setTranscript(language === 'en' ? "Find electrician near me" : 
                     language === 'hi' ? "मेरे पास इलेक्ट्रीशियन खोजें" : 
                     "माझ्या जवळ इलेक्ट्रिशियन शोधा");
      }, 3000);
      return () => clearTimeout(timer);
    }
  }, [isOpen, language]);

  const handleConfirm = () => {
    setIsProcessing(true);
    setTimeout(() => {
      onCommand(transcript);
      onClose();
      setIsProcessing(false);
      setTranscript('');
    }, 1000);
  };

  const handleRetry = () => {
    setTranscript('');
    setIsListening(true);
    setTimeout(() => {
      setIsListening(false);
      setTranscript(language === 'en' ? "Book plumber for tomorrow" : 
                   language === 'hi' ? "कल के लिए प्लंबर बुक करें" : 
                   "उद्यासाठी प्लंबर बुक करा");
    }, 3000);
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-md p-6 space-y-6">
        <div className="text-center">
          <div className="relative mx-auto w-20 h-20 mb-4">
            {isListening ? (
              <div className="w-20 h-20 bg-primary rounded-full flex items-center justify-center animate-pulse">
                <Mic className="w-8 h-8 text-white" />
                <div className="absolute inset-0 bg-primary/30 rounded-full animate-ping" />
              </div>
            ) : (
              <div className="w-20 h-20 bg-muted rounded-full flex items-center justify-center">
                <MicOff className="w-8 h-8 text-muted-foreground" />
              </div>
            )}
          </div>
          
          <p className="text-sm text-muted-foreground mb-2">
            {isListening ? texts.listening : isProcessing ? texts.processing : ''}
          </p>
          
          {transcript && !isListening && (
            <div className="bg-muted p-3 rounded-lg mb-4">
              <p className="text-sm">{transcript}</p>
            </div>
          )}
        </div>

        <div className="flex gap-2">
          {transcript && !isListening && (
            <>
              <Button variant="outline" onClick={handleRetry} className="flex-1">
                <RotateCcw className="w-4 h-4 mr-2" />
                {texts.tryAgain}
              </Button>
              <Button 
                onClick={handleConfirm} 
                className="flex-1 bg-primary hover:bg-primary/90"
                disabled={isProcessing}
              >
                <Volume2 className="w-4 h-4 mr-2" />
                {texts.confirm}
              </Button>
            </>
          )}
          <Button variant="ghost" onClick={onClose} className="flex-1">
            {texts.cancel}
          </Button>
        </div>
      </Card>
    </div>
  );
}