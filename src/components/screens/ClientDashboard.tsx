import { Search, History, HelpCircle, Plus, Zap, Wrench, Paintbrush, Hammer } from 'lucide-react';
import { Button } from '../ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { VoiceButton } from '../VoiceButton';
import { OfflineBanner } from '../OfflineBanner';

interface ClientDashboardProps {
  language: 'en' | 'hi' | 'mr';
  isOffline: boolean;
  onVoiceCommand: () => void;
  onNavigate: (screen: string) => void;
}

export function ClientDashboard({ language, isOffline, onVoiceCommand, onNavigate }: ClientDashboardProps) {
  const texts = {
    en: {
      title: "Hello, Priya!",
      subtitle: "What service do you need today?",
      findWorker: "Find Worker",
      myRequests: "My Requests",
      history: "History",
      help: "Help",
      quickBook: "Quick Book Services",
      electrician: "Electrician",
      plumber: "Plumber", 
      painter: "Painter",
      carpenter: "Carpenter",
      recentRequest: "Recent Request",
      pending: "Pending",
      worker: "Worker: Rajesh K.",
      eta: "ETA: 30 mins"
    },
    hi: {
      title: "नमस्ते, प्रिया!",
      subtitle: "आज आपको किस सेवा की आवश्यकता है?",
      findWorker: "कामगार खोजें",
      myRequests: "मेरी अनुरोध",
      history: "इतिहास",
      help: "सहायता",
      quickBook: "त्वरित सेवा बुक करें",
      electrician: "इलेक्ट्रीशियन",
      plumber: "प्लंबर",
      painter: "पेंटर",
      carpenter: "बढ़ई",
      recentRequest: "हाल की अनुरोध",
      pending: "लंबित",
      worker: "कामगार: राजेश के.",
      eta: "पहुंचने का समय: 30 मिनट"
    },
    mr: {
      title: "नमस्कार, प्रिया!",
      subtitle: "आज तुम्हाला कोणती सेवा हवी आहे?",
      findWorker: "कामगार शोधा",
      myRequests: "माझ्या विनंत्या",
      history: "इतिहास",
      help: "मदत",
      quickBook: "त्वरित सेवा बुक करा",
      electrician: "इलेक्ट्रिशियन",
      plumber: "प्लंबर",
      painter: "पेंटर",
      carpenter: "सुतार",
      recentRequest: "अलीकडील विनंती",
      pending: "प्रलंबित",
      worker: "कामगार: राजेश के.",
      eta: "पोहोचण्याची वेळ: 30 मिनिटे"
    }
  };

  const t = texts[language];

  const services = [
    { name: t.electrician, icon: Zap, color: 'text-yellow-600' },
    { name: t.plumber, icon: Wrench, color: 'text-blue-600' },
    { name: t.painter, icon: Paintbrush, color: 'text-purple-600' },
    { name: t.carpenter, icon: Hammer, color: 'text-orange-600' }
  ];

  return (
    <div className="min-h-screen bg-gray-50 pb-20">
      {/* Header */}
      <div className="bg-gradient-to-r from-green-600 to-green-500 text-white p-6 rounded-b-3xl">
        <OfflineBanner isOffline={isOffline} language={language} />
        <div className="mb-6">
          <h1 className="text-xl">{t.title}</h1>
          <p className="text-white/80 text-sm">{t.subtitle}</p>
        </div>
      </div>

      <div className="p-6 space-y-6 -mt-6">
        {/* Quick Actions */}
        <div className="grid grid-cols-2 gap-4">
          <Card className="transition-all hover:shadow-lg" onClick={() => onNavigate('findWorker')}>
            <CardContent className="p-4 text-center">
              <Search className="w-8 h-8 text-green-600 mx-auto mb-2" />
              <p className="text-sm">{t.findWorker}</p>
            </CardContent>
          </Card>
          <Card className="transition-all hover:shadow-lg" onClick={() => onNavigate('myRequests')}>
            <CardContent className="p-4 text-center">
              <Plus className="w-8 h-8 text-green-500 mx-auto mb-2" />
              <p className="text-sm">{t.myRequests}</p>
            </CardContent>
          </Card>
          <Card className="transition-all hover:shadow-lg" onClick={() => onNavigate('history')}>
            <CardContent className="p-4 text-center">
              <History className="w-8 h-8 text-blue-600 mx-auto mb-2" />
              <p className="text-sm">{t.history}</p>
            </CardContent>
          </Card>
          <Card className="transition-all hover:shadow-lg" onClick={() => onNavigate('help')}>
            <CardContent className="p-4 text-center">
              <HelpCircle className="w-8 h-8 text-gray-600 mx-auto mb-2" />
              <p className="text-sm">{t.help}</p>
            </CardContent>
          </Card>
        </div>

        {/* Quick Book Services */}
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">{t.quickBook}</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 gap-3">
              {services.map((service, index) => (
                <Button
                  key={index}
                  variant="outline"
                  className="h-16 flex flex-col items-center justify-center space-y-1 hover:bg-green-50"
                  onClick={() => onNavigate('jobPosting')}
                >
                  <service.icon className={`w-6 h-6 ${service.color}`} />
                  <span className="text-xs">{service.name}</span>
                </Button>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Recent Request */}
        <Card className="border-l-4 border-l-green-600">
          <CardHeader className="pb-3">
            <div className="flex items-center justify-between">
              <CardTitle className="text-lg">{t.recentRequest}</CardTitle>
              <Badge variant="secondary" className="bg-yellow-100 text-yellow-800">
                {t.pending}
              </Badge>
            </div>
          </CardHeader>
          <CardContent className="pt-0">
            <div className="space-y-2">
              <p className="text-gray-700">Kitchen tap repair</p>
              <p className="text-sm text-gray-600">{t.worker}</p>
              <p className="text-sm text-green-600">{t.eta}</p>
              <Button size="sm" className="w-full mt-3 bg-green-600 hover:bg-green-700">
                Track Worker
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Floating Voice Button */}
      <div className="fixed bottom-6 right-6">
        <VoiceButton onClick={onVoiceCommand} size="lg" />
      </div>
    </div>
  );
}