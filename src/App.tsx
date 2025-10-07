import { useState } from 'react';
import { VoiceOverlay } from './components/VoiceOverlay';
import { SplashScreen } from './components/screens/SplashScreen';
import { AuthScreen } from './components/screens/AuthScreen';
import { LanguageSelection } from './components/screens/LanguageSelection';
import { RoleSelection } from './components/screens/RoleSelection';
import { TutorialScreen } from './components/screens/TutorialScreen';
import { WorkerDashboard } from './components/screens/WorkerDashboard';
import { ClientDashboard } from './components/screens/ClientDashboard';
import { JobPosting } from './components/screens/JobPosting';
import { WorkerList } from './components/screens/WorkerList';
import { JobConfirmation } from './components/screens/JobConfirmation';
import { MyJobs } from './components/screens/MyJobs';
import { FindWork } from './components/screens/FindWork';
import { Earnings } from './components/screens/Earnings';
import { Help } from './components/screens/Help';
import { MyRequests } from './components/screens/MyRequests';
import { History } from './components/screens/History';

type Screen = 'splash' | 'auth' | 'language' | 'role' | 'tutorial' | 'workerDashboard' | 'clientDashboard' | 
             'jobPosting' | 'workerList' | 'jobConfirmation' | 'myJobs' | 'findWork' | 'earnings' | 'help' |
             'myRequests' | 'history';
type Language = 'en' | 'hi' | 'mr';
type Role = 'worker' | 'client' | null;

export default function App() {
  const [currentScreen, setCurrentScreen] = useState<Screen>('auth');
  const [language, setLanguage] = useState<Language>('en');
  const [role, setRole] = useState<Role>(null);
  const [isVoiceOverlayOpen, setIsVoiceOverlayOpen] = useState(false);
  const [isOffline, setIsOffline] = useState(false);
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  const handleSplashComplete = () => {
    setCurrentScreen('auth');
  };

  const handleAuthComplete = () => {
    setIsAuthenticated(true);
    setCurrentScreen('language');
  };

  const handleLanguageSelect = (selectedLanguage: Language) => {
    setLanguage(selectedLanguage);
    setCurrentScreen('role');
  };

  const handleRoleSelect = (selectedRole: Role) => {
    setRole(selectedRole);
    setCurrentScreen('tutorial');
  };

  const handleTutorialComplete = () => {
    if (role === 'worker') {
      setCurrentScreen('workerDashboard');
    } else {
      setCurrentScreen('clientDashboard');
    }
  };

  const handleTutorialSkip = () => {
    if (role === 'worker') {
      setCurrentScreen('workerDashboard');
    } else {
      setCurrentScreen('clientDashboard');
    }
  };

  const handleVoiceCommand = (command: string) => {
    // Process voice commands based on current screen and language
    console.log('Voice command received:', command);
    
    // Simple command processing for demo
    if (currentScreen === 'auth') {
      // Handle phone number or OTP voice input
      const numbers = command.replace(/\D/g, '');
      if (numbers.length === 10) {
        // This would set phone number in auth screen
        console.log('Phone number detected:', numbers);
      } else if (numbers.length === 4) {
        // This would set OTP in auth screen
        console.log('OTP detected:', numbers);
      }
    } else if (currentScreen === 'language') {
      if (command.toLowerCase().includes('hindi') || command.includes('हिन्दी')) {
        handleLanguageSelect('hi');
      } else if (command.toLowerCase().includes('marathi') || command.includes('मराठी')) {
        handleLanguageSelect('mr');
      } else if (command.toLowerCase().includes('english')) {
        handleLanguageSelect('en');
      }
    } else if (currentScreen === 'role') {
      if (command.toLowerCase().includes('worker') || command.includes('कामगार')) {
        handleRoleSelect('worker');
      } else if (command.toLowerCase().includes('client') || command.includes('ग्राहक')) {
        handleRoleSelect('client');
      }
    } else if (currentScreen === 'clientDashboard') {
      if (command.toLowerCase().includes('electrician') || command.includes('इलेक्ट्रीशियन')) {
        setCurrentScreen('workerList');
      } else if (command.toLowerCase().includes('post') || command.includes('पोस्ट')) {
        setCurrentScreen('jobPosting');
      }
    }
  };

  const handleNavigation = (screen: string) => {
    switch (screen) {
      case 'jobPosting':
        setCurrentScreen('jobPosting');
        break;
      case 'findWorker':
        setCurrentScreen('workerList');
        break;
      case 'myJobs':
        setCurrentScreen('myJobs');
        break;
      case 'findWork':
        setCurrentScreen('findWork');
        break;
      case 'earnings':
        setCurrentScreen('earnings');
        break;
      case 'help':
        setCurrentScreen('help');
        break;
      case 'myRequests':
        setCurrentScreen('myRequests');
        break;
      case 'history':
        setCurrentScreen('history');
        break;
      default:
        console.log(`Navigation to ${screen} not implemented`);
    }
  };

  const handleWorkerSelect = (workerId: string) => {
    console.log(`Selected worker: ${workerId}`);
    setCurrentScreen('jobConfirmation');
  };

  const handleJobPost = () => {
    setCurrentScreen('workerList');
  };

  const handleBackHome = () => {
    if (role === 'worker') {
      setCurrentScreen('workerDashboard');
    } else {
      setCurrentScreen('clientDashboard');
    }
  };

  const renderCurrentScreen = () => {
    switch (currentScreen) {
      case 'splash':
        return <SplashScreen onComplete={handleSplashComplete} />;
      
      case 'auth':
        return (
          <AuthScreen
            onAuthComplete={handleAuthComplete}
            onVoiceCommand={() => setIsVoiceOverlayOpen(true)}
          />
        );
      
      case 'language':
        return (
          <LanguageSelection
            onLanguageSelect={handleLanguageSelect}
            onVoiceCommand={() => setIsVoiceOverlayOpen(true)}
          />
        );
      
      case 'role':
        return (
          <RoleSelection
            language={language}
            onRoleSelect={handleRoleSelect}
            onVoiceCommand={() => setIsVoiceOverlayOpen(true)}
          />
        );
      
      case 'tutorial':
        return (
          <TutorialScreen
            language={language}
            role={role || 'worker'}
            onComplete={handleTutorialComplete}
            onSkip={handleTutorialSkip}
          />
        );
      
      case 'workerDashboard':
        return (
          <WorkerDashboard
            language={language}
            isOffline={isOffline}
            onVoiceCommand={() => setIsVoiceOverlayOpen(true)}
            onNavigate={handleNavigation}
          />
        );
      
      case 'clientDashboard':
        return (
          <ClientDashboard
            language={language}
            isOffline={isOffline}
            onVoiceCommand={() => setIsVoiceOverlayOpen(true)}
            onNavigate={handleNavigation}
          />
        );
      
      case 'jobPosting':
        return (
          <JobPosting
            language={language}
            onBack={handleBackHome}
            onVoiceCommand={() => setIsVoiceOverlayOpen(true)}
            onPost={handleJobPost}
          />
        );
      
      case 'workerList':
        return (
          <WorkerList
            language={language}
            onBack={handleBackHome}
            onWorkerSelect={handleWorkerSelect}
          />
        );
      
      case 'jobConfirmation':
        return (
          <JobConfirmation
            language={language}
            onHome={handleBackHome}
          />
        );
      
      case 'myJobs':
        return (
          <MyJobs
            language={language}
            isOffline={isOffline}
            onBack={handleBackHome}
            onVoiceCommand={() => setIsVoiceOverlayOpen(true)}
          />
        );
      
      case 'findWork':
        return (
          <FindWork
            language={language}
            isOffline={isOffline}
            onBack={handleBackHome}
            onVoiceCommand={() => setIsVoiceOverlayOpen(true)}
          />
        );
      
      case 'earnings':
        return (
          <Earnings
            language={language}
            isOffline={isOffline}
            onBack={handleBackHome}
            onVoiceCommand={() => setIsVoiceOverlayOpen(true)}
          />
        );
      
      case 'help':
        return (
          <Help
            language={language}
            isOffline={isOffline}
            onBack={handleBackHome}
            onVoiceCommand={() => setIsVoiceOverlayOpen(true)}
          />
        );
      
      case 'myRequests':
        return (
          <MyRequests
            language={language}
            isOffline={isOffline}
            onBack={handleBackHome}
            onVoiceCommand={() => setIsVoiceOverlayOpen(true)}
          />
        );
      
      case 'history':
        return (
          <History
            language={language}
            isOffline={isOffline}
            onBack={handleBackHome}
            onVoiceCommand={() => setIsVoiceOverlayOpen(true)}
          />
        );
      
      default:
        return <SplashScreen onComplete={handleSplashComplete} />;
    }
  };

  return (
    <div className="size-full min-h-screen bg-gray-50">
      {renderCurrentScreen()}
      
      <VoiceOverlay
        isOpen={isVoiceOverlayOpen}
        onClose={() => setIsVoiceOverlayOpen(false)}
        onCommand={handleVoiceCommand}
        language={language}
      />
      
      {/* Offline Toggle for Demo */}
      <div className="fixed top-4 right-4 z-40">
        <button
          onClick={() => setIsOffline(!isOffline)}
          className="px-3 py-1 text-xs bg-gray-800 text-white rounded-full opacity-50 hover:opacity-100"
        >
          {isOffline ? 'Go Online' : 'Go Offline'}
        </button>
      </div>
    </div>
  );
}