import { ArrowLeft, Clock, MapPin, Phone, MessageCircle, Star, CheckCircle, XCircle, AlertTriangle } from 'lucide-react';
import { Button } from '../ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { VoiceButton } from '../VoiceButton';
import { OfflineBanner } from '../OfflineBanner';

interface MyRequestsProps {
  language: 'en' | 'hi' | 'mr';
  isOffline: boolean;
  onBack: () => void;
  onVoiceCommand: () => void;
}

export function MyRequests({ language, isOffline, onBack, onVoiceCommand }: MyRequestsProps) {
  const texts = {
    en: {
      title: "My Requests",
      noRequests: "No active requests",
      noRequestsDesc: "You don't have any active service requests right now. Tap 'Find Worker' to book a service.",
      active: "Active Requests",
      recent: "Recent Requests",
      pending: "Pending",
      inProgress: "In Progress", 
      completed: "Completed",
      cancelled: "Cancelled",
      viewDetails: "View Details",
      callWorker: "Call Worker",
      chatWorker: "Chat",
      trackWorker: "Track Worker",
      cancel: "Cancel",
      reschedule: "Reschedule",
      eta: "ETA",
      mins: "mins",
      away: "away",
      rating: "Your Rating",
      rateService: "Rate Service"
    },
    hi: {
      title: "मेरी अनुरोध",
      noRequests: "कोई सक्रिय अनुरोध नहीं",
      noRequestsDesc: "आपके पास अभी कोई सक्रिय सेवा अनुरोध नहीं है। सेवा बुक करने के लिए 'कामगार खोजें' पर टैप करें।",
      active: "सक्रिय अनुरोध",
      recent: "हाल के अनुरोध",
      pending: "लंबित",
      inProgress: "प्रगति में",
      completed: "पूर्ण",
      cancelled: "रद्द",
      viewDetails: "विवरण देखें",
      callWorker: "कामगार को कॉल करें",
      chatWorker: "चैट",
      trackWorker: "कामगार को ट्रैक करें",
      cancel: "रद्द करें",
      reschedule: "पुनर्निर्धारण",
      eta: "पहुंचने का समय",
      mins: "मिनट",
      away: "दूर",
      rating: "आपकी रेटिंग",
      rateService: "सेवा को रेट करें"
    },
    mr: {
      title: "माझ्या विनंत्या",
      noRequests: "कोणत्याही सक्रिय विनंत्या नाहीत",
      noRequestsDesc: "तुमच्याकडे सध्या कोणत्याही सक्रिय सेवा विनंत्या नाहीत। सेवा बुक करण्यासाठी 'कामगार शोधा' वर टॅप करा।",
      active: "सक्रिय विनंत्या",
      recent: "अलीकडील विनंत्या",
      pending: "प्रलंबित",
      inProgress: "प्रगतीत",
      completed: "पूर्ण",
      cancelled: "रद्द",
      viewDetails: "तपशील पहा",
      callWorker: "कामगाराला कॉल करा",
      chatWorker: "चॅट",
      trackWorker: "कामगाराचा मागोवा घ्या",
      cancel: "रद्द करा",
      reschedule: "पुनर्निर्धारण",
      eta: "पोहोचण्याची वेळ",
      mins: "मिनिटे",
      away: "अंतरावर",
      rating: "तुमची रेटिंग",
      rateService: "सेवेला रेटिंग द्या"
    }
  };

  const t = texts[language];

  const activeRequests = [
    {
      id: "1",
      service: "Electrical Wiring Repair",
      worker: "Ramesh Kumar",
      status: "inProgress",
      eta: "15",
      location: "Kothrud, Pune",
      amount: "₹800",
      date: "Today",
      time: "2:30 PM",
      workerRating: 4.8,
      description: "Kitchen outlet not working, need urgent repair"
    },
    {
      id: "2",
      service: "AC Installation",
      worker: "Suresh Patel",
      status: "pending", 
      eta: "45",
      location: "Aundh, Pune",
      amount: "₹1500",
      date: "Tomorrow",
      time: "10:00 AM",
      workerRating: 4.9,
      description: "Split AC installation in bedroom"
    }
  ];

  const recentRequests = [
    {
      id: "3",
      service: "Plumbing Repair",
      worker: "Ajay Singh",
      status: "completed",
      location: "Baner, Pune",
      amount: "₹600",
      date: "Yesterday",
      time: "Completed",
      workerRating: 4.7,
      userRating: 5,
      description: "Kitchen tap leak fixed"
    },
    {
      id: "4",
      service: "Wall Painting",
      worker: "Vijay Sharma",
      status: "cancelled",
      location: "Wakad, Pune", 
      amount: "₹2000",
      date: "2 days ago",
      time: "Cancelled",
      workerRating: 4.5,
      userRating: null,
      description: "Living room wall painting"
    }
  ];

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'pending':
        return <Badge className="bg-yellow-100 text-yellow-800">{t.pending}</Badge>;
      case 'inProgress':
        return <Badge className="bg-blue-100 text-blue-800">{t.inProgress}</Badge>;
      case 'completed':
        return <Badge className="bg-green-100 text-green-800">{t.completed}</Badge>;
      case 'cancelled':
        return <Badge className="bg-red-100 text-red-800">{t.cancelled}</Badge>;
      default:
        return null;
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'pending':
        return <Clock className="w-4 h-4 text-yellow-600" />;
      case 'inProgress':
        return <AlertTriangle className="w-4 h-4 text-blue-600" />;
      case 'completed':
        return <CheckCircle className="w-4 h-4 text-green-600" />;
      case 'cancelled':
        return <XCircle className="w-4 h-4 text-red-600" />;
      default:
        return null;
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 pb-20">
      {/* Header */}
      <div className="bg-gradient-to-r from-green-600 to-green-500 text-white p-6 rounded-b-3xl">
        <OfflineBanner isOffline={isOffline} language={language} />
        <div className="flex items-center gap-4 mb-4">
          <Button
            variant="ghost"
            size="icon"
            onClick={onBack}
            className="text-white hover:bg-white/20"
          >
            <ArrowLeft className="w-5 h-5" />
          </Button>
          <h1 className="text-xl">{t.title}</h1>
        </div>
      </div>

      <div className="p-6 space-y-6 -mt-6">
        {/* Active Requests Section */}
        <div>
          <h2 className="text-lg mb-4">{t.active}</h2>
          {activeRequests.length > 0 ? (
            <div className="space-y-4">
              {activeRequests.map((request) => (
                <Card key={request.id} className="border-l-4 border-l-green-600">
                  <CardHeader className="pb-3">
                    <div className="flex items-center justify-between">
                      <CardTitle className="text-base">{request.service}</CardTitle>
                      {getStatusBadge(request.status)}
                    </div>
                  </CardHeader>
                  <CardContent className="pt-0">
                    <div className="space-y-3">
                      <p className="text-sm text-gray-600">{request.description}</p>
                      <div className="flex items-center justify-between text-sm text-gray-600">
                        <span className="flex items-center gap-1">
                          <Star className="w-4 h-4 text-yellow-500 fill-current" />
                          {request.worker} ({request.workerRating})
                        </span>
                        <span className="text-green-600">{request.amount}</span>
                      </div>
                      <div className="flex items-center gap-4 text-sm text-gray-600">
                        <span className="flex items-center gap-1">
                          <MapPin className="w-4 h-4" />
                          {request.location}
                        </span>
                        {request.status === 'inProgress' && (
                          <span className="flex items-center gap-1 text-blue-600">
                            {getStatusIcon(request.status)}
                            {t.eta}: {request.eta} {t.mins}
                          </span>
                        )}
                      </div>
                      <div className="flex gap-2">
                        {request.status === 'inProgress' && (
                          <>
                            <Button size="sm" className="bg-green-600 hover:bg-green-700">
                              {t.trackWorker}
                            </Button>
                            <Button variant="outline" size="sm">
                              <Phone className="w-4 h-4 mr-1" />
                              {t.callWorker}
                            </Button>
                            <Button variant="outline" size="sm">
                              <MessageCircle className="w-4 h-4 mr-1" />
                              {t.chatWorker}
                            </Button>
                          </>
                        )}
                        {request.status === 'pending' && (
                          <>
                            <Button variant="outline" size="sm" className="flex-1">
                              {t.reschedule}
                            </Button>
                            <Button variant="outline" size="sm" className="flex-1 text-red-600 border-red-200">
                              {t.cancel}
                            </Button>
                          </>
                        )}
                        <Button variant="ghost" size="sm" className="text-green-600">
                          {t.viewDetails}
                        </Button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          ) : (
            <Card>
              <CardContent className="p-8 text-center">
                <div className="text-gray-400 mb-4">
                  <Clock className="w-12 h-12 mx-auto" />
                </div>
                <h3 className="text-lg mb-2">{t.noRequests}</h3>
                <p className="text-gray-600 text-sm">{t.noRequestsDesc}</p>
              </CardContent>
            </Card>
          )}
        </div>

        {/* Recent Requests Section */}
        <div>
          <h2 className="text-lg mb-4">{t.recent}</h2>
          <div className="space-y-4">
            {recentRequests.map((request) => (
              <Card key={request.id}>
                <CardHeader className="pb-3">
                  <div className="flex items-center justify-between">
                    <CardTitle className="text-base">{request.service}</CardTitle>
                    {getStatusBadge(request.status)}
                  </div>
                </CardHeader>
                <CardContent className="pt-0">
                  <div className="space-y-3">
                    <p className="text-sm text-gray-600">{request.description}</p>
                    <div className="flex items-center justify-between text-sm text-gray-600">
                      <span className="flex items-center gap-1">
                        <Star className="w-4 h-4 text-yellow-500 fill-current" />
                        {request.worker} ({request.workerRating})
                      </span>
                      <span className="text-green-600">{request.amount}</span>
                    </div>
                    <div className="flex items-center justify-between text-sm text-gray-600">
                      <span className="flex items-center gap-1">
                        <MapPin className="w-4 h-4" />
                        {request.location}
                      </span>
                      {request.status === 'completed' && request.userRating && (
                        <div className="flex items-center gap-1">
                          <Star className="w-4 h-4 text-yellow-500 fill-current" />
                          <span>{t.rating}: {request.userRating}/5</span>
                        </div>
                      )}
                    </div>
                    <div className="flex items-center justify-between text-xs text-gray-500">
                      <span>{request.date}</span>
                      <div className="flex gap-2">
                        {request.status === 'completed' && !request.userRating && (
                          <Button variant="outline" size="sm" className="h-auto p-1 text-xs text-green-600 border-green-200">
                            {t.rateService}
                          </Button>
                        )}
                        <Button variant="ghost" size="sm" className="h-auto p-1 text-xs text-green-600">
                          {t.viewDetails}
                        </Button>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      </div>

      {/* Floating Voice Button */}
      <div className="fixed bottom-6 right-6">
        <VoiceButton onClick={onVoiceCommand} size="lg" />
      </div>
    </div>
  );
}