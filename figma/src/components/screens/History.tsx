import { ArrowLeft, Calendar, Filter, Search, Star, MapPin, CheckCircle, XCircle, Download, Eye } from 'lucide-react';
import { Button } from '../ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Input } from '../ui/input';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { VoiceButton } from '../VoiceButton';
import { OfflineBanner } from '../OfflineBanner';

interface HistoryProps {
  language: 'en' | 'hi' | 'mr';
  isOffline: boolean;
  onBack: () => void;
  onVoiceCommand: () => void;
}

export function History({ language, isOffline, onBack, onVoiceCommand }: HistoryProps) {
  const texts = {
    en: {
      title: "Service History",
      searchPlaceholder: "Search by service or worker...",
      filter: "Filter",
      all: "All",
      completed: "Completed",
      cancelled: "Cancelled",
      thisMonth: "This Month",
      lastMonth: "Last Month",
      older: "Older",
      totalSpent: "Total Spent",
      servicesCompleted: "Services Completed",
      avgRating: "Average Rating",
      viewDetails: "View Details",
      rateAgain: "Rate Again",
      bookAgain: "Book Again",
      downloadInvoice: "Download Invoice",
      noHistory: "No service history",
      noHistoryDesc: "You haven't used any services yet. Start by booking your first service!",
      rating: "Your Rating",
      worker: "Worker",
      amount: "Amount"
    },
    hi: {
      title: "सेवा इतिहास",
      searchPlaceholder: "सेवा या कामगार द्वारा खोजें...",
      filter: "फ़िल्टर",
      all: "सभी",
      completed: "पूर्ण",
      cancelled: "रद्द",
      thisMonth: "इस महीने",
      lastMonth: "पिछले महीने",
      older: "पुराने",
      totalSpent: "कुल खर्च",
      servicesCompleted: "पूर्ण सेवाएं",
      avgRating: "औसत रेटिंग",
      viewDetails: "विवरण देखें",
      rateAgain: "फिर से रेट करें",
      bookAgain: "फिर से बुक करें",
      downloadInvoice: "बिल डाउनलोड करें",
      noHistory: "कोई सेवा इतिहास नहीं",
      noHistoryDesc: "आपने अभी तक कोई सेवा का उपयोग नहीं किया है। अपनी पहली सेवा बुक करके शुरू करें!",
      rating: "आपकी रेटिंग",
      worker: "कामगार",
      amount: "राशि"
    },
    mr: {
      title: "सेवा इतिहास",
      searchPlaceholder: "सेवा किंवा कामगाराद्वारे शोधा...",
      filter: "फिल्टर",
      all: "सर्व",
      completed: "पूर्ण",
      cancelled: "रद्द",
      thisMonth: "या महिन्यात",
      lastMonth: "गेल्या महिन्यात",
      older: "जुने",
      totalSpent: "एकूण खर्च",
      servicesCompleted: "पूर्ण सेवा",
      avgRating: "सरासरी रेटिंग",
      viewDetails: "तपशील पहा",
      rateAgain: "पुन्हा रेट करा",
      bookAgain: "पुन्हा बुक करा",
      downloadInvoice: "बिल डाउनलोड करा",
      noHistory: "कोणताही सेवा इतिहास नाही",
      noHistoryDesc: "तुम्ही अजून कोणत्याही सेवेचा वापर केला नाही. तुमची पहिली सेवा बुक करून सुरुवात करा!",
      rating: "तुमची रेटिंग",
      worker: "कामगार",
      amount: "रक्कम"
    }
  };

  const t = texts[language];

  const stats = {
    totalSpent: 12500,
    servicesCompleted: 15,
    avgRating: 4.6
  };

  const historyData = {
    thisMonth: [
      {
        id: "1",
        service: "Electrical Repair",
        worker: "Ramesh Kumar",
        status: "completed",
        date: "Dec 15, 2024",
        location: "Kothrud, Pune",
        amount: "₹800",
        rating: 5,
        workerRating: 4.8,
        description: "Kitchen outlet repair"
      },
      {
        id: "2",
        service: "Plumbing Service",
        worker: "Suresh Patel",
        status: "completed",
        date: "Dec 12, 2024",
        location: "Aundh, Pune",
        amount: "₹600",
        rating: 4,
        workerRating: 4.7,
        description: "Bathroom tap leak fix"
      },
      {
        id: "3",
        service: "AC Installation",
        worker: "Vijay Sharma",
        status: "cancelled",
        date: "Dec 8, 2024",
        location: "Baner, Pune",
        amount: "₹1500",
        rating: null,
        workerRating: 4.5,
        description: "Split AC installation"
      }
    ],
    lastMonth: [
      {
        id: "4",
        service: "Wall Painting",
        worker: "Ajay Singh", 
        status: "completed",
        date: "Nov 28, 2024",
        location: "Wakad, Pune",
        amount: "₹2500",
        rating: 5,
        workerRating: 4.9,
        description: "Living room painting"
      },
      {
        id: "5",
        service: "Carpentry Work",
        worker: "Mohan Kumar",
        status: "completed",
        date: "Nov 20, 2024",
        location: "Kothrud, Pune",
        amount: "₹1200",
        rating: 4,
        workerRating: 4.6,
        description: "Kitchen cabinet repair"
      }
    ],
    older: [
      {
        id: "6",
        service: "Electrical Installation",
        worker: "Ravi Patel",
        status: "completed",
        date: "Oct 15, 2024",
        location: "Aundh, Pune",
        amount: "₹1800",
        rating: 5,
        workerRating: 4.8,
        description: "Ceiling fan installation"
      }
    ]
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
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
      case 'completed':
        return <CheckCircle className="w-4 h-4 text-green-600" />;
      case 'cancelled':
        return <XCircle className="w-4 h-4 text-red-600" />;
      default:
        return null;
    }
  };

  const HistoryCard = ({ item }: { item: any }) => (
    <Card>
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <CardTitle className="text-base">{item.service}</CardTitle>
          {getStatusBadge(item.status)}
        </div>
      </CardHeader>
      <CardContent className="pt-0">
        <div className="space-y-3">
          <p className="text-sm text-gray-600">{item.description}</p>
          <div className="flex items-center justify-between text-sm text-gray-600">
            <span className="flex items-center gap-1">
              <Star className="w-4 h-4 text-yellow-500 fill-current" />
              {item.worker} ({item.workerRating})
            </span>
            <span className="text-green-600">{item.amount}</span>
          </div>
          <div className="flex items-center justify-between text-sm text-gray-600">
            <span className="flex items-center gap-1">
              <MapPin className="w-4 h-4" />
              {item.location}
            </span>
            {item.status === 'completed' && item.rating && (
              <div className="flex items-center gap-1">
                <Star className="w-4 h-4 text-yellow-500 fill-current" />
                <span>{t.rating}: {item.rating}/5</span>
              </div>
            )}
          </div>
          <div className="flex items-center justify-between text-xs text-gray-500">
            <span>{item.date}</span>
            <div className="flex gap-2">
              {item.status === 'completed' && (
                <>
                  <Button variant="outline" size="sm" className="h-auto p-1 text-xs text-green-600 border-green-200">
                    {t.bookAgain}
                  </Button>
                  <Button variant="outline" size="sm" className="h-auto p-1 text-xs">
                    <Download className="w-3 h-3 mr-1" />
                    {t.downloadInvoice}
                  </Button>
                </>
              )}
              <Button variant="ghost" size="sm" className="h-auto p-1 text-xs text-green-600">
                <Eye className="w-3 h-3 mr-1" />
                {t.viewDetails}
              </Button>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );

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
        {/* Stats Cards */}
        <div className="grid grid-cols-3 gap-4">
          <Card>
            <CardContent className="p-4 text-center">
              <p className="text-2xl text-green-600">₹{stats.totalSpent.toLocaleString()}</p>
              <p className="text-xs text-gray-600">{t.totalSpent}</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4 text-center">
              <p className="text-2xl text-blue-600">{stats.servicesCompleted}</p>
              <p className="text-xs text-gray-600">{t.servicesCompleted}</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4 text-center">
              <div className="flex items-center justify-center gap-1">
                <Star className="w-4 h-4 text-yellow-500 fill-current" />
                <p className="text-2xl">{stats.avgRating}</p>
              </div>
              <p className="text-xs text-gray-600">{t.avgRating}</p>
            </CardContent>
          </Card>
        </div>

        {/* History Tabs */}
        <Tabs defaultValue="thisMonth" className="w-full">
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="thisMonth">{t.thisMonth}</TabsTrigger>
            <TabsTrigger value="lastMonth">{t.lastMonth}</TabsTrigger>
            <TabsTrigger value="older">{t.older}</TabsTrigger>
          </TabsList>
          
          <TabsContent value="thisMonth" className="space-y-4 mt-6">
            {historyData.thisMonth.length > 0 ? (
              historyData.thisMonth.map((item) => (
                <HistoryCard key={item.id} item={item} />
              ))
            ) : (
              <Card>
                <CardContent className="p-8 text-center">
                  <div className="text-gray-400 mb-4">
                    <Calendar className="w-12 h-12 mx-auto" />
                  </div>
                  <h3 className="text-lg mb-2">{t.noHistory}</h3>
                  <p className="text-gray-600 text-sm">{t.noHistoryDesc}</p>
                </CardContent>
              </Card>
            )}
          </TabsContent>
          
          <TabsContent value="lastMonth" className="space-y-4 mt-6">
            {historyData.lastMonth.map((item) => (
              <HistoryCard key={item.id} item={item} />
            ))}
          </TabsContent>
          
          <TabsContent value="older" className="space-y-4 mt-6">
            {historyData.older.map((item) => (
              <HistoryCard key={item.id} item={item} />
            ))}
          </TabsContent>
        </Tabs>
      </div>

      {/* Floating Voice Button */}
      <div className="fixed bottom-6 right-6">
        <VoiceButton onClick={onVoiceCommand} size="lg" />
      </div>
    </div>
  );
}