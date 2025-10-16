import { useEffect } from 'react';
import { ImageWithFallback } from '../figma/ImageWithFallback';

interface SplashScreenProps {
  onComplete: () => void;
}

export function SplashScreen({ onComplete }: SplashScreenProps) {
  useEffect(() => {
    const timer = setTimeout(onComplete, 3000);
    return () => clearTimeout(timer);
  }, [onComplete]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-orange-50 via-white to-orange-50 flex flex-col items-center justify-center p-6 relative overflow-hidden">
      {/* Decorative circles */}
      <div className="absolute top-20 left-10 w-32 h-32 bg-primary/10 rounded-full blur-xl" />
      <div className="absolute bottom-40 right-10 w-40 h-40 bg-accent/10 rounded-full blur-xl" />
      
      <div className="text-center space-y-8 z-10">
        {/* Logo */}
        <div className="space-y-4">
          <div className="w-24 h-24 mx-auto bg-primary rounded-2xl flex items-center justify-center shadow-lg">
            <span className="text-white text-3xl">🛠️</span>
          </div>
          <div className="space-y-2">
            <h1 className="text-4xl text-primary tracking-wide">VoiceSewa</h1>
            <p className="text-lg text-gray-600 max-w-xs mx-auto leading-relaxed">
              Skill Meets Opportunity in Every Language
            </p>
          </div>
        </div>

        {/* Cultural motif */}
        <div className="w-16 h-16 mx-auto opacity-30">
          <svg viewBox="0 0 64 64" className="w-full h-full text-primary">
            <circle cx="32" cy="32" r="30" fill="none" stroke="currentColor" strokeWidth="1" strokeDasharray="4,4" />
            <circle cx="32" cy="32" r="20" fill="none" stroke="currentColor" strokeWidth="1" strokeDasharray="2,2" />
            <circle cx="32" cy="32" r="10" fill="none" stroke="currentColor" strokeWidth="1" />
          </svg>
        </div>

        {/* Loading indicator */}
        <div className="w-32 h-1 bg-gray-200 rounded-full mx-auto overflow-hidden">
          <div className="h-full bg-primary rounded-full animate-pulse w-1/2" />
        </div>
      </div>
    </div>
  );
}