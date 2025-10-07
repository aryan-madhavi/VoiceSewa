import { ArrowLeft, Clock, MapPin, Star, CheckCircle, AlertCircle, Phone } from 'lucide-react';
import { Button } from '../ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { VoiceButton } from '../VoiceButton';
import { OfflineBanner } from '../OfflineBanner';

interface MyJobsProps {
  language: 'en' | 'hi' | 'mr';
  isOffline: boolean;
  onBack: () => void;
  onVoiceCommand: () => void;
}

export function MyJobs({ language, isOffline, onBack, onVoiceCommand }: MyJobsProps) {
  const texts = {
    en: {
      title: "My Jobs",
      noJobs: "No active jobs",
      noJobsDesc: "You don't have any active jobs right now. Check 'Find Work' to discover new opportunities.",
      ongoing: "Ongoing",
      completed: "Completed",
      pending: "Pending",
      cancelled: "Cancelled",
      viewDetails: "View Details",
      callClient: "Call Client",
      markComplete: "Mark Complete",
      active: "Active Jobs",
      recent: "Recent Jobs"
    },
    hi: {
      title: "मेरे काम",
      noJobs: "कोई सक्रिय काम नहीं",
      noJobsDesc: "आपके पास अभी कोई सक्रिय काम नहीं है। नए अवसर खोजने के लिए 'काम खोजें' देखें।",
      ongoing: "चालू",
      completed: "पूर्ण",
      pending: "लंबित",
      cancelled: "रद्द",
      viewDetails: "विवरण देखें",
      callClient: "ग्राहक को कॉल करें",
      markComplete: "पूर्ण का निशान लगाएं",
      active: "सक्रिय काम",
      recent: "हाल के काम"
    },
    mr: {
      title: "माझी कामे",
      noJobs: "कोणतीही सक्रिय कामे नाहीत",
      noJobsDesc: "तुमच्याकडे सध्या कोणतीही सक्रिय कामे नाहीत। नवीन संधी शोधण्यासाठी 'काम शोधा' पहा।",
      ongoing: "सुरू",
      completed: "पूर्ण",
      pending: "प्रलंबित",
      cancelled: "रद्द",
      viewDetails: "तपशील पहा",
      callClient: "ग्राहकाला कॉल करा",
      markComplete: "पूर्ण म्हणून चिन्हांकित करा",
      active: "सक्रिय कामे",
      recent: "अलीकडील कामे"
    }
  };

  const t = texts[language];

  const activeJobs = [
    {
      id: "1",
      title: "Electrical Wiring Installation",
      client: "Sharma Family",
      location: "Kothrud, Pune",
      amount: "₹1,200",
      status: "ongoing",
      date: "Today",
      time: "2:00 PM",
      rating: null
    },
    {
      id: "2", 
      title: "Kitchen Plumbing Repair",
      client: "Patel Residence",
      location: "Aundh, Pune",
      amount: "₹800",
      status: "pending",
      date: "Tomorrow",
      time: "10:00 AM",
      rating: null
    }
  ];

  const recentJobs = [
    {
      id: "3",
      title: "Bathroom Renovation",
      client: "Kumar Family",
      location: "Baner, Pune",
      amount: "₹2,500",
      status: "completed",
      date: "Yesterday",
      time: "Completed",
      rating: 5
    },
    {
      id: "4",
      title: "Ceiling Fan Installation",
      client: "Singh Residence",
      location: "Wakad, Pune",
      amount: "₹600",
      status: "completed",
      date: "2 days ago",
      time: "Completed",
      rating: 4
    }
  ];

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'ongoing':
        return <Badge className="bg-blue-100 text-blue-800">{t.ongoing}</Badge>;
      case 'completed':
        return <Badge className="bg-green-100 text-green-800">{t.completed}</Badge>;
      case 'pending':
        return <Badge className="bg-yellow-100 text-yellow-800">{t.pending}</Badge>;
      case 'cancelled':
        return <Badge className="bg-red-100 text-red-800">{t.cancelled}</Badge>;
      default:
        return null;
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'ongoing':
        return <Clock className="w-4 h-4 text-blue-600" />;
      case 'completed':
        return <CheckCircle className="w-4 h-4 text-green-600" />;
      case 'pending':
        return <AlertCircle className="w-4 h-4 text-yellow-600" />;
      default:
        return null;
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 pb-20">
      {/* Header */}
      <div className="bg-primary text-white p-6 rounded-b-3xl">
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
        {/* Active Jobs Section */}
        <div>
          <h2 className="text-lg mb-4">{t.active}</h2>
          {activeJobs.length > 0 ? (
            <div className="space-y-4">
              {activeJobs.map((job) => (
                <Card key={job.id} className="border-l-4 border-l-primary">
                  <CardHeader className="pb-3">
                    <div className="flex items-center justify-between">
                      <CardTitle className="text-base">{job.title}</CardTitle>
                      {getStatusBadge(job.status)}
                    </div>
                  </CardHeader>
                  <CardContent className="pt-0">
                    <div className="space-y-3">
                      <div className="flex items-center justify-between text-sm text-gray-600">
                        <span>{job.client}</span>
                        <span className="text-primary">{job.amount}</span>
                      </div>
                      <div className="flex items-center gap-4 text-sm text-gray-600">
                        <span className="flex items-center gap-1">
                          <MapPin className="w-4 h-4" />
                          {job.location}
                        </span>
                        <span className="flex items-center gap-1">
                          {getStatusIcon(job.status)}
                          {job.date} • {job.time}
                        </span>
                      </div>
                      <div className="flex gap-2">
                        <Button variant="outline" size="sm" className="flex-1">
                          <Phone className="w-4 h-4 mr-2" />
                          {t.callClient}
                        </Button>
                        {job.status === 'ongoing' && (
                          <Button size="sm" className="flex-1 bg-accent hover:bg-accent/90">
                            {t.markComplete}
                          </Button>
                        )}
                        <Button variant="outline" size="sm" className="flex-1">
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
                <h3 className="text-lg mb-2">{t.noJobs}</h3>
                <p className="text-gray-600 text-sm">{t.noJobsDesc}</p>
              </CardContent>
            </Card>
          )}
        </div>

        {/* Recent Jobs Section */}
        <div>
          <h2 className="text-lg mb-4">{t.recent}</h2>
          <div className="space-y-4">
            {recentJobs.map((job) => (
              <Card key={job.id}>
                <CardHeader className="pb-3">
                  <div className="flex items-center justify-between">
                    <CardTitle className="text-base">{job.title}</CardTitle>
                    {getStatusBadge(job.status)}
                  </div>
                </CardHeader>
                <CardContent className="pt-0">
                  <div className="space-y-3">
                    <div className="flex items-center justify-between text-sm text-gray-600">
                      <span>{job.client}</span>
                      <span className="text-primary">{job.amount}</span>
                    </div>
                    <div className="flex items-center justify-between text-sm text-gray-600">
                      <span className="flex items-center gap-1">
                        <MapPin className="w-4 h-4" />
                        {job.location}
                      </span>
                      {job.rating && (
                        <div className="flex items-center gap-1">
                          <Star className="w-4 h-4 text-yellow-500 fill-current" />
                          <span>{job.rating}/5</span>
                        </div>
                      )}
                    </div>
                    <div className="flex items-center justify-between text-xs text-gray-500">
                      <span>{job.date}</span>
                      <Button variant="ghost" size="sm" className="h-auto p-0 text-primary">
                        {t.viewDetails}
                      </Button>
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