import { ArrowLeft, Phone, MessageCircle, Book, FileText, Users, Star, ExternalLink, ChevronRight } from 'lucide-react';
import { Button } from '../ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from '../ui/accordion';
import { VoiceButton } from '../VoiceButton';
import { OfflineBanner } from '../OfflineBanner';

interface HelpProps {
  language: 'en' | 'hi' | 'mr';
  isOffline: boolean;
  onBack: () => void;
  onVoiceCommand: () => void;
}

export function Help({ language, isOffline, onBack, onVoiceCommand }: HelpProps) {
  const texts = {
    en: {
      title: "Help & Support",
      quickActions: "Quick Actions",
      callSupport: "Call Support",
      chatSupport: "Chat Support",
      tutorials: "Video Tutorials",
      faq: "FAQ",
      community: "Community",
      feedback: "Send Feedback",
      contactUs: "Contact Us",
      availableNow: "Available Now",
      online: "Online",
      frequently: "Frequently Asked Questions",
      howToUse: "How to Use VoiceSewa",
      payment: "Payment & Earnings",
      jobManagement: "Job Management",
      account: "Account Settings",
      technical: "Technical Issues",
      policies: "Policies & Terms",
      version: "App Version",
      supportHours: "Support Hours: 6 AM - 10 PM",
      rating: "Rate Our App",
      share: "Share VoiceSewa",
      languages: "Change Language",
      // FAQ content
      howToFindWork: "How do I find work on VoiceSewa?",
      howToFindWorkAnswer: "You can find work by going to 'Find Work' section. Use voice commands or browse available jobs in your area. Jobs are sorted by distance and urgency.",
      howPaymentWorks: "How does payment work?",
      howPaymentWorksAnswer: "Payment is processed after job completion and client approval. Earnings are added to your wallet and can be withdrawn to your bank account.",
      voiceNotWorking: "Voice commands not working?",
      voiceNotWorkingAnswer: "Check your microphone permissions and internet connection. Try speaking clearly in Hindi, Marathi, or English.",
      updateProfile: "How to update my profile?",
      updateProfileAnswer: "Go to Profile section and tap 'Edit Profile'. You can update your skills, location, and contact information.",
      offlineMode: "Does offline mode work?",
      offlineModeAnswer: "Yes, you can view your jobs and basic information offline. New job notifications require internet connection."
    },
    hi: {
      title: "सहायता और समर्थन",
      quickActions: "त्वरित कार्य",
      callSupport: "सहायता कॉल करें",
      chatSupport: "चैट सहायता",
      tutorials: "वीडियो ट्यूटोरियल",
      faq: "अक्सर पूछे जाने वाले प्रश्न",
      community: "समुदाय",
      feedback: "फीडबैक भेजें",
      contactUs: "हमसे संपर्क करें",
      availableNow: "अभी उपलब्ध",
      online: "ऑनलाइन",
      frequently: "अक्सर पूछे जाने वाले प्रश्न",
      howToUse: "VoiceSewa का उपयोग कैसे करें",
      payment: "भुगतान और कमाई",
      jobManagement: "काम प्रबंधन",
      account: "खाता सेटिंग्स",
      technical: "तकनीकी समस्याएं",
      policies: "नीतियां और नियम",
      version: "ऐप संस्करण",
      supportHours: "सहायता समय: सुबह 6 बजे - रात 10 बजे",
      rating: "हमारे ऐप को रेट करें",
      share: "VoiceSewa साझा करें",
      languages: "भाषा बदलें",
      // FAQ content
      howToFindWork: "मैं VoiceSewa पर काम कैसे खोजूं?",
      howToFindWorkAnswer: "'काम खोजें' सेक्शन में जाकर आप काम पा सकते हैं। वॉयस कमांड का उपयोग करें या अपने क्षेत्र में उपलब्ध काम देखें।",
      howPaymentWorks: "भुगतान कैसे काम करता है?",
      howPaymentWorksAnswer: "काम पूरा होने और ग्राहक की मंजूरी के बाद भुगतान प्रक्रिया होती है। कमाई आपके वॉलेट में जुड़ जाती है।",
      voiceNotWorking: "वॉयस कमांड काम नहीं कर रहे?",
      voiceNotWorkingAnswer: "अपनी माइक्रोफोन अनुमतियां और इंटरनेट कनेक्शन जांचें। हिंदी, मराठी या अंग्रेजी में स्पष्ट रूप से बोलने की कोशिश करें।",
      updateProfile: "अपनी प्रोफ़ाइल कैसे अपडेट करूं?",
      updateProfileAnswer: "प्रोफ़ाइल सेक्शन में जाएं और 'प्रोफ़ाइल संपादित करें' पर टैप करें। आप अपने कौशल, स्थान और संपर्क जानकारी अपडेट कर सकते हैं।",
      offlineMode: "क्या ऑफ़लाइन मोड काम करता है?",
      offlineModeAnswer: "हाँ, आप अपने काम और बुनियादी जानकारी ऑफ़लाइन देख सकते हैं। नई नौकरी की सूचनाओं के लिए इंटरनेट कनेक्शन आवश्यक है।"
    },
    mr: {
      title: "मदत आणि समर्थन",
      quickActions: "द्रुत क्रिया",
      callSupport: "समर्थनास कॉल करा",
      chatSupport: "चॅट समर्थन",
      tutorials: "व्हिडिओ ट्यूटोरियल",
      faq: "वारंवार विचारले जाणारे प्रश्न",
      community: "समुदाय",
      feedback: "फीडबॅक पाठवा",
      contactUs: "आमच्याशी संपर्क साधा",
      availableNow: "आता उपलब्ध",
      online: "ऑनलाइन",
      frequently: "वारंवार विचारले जाणारे प्रश्न",
      howToUse: "VoiceSewa कसे वापरावे",
      payment: "पेमेंट आणि कमाई",
      jobManagement: "काम व्यवस्थापन",
      account: "खाते सेटिंग्ज",
      technical: "तांत्रिक समस्या",
      policies: "धोरणे आणि अटी",
      version: "अॅप आवृत्ती",
      supportHours: "समर्थन वेळा: सकाळी 6 वाजे - रात्री 10 वाजे",
      rating: "आमच्या अॅपला रेटिंग द्या",
      share: "VoiceSewa शेअर करा",
      languages: "भाषा बदला",
      // FAQ content
      howToFindWork: "मी VoiceSewa वर काम कसे शोधू?",
      howToFindWorkAnswer: "'काम शोधा' विभागात जाऊन तुम्ही काम मिळवू शकता। व्हॉइस कमांड वापरा किंवा तुमच्या भागात उपलब्ध कामे पहा।",
      howPaymentWorks: "पेमेंट कसे काम करते?",
      howPaymentWorksAnswer: "काम पूर्ण झाल्यानंतर आणि ग्राहकाच्या मंजुरीनंतर पेमेंट प्रोसेस होते। कमाई तुमच्या वॉलेटमध्ये जोडली जाते.",
      voiceNotWorking: "व्हॉइस कमांड काम करत नाहीत?",
      voiceNotWorkingAnswer: "तुमच्या मायक्रोफोन परवानग्या आणि इंटरनेट कनेक्शन तपासा। हिंदी, मराठी किंवा इंग्रजीमध्ये स्पष्टपणे बोलण्याचा प्रयत्न करा।",
      updateProfile: "माझी प्रोफाइल कशी अपडेट करावी?",
      updateProfileAnswer: "प्रोफाइल विभागात जा आणि 'प्रोफाइल संपादित करा' वर टॅप करा। तुम्ही तुमची कौशल्ये, स्थान आणि संपर्क माहिती अपडेट करू शकता।",
      offlineMode: "ऑफलाइन मोड काम करतो का?",
      offlineModeAnswer: "होय, तुम्ही तुमची कामे आणि मूलभूत माहिती ऑफलाइन पाहू शकता. नवीन नोकरीच्या सूचनांसाठी इंटरनेट कनेक्शन आवश्यक आहे."
    }
  };

  const t = texts[language];

  const faqItems = [
    {
      question: t.howToFindWork,
      answer: t.howToFindWorkAnswer
    },
    {
      question: t.howPaymentWorks,
      answer: t.howPaymentWorksAnswer
    },
    {
      question: t.voiceNotWorking,
      answer: t.voiceNotWorkingAnswer
    },
    {
      question: t.updateProfile,
      answer: t.updateProfileAnswer
    },
    {
      question: t.offlineMode,
      answer: t.offlineModeAnswer
    }
  ];

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
        {/* Quick Actions */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base">{t.quickActions}</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 gap-4">
              <Button 
                variant="outline" 
                className="h-auto p-4 flex flex-col items-center gap-2"
              >
                <Phone className="w-6 h-6 text-green-600" />
                <div className="text-center">
                  <p className="text-sm">{t.callSupport}</p>
                  <Badge variant="secondary" className="bg-green-100 text-green-800 text-xs mt-1">
                    {t.availableNow}
                  </Badge>
                </div>
              </Button>
              
              <Button 
                variant="outline" 
                className="h-auto p-4 flex flex-col items-center gap-2"
              >
                <MessageCircle className="w-6 h-6 text-blue-600" />
                <div className="text-center">
                  <p className="text-sm">{t.chatSupport}</p>
                  <Badge variant="secondary" className="bg-blue-100 text-blue-800 text-xs mt-1">
                    {t.online}
                  </Badge>
                </div>
              </Button>
              
              <Button 
                variant="outline" 
                className="h-auto p-4 flex flex-col items-center gap-2"
              >
                <Book className="w-6 h-6 text-purple-600" />
                <p className="text-sm">{t.tutorials}</p>
              </Button>
              
              <Button 
                variant="outline" 
                className="h-auto p-4 flex flex-col items-center gap-2"
              >
                <Users className="w-6 h-6 text-orange-600" />
                <p className="text-sm">{t.community}</p>
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* FAQ Section */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base">{t.frequently}</CardTitle>
          </CardHeader>
          <CardContent>
            <Accordion type="single" collapsible className="w-full">
              {faqItems.map((item, index) => (
                <AccordionItem key={index} value={`item-${index}`}>
                  <AccordionTrigger className="text-left text-sm">
                    {item.question}
                  </AccordionTrigger>
                  <AccordionContent className="text-sm text-gray-600">
                    {item.answer}
                  </AccordionContent>
                </AccordionItem>
              ))}
            </Accordion>
          </CardContent>
        </Card>

        {/* Help Categories */}
        <div className="space-y-3">
          <h3 className="text-lg">{t.howToUse}</h3>
          
          <Card className="cursor-pointer hover:bg-gray-50 transition-colors">
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <Book className="w-5 h-5 text-blue-600" />
                  <span className="text-sm">{t.howToUse}</span>
                </div>
                <ChevronRight className="w-4 h-4 text-gray-400" />
              </div>
            </CardContent>
          </Card>

          <Card className="cursor-pointer hover:bg-gray-50 transition-colors">
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <FileText className="w-5 h-5 text-green-600" />
                  <span className="text-sm">{t.payment}</span>
                </div>
                <ChevronRight className="w-4 h-4 text-gray-400" />
              </div>
            </CardContent>
          </Card>

          <Card className="cursor-pointer hover:bg-gray-50 transition-colors">
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <Users className="w-5 h-5 text-purple-600" />
                  <span className="text-sm">{t.jobManagement}</span>
                </div>
                <ChevronRight className="w-4 h-4 text-gray-400" />
              </div>
            </CardContent>
          </Card>

          <Card className="cursor-pointer hover:bg-gray-50 transition-colors">
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <Star className="w-5 h-5 text-orange-600" />
                  <span className="text-sm">{t.account}</span>
                </div>
                <ChevronRight className="w-4 h-4 text-gray-400" />
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Contact & Feedback */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base">{t.contactUs}</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <p className="text-sm text-gray-600">{t.supportHours}</p>
              
              <div className="flex gap-2">
                <Button variant="outline" className="flex-1">
                  <Star className="w-4 h-4 mr-2" />
                  {t.rating}
                </Button>
                <Button variant="outline" className="flex-1">
                  <ExternalLink className="w-4 h-4 mr-2" />
                  {t.share}
                </Button>
              </div>
              
              <Button variant="outline" className="w-full">
                <MessageCircle className="w-4 h-4 mr-2" />
                {t.feedback}
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* App Info */}
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between text-sm text-gray-600">
              <span>{t.version}</span>
              <span>1.2.0</span>
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