import { Bell, Briefcase, TrendingUp, HelpCircle, MapPin, Star, Clock } from 'lucide-react';
import { Button } from '../ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { VoiceButton } from '../VoiceButton';
import { OfflineBanner } from '../OfflineBanner';

interface WorkerDashboardProps {
  language: 'en' | 'hi' | 'mr';
  isOffline: boolean;
  onVoiceCommand: () => void;
  onNavigate: (screen: string) => void;
}

export function WorkerDashboard({ language, isOffline, onVoiceCommand, onNavigate }: WorkerDashboardProps) {
  const texts = {
    en: {
      title: "Welcome back, Ramesh!",
      subtitle: "Ready to find work today?",
      myJobs: "My Jobs",
      findWork: "Find Work",
      earnings: "Earnings",
      help: "Help",
      newJob: "New Job Alert",
      jobDesc: "Plumbing work in Kothrud",
      timeAgo: "2 hours ago",
      distance: "1.2 km away",
      amount: "₹500-800",
      accept: "Accept",
      view: "View Details",
      todayEarnings: "Today's Earnings",
      thisWeek: "This Week",
      rating: "Your Rating"
    },
    hi: {
      title: "वापस आपका स्वागत है, रमेश!",
      subtitle: "आज काम खोजने के लिए तैयार हैं?",
      myJobs: "मेरे काम",
      findWork: "काम खोजें",
      earnings: "कमाई",
      help: "सहायता",
      newJob: "नई नौकरी अलर्ट",
      jobDesc: "कोथरूड में प्लंबिंग का काम",
      timeAgo: "2 घंटे पहले",
      distance: "1.2 किमी दूर",
      amount: "₹500-800",
      accept: "स्वीकार करें",
      view: "विवरण देखें",
      todayEarnings: "आज की कमाई",
      thisWeek: "इस सप्ताह",
      rating: "आपकी रेटिंग"
    },
    mr: {
      title: "परत स्वागत आहे, रमेश!",
      subtitle: "आज काम शोधायला तयार आहात?",
      myJobs: "माझी कामे",
      findWork: "काम शोधा",
      earnings: "कमाई",
      help: "मदत",
      newJob: "नवीन नोकरी अलर्ट",
      jobDesc: "कोथरुडमध्ये प्लंबिंगचे काम",
      timeAgo: "2 तास आधी",
      distance: "1.2 किमी अंतरावर",
      amount: "₹500-800",
      accept: "स्वीकार करा",
      view: "तपशील पहा",
      todayEarnings: "आजची कमाई",
      thisWeek: "या आठवड्यात",
      rating: "तुमची रेटिंग"
    }
  };

  const t = texts[language];

  return (
    <div className="min-h-screen bg-gray-50 pb-20">
      {/* Header */}
      <div className="bg-primary text-white p-6 rounded-b-3xl">
        <OfflineBanner isOffline={isOffline} language={language} />
        <div className="flex items-center justify-between mb-4">
          <div>
            <h1 className="text-xl">{t.title}</h1>
            <p className="text-primary-foreground/80 text-sm">{t.subtitle}</p>
          </div>
          <Button variant="ghost" size="icon" className="text-white">
            <Bell className="w-5 h-5" />
          </Button>
        </div>
      </div>

      <div className="p-6 space-y-6 -mt-6">
        {/* Quick Actions */}
        <div className="grid grid-cols-2 gap-4">
          <Card className="transition-all hover:shadow-lg" onClick={() => onNavigate('myJobs')}>
            <CardContent className="p-4 text-center">
              <Briefcase className="w-8 h-8 text-primary mx-auto mb-2" />
              <p className="text-sm">{t.myJobs}</p>
            </CardContent>
          </Card>
          <Card className="transition-all hover:shadow-lg" onClick={() => onNavigate('findWork')}>
            <CardContent className="p-4 text-center">
              <MapPin className="w-8 h-8 text-accent mx-auto mb-2" />
              <p className="text-sm">{t.findWork}</p>
            </CardContent>
          </Card>
          <Card className="transition-all hover:shadow-lg" onClick={() => onNavigate('earnings')}>
            <CardContent className="p-4 text-center">
              <TrendingUp className="w-8 h-8 text-blue-600 mx-auto mb-2" />
              <p className="text-sm">{t.earnings}</p>
            </CardContent>
          </Card>
          <Card className="transition-all hover:shadow-lg" onClick={() => onNavigate('help')}>
            <CardContent className="p-4 text-center">
              <HelpCircle className="w-8 h-8 text-gray-600 mx-auto mb-2" />
              <p className="text-sm">{t.help}</p>
            </CardContent>
          </Card>
        </div>

        {/* New Job Alert */}
        <Card className="border-l-4 border-l-accent">
          <CardHeader className="pb-3">
            <div className="flex items-center justify-between">
              <CardTitle className="text-lg">{t.newJob}</CardTitle>
              <Badge variant="secondary" className="bg-accent/10 text-accent">
                <Clock className="w-3 h-3 mr-1" />
                {t.timeAgo}
              </Badge>
            </div>
          </CardHeader>
          <CardContent className="pt-0">
            <div className="space-y-3">
              <p className="text-gray-700">{t.jobDesc}</p>
              <div className="flex items-center gap-4 text-sm text-gray-600">
                <span className="flex items-center gap-1">
                  <MapPin className="w-4 h-4" />
                  {t.distance}
                </span>
                <span className="text-accent">{t.amount}</span>
              </div>
              <div className="flex gap-2">
                <Button className="flex-1 bg-accent hover:bg-accent/90">
                  {t.accept}
                </Button>
                <Button variant="outline" className="flex-1">
                  {t.view}
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Quick Stats */}
        <div className="grid grid-cols-3 gap-4">
          <Card>
            <CardContent className="p-4 text-center">
              <p className="text-2xl text-primary">₹350</p>
              <p className="text-xs text-gray-600">{t.todayEarnings}</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4 text-center">
              <p className="text-2xl text-accent">₹2,100</p>
              <p className="text-xs text-gray-600">{t.thisWeek}</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4 text-center">
              <div className="flex items-center justify-center gap-1">
                <Star className="w-4 h-4 text-yellow-500 fill-current" />
                <p className="text-2xl">4.8</p>
              </div>
              <p className="text-xs text-gray-600">{t.rating}</p>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Floating Voice Button */}
      <div className="fixed bottom-6 right-6">
        <VoiceButton onClick={onVoiceCommand} size="lg" />
      </div>
    </div>
  );
}