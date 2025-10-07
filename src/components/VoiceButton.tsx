import { Mic } from 'lucide-react';
import { Button } from './ui/button';

interface VoiceButtonProps {
  onClick: () => void;
  isListening?: boolean;
  size?: 'sm' | 'md' | 'lg';
}

export function VoiceButton({ onClick, isListening = false, size = 'md' }: VoiceButtonProps) {
  const sizeClasses = {
    sm: 'w-10 h-10',
    md: 'w-12 h-12',
    lg: 'w-16 h-16'
  };

  const iconSizes = {
    sm: 'w-4 h-4',
    md: 'w-5 h-5',
    lg: 'w-7 h-7'
  };

  return (
    <Button
      onClick={onClick}
      className={`${sizeClasses[size]} rounded-full bg-primary hover:bg-primary/90 ${
        isListening ? 'animate-pulse bg-primary/80' : ''
      } relative`}
      size="icon"
    >
      <Mic className={`${iconSizes[size]} text-white`} />
      {isListening && (
        <div className="absolute inset-0 bg-primary/30 rounded-full animate-ping" />
      )}
    </Button>
  );
}