import { ArrowLeft, MapPin, Star, Phone, Shield, Clock } from 'lucide-react';
import { Button } from '../ui/button';
import { Card, CardContent } from '../ui/card';
import { Badge } from '../ui/badge';
import { Avatar, AvatarFallback, AvatarImage } from '../ui/avatar';
import { ImageWithFallback } from '../figma/ImageWithFallback';

interface WorkerListProps {
  language: 'en' | 'hi' | 'mr';
  onBack: () => void;
  onWorkerSelect: (workerId: string) => void;
}

export function WorkerList({ language, onBack, onWorkerSelect }: WorkerListProps) {
  const texts = {
    en: {
      title: "Available Workers",
      subtitle: "Electricians near you",
      verified: "Verified",
      away: "away",
      call: "Call",
      book: "Book",
      experience: "years exp",
      rating: "rating",
      jobs: "jobs completed"
    },
    hi: {
      title: "उपलब्ध कामगार",
      subtitle: "आपके पास इलेक्ट्रीशियन",
      verified: "सत्यापित",
      away: "दूर",
      call: "कॉल करें",
      book: "बुक करें",
      experience: "साल का अनुभव",
      rating: "रेटिंग",
      jobs: "काम पूरे किए"
    },
    mr: {
      title: "उपलब्ध कामगार",
      subtitle: "तुमच्या जवळचे इलेक्ट्रिशियन",
      verified: "सत्यापित",
      away: "अंतरावर",
      call: "कॉल करा",
      book: "बुक करा",
      experience: "वर्षांचा अनुभव",
      rating: "रेटिंग",
      jobs: "कामे पूर्ण केली"
    }
  };

  const t = texts[language];

  const workers = [
    {
      id: '1',
      name: 'Rajesh Kumar',
      rating: 4.8,
      distance: '1.2 km',
      experience: 8,
      jobsCompleted: 145,
      verified: true,
      available: true,
      image: 'https://images.unsplash.com/photo-1618228298959-0198d476d2ba?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxpbmRpYW4lMjBwbHVtYmVyJTIwZWxlY3RyaWNpYW58ZW58MXx8fHwxNzU5NjEyNTEyfDA&ixlib=rb-4.1.0&q=80&w=1080'
    },
    {
      id: '2', 
      name: 'Amit Sharma',
      rating: 4.6,
      distance: '2.1 km',
      experience: 5,
      jobsCompleted: 89,
      verified: true,
      available: true
    },
    {
      id: '3',
      name: 'Suresh Patil',
      rating: 4.9,
      distance: '0.8 km',
      experience: 12,
      jobsCompleted: 203,
      verified: true,
      available: false
    },
    {
      id: '4',
      name: 'Ravi Singh',
      rating: 4.5,
      distance: '3.2 km',
      experience: 6,
      jobsCompleted: 67,
      verified: false,
      available: true
    }
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

      <div className="p-6 space-y-4 -mt-6">
        {workers.map((worker) => (
          <Card key={worker.id} className={`transition-all hover:shadow-lg ${
            !worker.available ? 'opacity-60' : ''
          }`}>
            <CardContent className="p-4">
              <div className="flex items-start space-x-4">
                <div className="relative">
                  <Avatar className="w-16 h-16">
                    {worker.image ? (
                      <AvatarImage src={worker.image} alt={worker.name} />
                    ) : (
                      <AvatarFallback>{worker.name.split(' ').map(n => n[0]).join('')}</AvatarFallback>
                    )}
                  </Avatar>
                  {worker.verified && (
                    <div className="absolute -top-1 -right-1 w-5 h-5 bg-blue-500 rounded-full flex items-center justify-center">
                      <Shield className="w-3 h-3 text-white" />
                    </div>
                  )}
                </div>

                <div className="flex-1 space-y-2">
                  <div className="flex items-center justify-between">
                    <h3 className="text-lg">{worker.name}</h3>
                    {!worker.available && (
                      <Badge variant="secondary" className="text-xs">
                        <Clock className="w-3 h-3 mr-1" />
                        Busy
                      </Badge>
                    )}
                  </div>

                  <div className="flex items-center space-x-4 text-sm text-gray-600">
                    <div className="flex items-center space-x-1">
                      <Star className="w-4 h-4 text-yellow-500 fill-current" />
                      <span>{worker.rating}</span>
                    </div>
                    <div className="flex items-center space-x-1">
                      <MapPin className="w-4 h-4" />
                      <span>{worker.distance} {t.away}</span>
                    </div>
                  </div>

                  <div className="flex items-center space-x-4 text-xs text-gray-500">
                    <span>{worker.experience} {t.experience}</span>
                    <span>{worker.jobsCompleted} {t.jobs}</span>
                  </div>

                  {worker.verified && (
                    <Badge variant="secondary" className="text-xs bg-blue-50 text-blue-700">
                      <Shield className="w-3 h-3 mr-1" />
                      {t.verified}
                    </Badge>
                  )}

                  <div className="flex space-x-2 pt-2">
                    <Button 
                      variant="outline" 
                      size="sm" 
                      className="flex-1"
                      disabled={!worker.available}
                    >
                      <Phone className="w-4 h-4 mr-1" />
                      {t.call}
                    </Button>
                    <Button 
                      size="sm" 
                      className="flex-1 bg-green-600 hover:bg-green-700"
                      onClick={() => onWorkerSelect(worker.id)}
                      disabled={!worker.available}
                    >
                      {t.book}
                    </Button>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}