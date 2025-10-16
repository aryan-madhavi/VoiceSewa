import { CheckCircle, Clock, MapPin, Phone, MessageCircle } from 'lucide-react';
import { Button } from '../ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Avatar, AvatarFallback, AvatarImage } from '../ui/avatar';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { useState } from 'react';

interface JobConfirmationProps {
  language: 'en' | 'hi' | 'mr';
  onHome: () => void;
}

export function JobConfirmation({ language, onHome }: JobConfirmationProps) {
  const [otpReceived, setOtpReceived] = useState(false);
  const [otp, setOtp] = useState('');

  const texts = {
    en: {
      title: "Job Confirmed!",
      subtitle: "Your electrician is on the way",
      worker: "Rajesh Kumar",
      eta: "Arriving in 25-30 minutes",
      status: "Confirmed",
      jobDetails: "Job Details",
      service: "Electrical repair work",
      location: "Your Location",
      address: "123 Kothrud, Pune",
      contact: "Contact Worker",
      call: "Call",
      message: "Message",
      arrival: "Worker Arrival Confirmation",
      otpPrompt: "Worker will provide OTP upon arrival",
      enterOtp: "Enter OTP",
      otpPlaceholder: "Enter 4-digit OTP",
      confirm: "Confirm Arrival",
      backHome: "Back to Home",
      otpSuccess: "Worker arrival confirmed!"
    },
    hi: {
      title: "नौकरी की पुष्टि हो गई!",
      subtitle: "आपका इलेक्ट्रीशियन आ रहा है",
      worker: "राजेश कुमार",
      eta: "25-30 मिनट में पहुंचेंगे",
      status: "पुष्ट",
      jobDetails: "नौकरी का विवरण",
      service: "बिजली की मरम्मत का काम",
      location: "आपका स्थान",
      address: "123 कोथरूड, पुणे",
      contact: "कामगार से संपर्क करें",
      call: "कॉल करें",
      message: "संदेश",
      arrival: "कामगार के आने की पुष्टि",
      otpPrompt: "कामगार आने पर OTP देगा",
      enterOtp: "OTP दर्ज करें",
      otpPlaceholder: "4 अंकों का OTP दर्ज करें",
      confirm: "आगमन की पुष्टि करें",
      backHome: "होम पर वापस जाएं",
      otpSuccess: "कामगार का आगमन पुष्ट हुआ!"
    },
    mr: {
      title: "नोकरीची पुष्टी झाली!",
      subtitle: "तुमचा इलेक्ट्रिशियन येत आहे",
      worker: "राजेश कुमार",
      eta: "25-30 मिनिटात पोहोचतील",
      status: "पुष्ट",
      jobDetails: "नोकरीचे तपशील",
      service: "विद्युत दुरुस्तीचे काम",
      location: "तुमचे स्थान",
      address: "123 कोथरुड, पुणे",
      contact: "कामगाराशी संपर्क साधा",
      call: "कॉल करा",
      message: "संदेश",
      arrival: "कामगार आगमन पुष्टीकरण",
      otpPrompt: "कामगार आल्यावर OTP देईल",
      enterOtp: "OTP टाका",
      otpPlaceholder: "4 अंकी OTP टाका",
      confirm: "आगमनाची पुष्टी करा",
      backHome: "होम वर परत जा",
      otpSuccess: "कामगाराचे आगमन पुष्ट झाले!"
    }
  };

  const t = texts[language];

  const handleOtpConfirm = () => {
    if (otp === '1234') {
      setOtpReceived(true);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 pb-20">
      {/* Header */}
      <div className="bg-gradient-to-r from-green-600 to-green-500 text-white p-6 rounded-b-3xl">
        <div className="text-center space-y-4">
          <CheckCircle className="w-16 h-16 mx-auto text-white" />
          <div>
            <h1 className="text-xl">{t.title}</h1>
            <p className="text-white/80 text-sm">{t.subtitle}</p>
          </div>
        </div>
      </div>

      <div className="p-6 space-y-6 -mt-6">
        {/* Worker Info */}
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center space-x-4">
              <Avatar className="w-16 h-16">
                <AvatarImage src="https://images.unsplash.com/photo-1618228298959-0198d476d2ba?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxpbmRpYW4lMjBwbHVtYmVyJTIwZWxlY3RyaWNpYW58ZW58MXx8fHwxNzU5NjEyNTEyfDA&ixlib=rb-4.1.0&q=80&w=1080" />
                <AvatarFallback>RK</AvatarFallback>
              </Avatar>
              <div className="flex-1">
                <div className="flex items-center justify-between">
                  <h3 className="text-lg">{t.worker}</h3>
                  <Badge className="bg-green-100 text-green-800">
                    {t.status}
                  </Badge>
                </div>
                <div className="flex items-center space-x-2 text-sm text-gray-600 mt-1">
                  <Clock className="w-4 h-4" />
                  <span>{t.eta}</span>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Job Details */}
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">{t.jobDetails}</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <p className="text-sm text-gray-600">Service</p>
              <p>{t.service}</p>
            </div>
            <div className="flex items-center space-x-2">
              <MapPin className="w-4 h-4 text-gray-500" />
              <div>
                <p className="text-sm text-gray-600">{t.location}</p>
                <p className="text-sm">{t.address}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Contact Options */}
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">{t.contact}</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex space-x-3">
              <Button variant="outline" className="flex-1">
                <Phone className="w-4 h-4 mr-2" />
                {t.call}
              </Button>
              <Button variant="outline" className="flex-1">
                <MessageCircle className="w-4 h-4 mr-2" />
                {t.message}
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* OTP Confirmation */}
        <Card className={otpReceived ? 'border-green-200 bg-green-50' : ''}>
          <CardHeader>
            <CardTitle className="text-lg">{t.arrival}</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {!otpReceived ? (
              <>
                <p className="text-sm text-gray-600">{t.otpPrompt}</p>
                <div className="space-y-3">
                  <Label htmlFor="otp">{t.enterOtp}</Label>
                  <Input
                    id="otp"
                    placeholder={t.otpPlaceholder}
                    value={otp}
                    onChange={(e) => setOtp(e.target.value)}
                    maxLength={4}
                    className="text-center tracking-wider"
                  />
                  <Button 
                    onClick={handleOtpConfirm}
                    className="w-full bg-green-600 hover:bg-green-700"
                    disabled={otp.length !== 4}
                  >
                    {t.confirm}
                  </Button>
                </div>
              </>
            ) : (
              <div className="text-center space-y-4">
                <CheckCircle className="w-12 h-12 text-green-600 mx-auto" />
                <p className="text-green-800">{t.otpSuccess}</p>
                <Button onClick={onHome} className="w-full bg-green-600 hover:bg-green-700">
                  {t.backHome}
                </Button>
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}