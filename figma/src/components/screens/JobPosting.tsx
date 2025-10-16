import { MapPin, Calendar, Clock, Zap, Wrench, Paintbrush, Hammer, Sparkles, ArrowLeft } from 'lucide-react';
import { Button } from '../ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Textarea } from '../ui/textarea';
import { VoiceButton } from '../VoiceButton';
import { useState } from 'react';

interface JobPostingProps {
  language: 'en' | 'hi' | 'mr';
  onBack: () => void;
  onVoiceCommand: () => void;
  onPost: () => void;
}

export function JobPosting({ language, onBack, onVoiceCommand, onPost }: JobPostingProps) {
  const [selectedService, setSelectedService] = useState<string>('');
  const [description, setDescription] = useState('');

  const texts = {
    en: {
      title: "Post a Job",
      subtitle: "Tell us what work you need done",
      selectService: "Select Service Type",
      electrician: "Electrician",
      plumber: "Plumber",
      painter: "Painter", 
      carpenter: "Carpenter",
      cleaner: "Cleaner",
      describe: "Describe Your Work",
      placeholder: "Tell us about the work you need done...",
      location: "Your Location",
      currentLocation: "Using current location",
      changeLocation: "Change Location",
      timing: "When do you need this?",
      asap: "As soon as possible",
      later: "Schedule for later",
      post: "Post Job",
      voiceDesc: "Describe work using voice"
    },
    hi: {
      title: "नौकरी पोस्ट करें",
      subtitle: "बताएं कि आपको क्या काम करवाना है",
      selectService: "सेवा प्रकार चुनें",
      electrician: "इलेक्ट्रीशियन",
      plumber: "प्लंबर",
      painter: "पेंटर",
      carpenter: "बढ़ई",
      cleaner: "सफाई",
      describe: "अपना काम बताएं",
      placeholder: "बताएं कि आपको कौन सा काम करवाना है...",
      location: "आपका स्थान",
      currentLocation: "वर्तमान स्थान का उपयोग",
      changeLocation: "स्थान बदलें",
      timing: "आपको यह कब चाहिए?",
      asap: "जितनी जल्दी हो सके",
      later: "बाद के लिए निर्धारित करें",
      post: "नौकरी पोस्ट करें",
      voiceDesc: "आवाज़ से काम का विवरण दें"
    },
    mr: {
      title: "नोकरी पोस्ट करा",
      subtitle: "सांगा की तुम्हाला काय काम करायचे आहे",
      selectService: "सेवा प्रकार निवडा",
      electrician: "इलेक्ट्रिशियन",
      plumber: "प्लंबर",
      painter: "पेंटर",
      carpenter: "सुतार",
      cleaner: "स्वच्छता",
      describe: "तुमचे काम सांगा",
      placeholder: "सांगा की तुम्हाला कोणते काम करायचे आहे...",
      location: "तुमचे स्थान",
      currentLocation: "सध्याचे स्थान वापरत आहे",
      changeLocation: "स्थान बदला",
      timing: "तुम्हाला हे कधी हवे आहे?",
      asap: "शक्य तितक्या लवकर",
      later: "नंतरसाठी निर्धारित करा",
      post: "नोकरी पोस्ट करा",
      voiceDesc: "आवाजाने कामाचे वर्णन करा"
    }
  };

  const t = texts[language];

  const services = [
    { name: t.electrician, icon: Zap, color: 'bg-yellow-100 text-yellow-600', id: 'electrician' },
    { name: t.plumber, icon: Wrench, color: 'bg-blue-100 text-blue-600', id: 'plumber' },
    { name: t.painter, icon: Paintbrush, color: 'bg-purple-100 text-purple-600', id: 'painter' },
    { name: t.carpenter, icon: Hammer, color: 'bg-orange-100 text-orange-600', id: 'carpenter' },
    { name: t.cleaner, icon: Sparkles, color: 'bg-green-100 text-green-600', id: 'cleaner' }
  ];

  return (
    <div className="min-h-screen bg-gray-50 pb-20">
      {/* Header */}
      <div className="bg-gradient-to-r from-green-600 to-green-500 text-white p-6 rounded-b-3xl">
        <div className="flex items-center space-x-4 mb-4">
          <Button variant="ghost" size="icon" onClick={onBack} className="text-white">
            <ArrowLeft className="w-5 h-5" />
          </Button>
          <div>
            <h1 className="text-xl">{t.title}</h1>
            <p className="text-primary-foreground/80 text-sm">{t.subtitle}</p>
          </div>
        </div>
      </div>

      <div className="p-6 space-y-6 -mt-6">
        {/* Service Selection */}
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">{t.selectService}</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 gap-3">
              {services.map((service) => (
                <Button
                  key={service.id}
                  variant={selectedService === service.id ? "default" : "outline"}
                  className={`h-20 flex flex-col items-center justify-center space-y-2 ${
                    selectedService === service.id ? 'bg-primary text-white' : 'hover:bg-gray-50'
                  }`}
                  onClick={() => setSelectedService(service.id)}
                >
                  <service.icon className={`w-6 h-6 ${
                    selectedService === service.id ? 'text-white' : service.color.split(' ')[1]
                  }`} />
                  <span className="text-xs">{service.name}</span>
                </Button>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Job Description */}
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle className="text-lg">{t.describe}</CardTitle>
              <VoiceButton onClick={onVoiceCommand} size="sm" />
            </div>
          </CardHeader>
          <CardContent>
            <Textarea
              placeholder={t.placeholder}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              className="min-h-24"
            />
            <p className="text-xs text-gray-500 mt-2">{t.voiceDesc}</p>
          </CardContent>
        </Card>

        {/* Location */}
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">{t.location}</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <MapPin className="w-5 h-5 text-accent" />
                <div>
                  <p className="text-sm">{t.currentLocation}</p>
                  <p className="text-xs text-gray-500">Kothrud, Pune</p>
                </div>
              </div>
              <Button variant="outline" size="sm">
                {t.changeLocation}
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* Timing */}
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">{t.timing}</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <Button variant="outline" className="w-full justify-start">
              <Clock className="w-4 h-4 mr-3" />
              {t.asap}
            </Button>
            <Button variant="outline" className="w-full justify-start">
              <Calendar className="w-4 h-4 mr-3" />
              {t.later}
            </Button>
          </CardContent>
        </Card>

        {/* Submit Button */}
        <Button 
          className="w-full h-12 bg-green-600 hover:bg-green-700"
          onClick={onPost}
          disabled={!selectedService || !description.trim()}
        >
          {t.post}
        </Button>
      </div>
    </div>
  );
}