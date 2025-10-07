import { ArrowLeft, MapPin, Clock, Filter, Star, Zap, Search } from 'lucide-react';
import { Button } from '../ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Input } from '../ui/input';
import { VoiceButton } from '../VoiceButton';
import { OfflineBanner } from '../OfflineBanner';

interface FindWorkProps {
  language: 'en' | 'hi' | 'mr';
  isOffline: boolean;
  onBack: () => void;
  onVoiceCommand: () => void;
}

export function FindWork({ language, isOffline, onBack, onVoiceCommand }: FindWorkProps) {
  const texts = {
    en: {
      title: "Find Work",
      searchPlaceholder: "Search for jobs...",
      filter: "Filter",
      urgent: "Urgent",
      newJob: "New",
      highPaying: "High Pay",
      nearYou: "Near You",
      apply: "Apply Now",
      viewDetails: "View Details",
      away: "away",
      ago: "ago",
      hour: "hour",
      hours: "hours",
      minute: "minute",
      minutes: "minutes",
      noJobs: "No jobs found",
      noJobsDesc: "Try adjusting your search or check back later for new opportunities.",
      recommended: "Recommended for You",
      allJobs: "All Available Jobs"
    },
    hi: {
      title: "काम खोजें",
      searchPlaceholder: "नौकरियों की खोज करें...",
      filter: "फ़िल्टर",
      urgent: "तत्काल",
      newJob: "नया",
      highPaying: "अच्छी तनख्वाह",
      nearYou: "आपके पास",
      apply: "अभी आवेदन करें",
      viewDetails: "विवरण देखें", 
      away: "दूर",
      ago: "पहले",
      hour: "घंटा",
      hours: "घंटे",
      minute: "मिनट",
      minutes: "मिनट",
      noJobs: "कोई काम नहीं मिला",
      noJobsDesc: "अपनी खोज को समायोजित करने का प्रयास करें या नए अवसरों के लिए बाद में वापस आएं।",
      recommended: "आपके लिए सुझाया गया",
      allJobs: "सभी उपलब्ध काम"
    },
    mr: {
      title: "काम शोधा",
      searchPlaceholder: "नोकऱ्या शोधा...",
      filter: "फिल्टर",
      urgent: "तातडीचे",
      newJob: "नवीन",
      highPaying: "चांगला पगार",
      nearYou: "तुमच्या जवळ",
      apply: "आता अर्ज करा",
      viewDetails: "तपशील पहा",
      away: "अंतरावर", 
      ago: "आधी",
      hour: "तास",
      hours: "तास",
      minute: "मिनिट",
      minutes: "मिनिटे",
      noJobs: "कोणतीही कामे मिळाली नाहीत",
      noJobsDesc: "तुमचा शोध समायोजित करण्याचा प्रयत्न करा किंवा नवीन संधींसाठी नंतर परत या।",
      recommended: "तुमच्यासाठी शिफारस केलेले",
      allJobs: "सर्व उपलब्ध कामे"
    }
  };

  const t = texts[language];

  const recommendedJobs = [
    {
      id: "1",
      title: "Electrical Wiring Repair",
      description: "Kitchen electrical outlet repair needed urgently",
      client: "Mehta Family",
      location: "Kothrud, Pune",
      distance: "0.8 km",
      amount: "₹800-1200",
      timePosted: "30 minutes",
      isUrgent: true,
      isNew: true,
      rating: 4.8,
      tags: ["Electrical", "Urgent"]
    },
    {
      id: "2",
      title: "Bathroom Plumbing",
      description: "Leaking tap and shower head installation",
      client: "Sharma Residence",
      location: "Aundh, Pune",
      distance: "1.5 km",
      amount: "₹600-900",
      timePosted: "1 hour",
      isUrgent: false,
      isNew: true,
      rating: 4.9,
      tags: ["Plumbing"]
    }
  ];

  const allJobs = [
    {
      id: "3",
      title: "AC Installation",
      description: "Split AC installation in 2 bedrooms",
      client: "Patel Family",
      location: "Baner, Pune",
      distance: "2.1 km",
      amount: "₹1500-2000",
      timePosted: "2 hours",
      isUrgent: false,
      isNew: false,
      rating: 4.7,
      tags: ["AC", "Installation"]
    },
    {
      id: "4",
      title: "Wall Painting",
      description: "Living room and bedroom painting work",
      client: "Kumar Residence",
      location: "Wakad, Pune",
      distance: "3.2 km",
      amount: "₹2500-3500",
      timePosted: "3 hours",
      isUrgent: false,
      isNew: false,
      rating: 4.6,
      tags: ["Painting"]
    },
    {
      id: "5",
      title: "Kitchen Renovation",
      description: "Complete kitchen modular renovation",
      client: "Singh Family",
      location: "Hinjewadi, Pune",
      distance: "4.8 km",
      amount: "₹5000-8000",
      timePosted: "5 hours",
      isUrgent: false,
      isNew: false,
      rating: 4.9,
      tags: ["Renovation", "Kitchen"]
    }
  ];

  const getTimeText = (timePosted: string) => {
    const num = parseInt(timePosted);
    if (timePosted.includes('minute')) {
      return `${num} ${num === 1 ? t.minute : t.minutes} ${t.ago}`;
    } else if (timePosted.includes('hour')) {
      return `${num} ${num === 1 ? t.hour : t.hours} ${t.ago}`;
    }
    return `${timePosted} ${t.ago}`;
  };

  const JobCard = ({ job, showRecommended = false }: { job: any; showRecommended?: boolean }) => (
    <Card className={`transition-all hover:shadow-lg ${showRecommended ? 'border-l-4 border-l-primary' : ''}`}>
      <CardHeader className="pb-3">
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <CardTitle className="text-base mb-1">{job.title}</CardTitle>
            <p className="text-sm text-gray-600 mb-2">{job.description}</p>
            <div className="flex items-center gap-2 flex-wrap">
              {job.isUrgent && (
                <Badge className="bg-red-100 text-red-800 text-xs">
                  <Zap className="w-3 h-3 mr-1" />
                  {t.urgent}
                </Badge>
              )}
              {job.isNew && (
                <Badge className="bg-blue-100 text-blue-800 text-xs">
                  {t.newJob}
                </Badge>
              )}
              {parseInt(job.amount.split('-')[1].replace('₹', '')) > 2000 && (
                <Badge className="bg-green-100 text-green-800 text-xs">
                  {t.highPaying}
                </Badge>
              )}
            </div>
          </div>
          <div className="text-right">
            <p className="text-primary text-sm">{job.amount}</p>
          </div>
        </div>
      </CardHeader>
      <CardContent className="pt-0">
        <div className="space-y-3">
          <div className="flex items-center justify-between text-sm text-gray-600">
            <span>{job.client}</span>
            <div className="flex items-center gap-1">
              <Star className="w-3 h-3 text-yellow-500 fill-current" />
              <span>{job.rating}</span>
            </div>
          </div>
          <div className="flex items-center justify-between text-sm text-gray-600">
            <span className="flex items-center gap-1">
              <MapPin className="w-4 h-4" />
              {job.location} • {job.distance} {t.away}
            </span>
            <span className="flex items-center gap-1">
              <Clock className="w-4 h-4" />
              {getTimeText(job.timePosted)}
            </span>
          </div>
          <div className="flex gap-2">
            <Button size="sm" className="flex-1 bg-accent hover:bg-accent/90">
              {t.apply}
            </Button>
            <Button variant="outline" size="sm" className="flex-1">
              {t.viewDetails}
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  );

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
        
        {/* Search Bar */}
        <div className="flex gap-2">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
            <Input
              placeholder={t.searchPlaceholder}
              className="pl-10 bg-white/10 border-white/20 text-white placeholder:text-white/70"
            />
          </div>
          <Button variant="ghost" size="icon" className="text-white hover:bg-white/20">
            <Filter className="w-5 h-5" />
          </Button>
        </div>
      </div>

      <div className="p-6 space-y-6 -mt-6">
        {/* Recommended Jobs Section */}
        <div>
          <h2 className="text-lg mb-4">{t.recommended}</h2>
          <div className="space-y-4">
            {recommendedJobs.map((job) => (
              <JobCard key={job.id} job={job} showRecommended={true} />
            ))}
          </div>
        </div>

        {/* All Jobs Section */}
        <div>
          <h2 className="text-lg mb-4">{t.allJobs}</h2>
          <div className="space-y-4">
            {allJobs.map((job) => (
              <JobCard key={job.id} job={job} />
            ))}
          </div>
        </div>

        {/* No Jobs State (hidden for demo) */}
        {false && (
          <Card>
            <CardContent className="p-8 text-center">
              <div className="text-gray-400 mb-4">
                <Search className="w-12 h-12 mx-auto" />
              </div>
              <h3 className="text-lg mb-2">{t.noJobs}</h3>
              <p className="text-gray-600 text-sm">{t.noJobsDesc}</p>
            </CardContent>
          </Card>
        )}
      </div>

      {/* Floating Voice Button */}
      <div className="fixed bottom-6 right-6">
        <VoiceButton onClick={onVoiceCommand} size="lg" />
      </div>
    </div>
  );
}