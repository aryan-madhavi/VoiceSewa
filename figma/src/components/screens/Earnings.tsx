import { ArrowLeft, TrendingUp, Calendar, Eye, Download, Wallet, Target, Award } from 'lucide-react';
import { Button } from '../ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Progress } from '../ui/progress';
import { VoiceButton } from '../VoiceButton';
import { OfflineBanner } from '../OfflineBanner';

interface EarningsProps {
  language: 'en' | 'hi' | 'mr';
  isOffline: boolean;
  onBack: () => void;
  onVoiceCommand: () => void;
}

export function Earnings({ language, isOffline, onBack, onVoiceCommand }: EarningsProps) {
  const texts = {
    en: {
      title: "Earnings",
      today: "Today",
      week: "This Week",
      month: "This Month",
      total: "Total Earned",
      pending: "Pending",
      completed: "Completed",
      withdrawn: "Withdrawn",
      withdraw: "Withdraw",
      viewStatement: "View Statement",
      downloadReport: "Download Report",
      earnings: "Earnings",
      bonus: "Bonus",
      monthlyGoal: "Monthly Goal",
      achievement: "Achievement",
      recentTransactions: "Recent Transactions",
      jobCompleted: "Job Completed",
      bonusEarned: "Bonus Earned",
      withdrawalProcessed: "Withdrawal Processed",
      noTransactions: "No transactions yet",
      goalProgress: "Goal Progress",
      keepGoing: "Keep going! You're doing great.",
      excellentWork: "Excellent work this month!"
    },
    hi: {
      title: "कमाई",
      today: "आज",
      week: "इस सप्ताह",
      month: "इस महीने",
      total: "कुल कमाई",
      pending: "लंबित",
      completed: "पूर्ण",
      withdrawn: "निकाला गया",
      withdraw: "निकालें",
      viewStatement: "स्टेटमेंट देखें",
      downloadReport: "रिपोर्ट डाउनलोड करें",
      earnings: "कमाई",
      bonus: "बोनस",
      monthlyGoal: "मासिक लक्ष्य",
      achievement: "उपलब्धि",
      recentTransactions: "हाल के लेनदेन",
      jobCompleted: "काम पूरा हुआ",
      bonusEarned: "बोनस मिला",
      withdrawalProcessed: "निकासी प्रक्रिया",
      noTransactions: "अभी तक कोई लेनदेन नहीं",
      goalProgress: "लक्ष्य प्रगति",
      keepGoing: "चलते रहें! आप बहुत अच्छा कर रहे हैं।",
      excellentWork: "इस महीने उत्कृष्ट काम!"
    },
    mr: {
      title: "कमाई",
      today: "आज",
      week: "या आठवड्यात",
      month: "या महिन्यात",
      total: "एकूण कमाई",
      pending: "प्रलंबित",
      completed: "पूर्ण",
      withdrawn: "काढले",
      withdraw: "काढा",
      viewStatement: "स्टेटमेंट पहा",
      downloadReport: "अहवाल डाउनलोड करा",
      earnings: "कमाई",
      bonus: "बोनस",
      monthlyGoal: "मासिक ध्येय",
      achievement: "सिद्धी",
      recentTransactions: "अलीकडील व्यवहार",
      jobCompleted: "काम पूर्ण झाले",
      bonusEarned: "बोनस मिळाला",
      withdrawalProcessed: "काढण्याची प्रक्रिया",
      noTransactions: "अद्याप कोणते व्यवहार नाहीत",
      goalProgress: "ध्येय प्रगती",
      keepGoing: "चालू ठेवा! तुम्ही खूप चांगले करत आहात.",
      excellentWork: "या महिन्यात उत्कृष्ट काम!"
    }
  };

  const t = texts[language];

  const earningsData = {
    today: { amount: 850, jobs: 2 },
    week: { amount: 4200, jobs: 8 },
    month: { amount: 18500, jobs: 35 },
    pending: 1200,
    completed: 17300,
    withdrawn: 15000
  };

  const monthlyGoal = 25000;
  const currentProgress = (earningsData.month.amount / monthlyGoal) * 100;

  const recentTransactions = [
    {
      id: "1",
      type: "job",
      description: "Electrical wiring repair - Sharma Family",
      amount: "+₹800",
      date: "Today, 4:30 PM",
      status: "completed"
    },
    {
      id: "2", 
      type: "bonus",
      description: "Weekly performance bonus",
      amount: "+₹200",
      date: "Today, 2:15 PM",
      status: "completed"
    },
    {
      id: "3",
      type: "job",
      description: "Plumbing repair - Kumar Residence",
      amount: "+₹600",
      date: "Yesterday, 6:45 PM",
      status: "completed"
    },
    {
      id: "4",
      type: "withdrawal",
      description: "Bank transfer to SBI Account",
      amount: "-₹5000",
      date: "2 days ago",
      status: "processed"
    },
    {
      id: "5",
      type: "job",
      description: "AC installation - Patel Family",
      amount: "+₹1500",
      date: "3 days ago",
      status: "completed"
    }
  ];

  const getTransactionIcon = (type: string) => {
    switch (type) {
      case 'job':
        return <Wallet className="w-4 h-4 text-green-600" />;
      case 'bonus':
        return <Award className="w-4 h-4 text-blue-600" />;
      case 'withdrawal':
        return <Download className="w-4 h-4 text-orange-600" />;
      default:
        return <Wallet className="w-4 h-4 text-gray-600" />;
    }
  };

  const getTransactionLabel = (type: string) => {
    switch (type) {
      case 'job':
        return t.jobCompleted;
      case 'bonus':
        return t.bonusEarned;
      case 'withdrawal':
        return t.withdrawalProcessed;
      default:
        return '';
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
        {/* Quick Stats */}
        <div className="grid grid-cols-3 gap-4">
          <Card>
            <CardContent className="p-4 text-center">
              <p className="text-2xl text-primary">₹{earningsData.today.amount}</p>
              <p className="text-xs text-gray-600">{t.today}</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4 text-center">
              <p className="text-2xl text-accent">₹{earningsData.week.amount.toLocaleString()}</p>
              <p className="text-xs text-gray-600">{t.week}</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4 text-center">
              <p className="text-2xl text-blue-600">₹{earningsData.month.amount.toLocaleString()}</p>
              <p className="text-xs text-gray-600">{t.month}</p>
            </CardContent>
          </Card>
        </div>

        {/* Monthly Goal Progress */}
        <Card className="border-l-4 border-l-blue-600">
          <CardHeader className="pb-3">
            <div className="flex items-center justify-between">
              <CardTitle className="text-base flex items-center gap-2">
                <Target className="w-5 h-5 text-blue-600" />
                {t.monthlyGoal}
              </CardTitle>
              <Badge className="bg-blue-100 text-blue-800">
                {Math.round(currentProgress)}%
              </Badge>
            </div>
          </CardHeader>
          <CardContent className="pt-0">
            <div className="space-y-3">
              <Progress value={currentProgress} className="h-2" />
              <div className="flex justify-between text-sm">
                <span className="text-gray-600">₹{earningsData.month.amount.toLocaleString()}</span>
                <span className="text-gray-600">₹{monthlyGoal.toLocaleString()}</span>
              </div>
              <p className="text-sm text-gray-600">
                {currentProgress >= 90 ? t.excellentWork : t.keepGoing}
              </p>
            </div>
          </CardContent>
        </Card>

        {/* Earnings Breakdown */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base">{t.earnings}</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <span className="text-gray-600">{t.completed}</span>
                <span className="text-green-600">₹{earningsData.completed.toLocaleString()}</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-gray-600">{t.pending}</span>
                <span className="text-yellow-600">₹{earningsData.pending.toLocaleString()}</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-gray-600">{t.withdrawn}</span>
                <span className="text-gray-600">₹{earningsData.withdrawn.toLocaleString()}</span>
              </div>
              <div className="border-t pt-4">
                <div className="flex items-center justify-between">
                  <span className="text-lg">{t.total}</span>
                  <span className="text-lg text-primary">₹{(earningsData.completed + earningsData.pending).toLocaleString()}</span>
                </div>
              </div>
              <div className="flex gap-2 pt-2">
                <Button className="flex-1 bg-accent hover:bg-accent/90">
                  <Download className="w-4 h-4 mr-2" />
                  {t.withdraw}
                </Button>
                <Button variant="outline" className="flex-1">
                  <Eye className="w-4 h-4 mr-2" />
                  {t.viewStatement}
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Recent Transactions */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base">{t.recentTransactions}</CardTitle>
          </CardHeader>
          <CardContent>
            {recentTransactions.length > 0 ? (
              <div className="space-y-4">
                {recentTransactions.map((transaction) => (
                  <div key={transaction.id} className="flex items-center gap-3 p-3 rounded-lg bg-gray-50">
                    {getTransactionIcon(transaction.type)}
                    <div className="flex-1 min-w-0">
                      <p className="text-sm text-gray-900 truncate">{transaction.description}</p>
                      <p className="text-xs text-gray-500">{transaction.date}</p>
                    </div>
                    <div className="text-right">
                      <p className={`text-sm ${transaction.amount.startsWith('+') ? 'text-green-600' : 'text-orange-600'}`}>
                        {transaction.amount}
                      </p>
                      <p className="text-xs text-gray-500">{getTransactionLabel(transaction.type)}</p>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-center py-8 text-gray-500">
                <Wallet className="w-12 h-12 mx-auto mb-2 text-gray-300" />
                <p>{t.noTransactions}</p>
              </div>
            )}
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