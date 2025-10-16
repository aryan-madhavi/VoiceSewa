import { useState } from "react";
import {
  Phone,
  Shield,
  Check,
  ArrowRight,
  Loader2,
} from "lucide-react";
import { Button } from "../ui/button";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "../ui/card";
import { Input } from "../ui/input";
import { Label } from "../ui/label";
import { Checkbox } from "../ui/checkbox";

interface AuthScreenProps {
  onAuthComplete: () => void;
  onVoiceCommand: () => void;
}

export function AuthScreen({
  onAuthComplete,
  onVoiceCommand,
}: AuthScreenProps) {
  const [step, setStep] = useState<"phone" | "otp">("phone");
  const [phoneNumber, setPhoneNumber] = useState("");
  const [otp, setOtp] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [consentGiven, setConsentGiven] = useState(false);

  const handleSendOtp = async () => {
    if (phoneNumber.length === 10 && consentGiven) {
      setIsLoading(true);
      // Simulate API call
      setTimeout(() => {
        setIsLoading(false);
        setStep("otp");
      }, 2000);
    }
  };

  const handleVerifyOtp = async () => {
    if (otp === "1234") {
      setIsLoading(true);
      setTimeout(() => {
        setIsLoading(false);
        onAuthComplete();
      }, 1500);
    }
  };

  const handleResendOtp = () => {
    setOtp("");
    setIsLoading(true);
    setTimeout(() => {
      setIsLoading(false);
    }, 1000);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-orange-50 via-white to-orange-50 flex flex-col items-center justify-center p-6">
      <div className="w-full max-w-md space-y-8">
        {/* Header */}
        <div className="text-center space-y-4">
          <div className="w-20 h-20 mx-auto bg-primary rounded-2xl flex items-center justify-center shadow-lg">
            <Shield className="w-10 h-10 text-white" />
          </div>
          <div className="space-y-2">
            <h1 className="text-gray-800">
              {step === "phone"
                ? "Welcome to VoiceSewa"
                : "Verify Your Number"}
            </h1>
            <p className="text-gray-600">
              {step === "phone"
                ? "Enter your mobile number to get started"
                : `We've sent a 4-digit OTP to +91 ${phoneNumber}`}
            </p>
          </div>
        </div>

        {/* Authentication Form */}
        <Card className="shadow-lg border-0">
          <CardHeader className="text-center pb-4">
            <CardTitle className="flex items-center justify-center gap-2">
              <Phone className="w-5 h-5 text-primary" />
              {step === "phone" ? "Mobile Number" : "Enter OTP"}
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-6">
            {step === "phone" ? (
              <>
                {/* Phone Number Input */}
                <div className="space-y-3">
                  <Label htmlFor="phone">Mobile Number</Label>
                  <div className="flex">
                    <div className="flex items-center px-3 bg-muted rounded-l-lg border border-r-0">
                      <span className="text-gray-600">+91</span>
                    </div>
                    <Input
                      id="phone"
                      type="tel"
                      placeholder="Enter 10-digit number"
                      value={phoneNumber}
                      onChange={(e) =>
                        setPhoneNumber(
                          e.target.value
                            .replace(/\D/g, "")
                            .slice(0, 10),
                        )
                      }
                      className="rounded-l-none flex-1"
                      maxLength={10}
                    />
                  </div>
                  <div className="flex items-center space-x-2">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={onVoiceCommand}
                      className="h-8 w-8 rounded-full p-0"
                    >
                      <Phone className="w-3 h-3" />
                    </Button>
                    <span className="text-gray-500">
                      Say your number aloud
                    </span>
                  </div>
                </div>

                {/* Privacy Consent */}
                <div className="space-y-4">
                  <div className="flex items-start space-x-3 flex-col">
                    <div className="flex items-start space-x-3">
                      <Checkbox
                        id="consent"
                        checked={consentGiven}
                        onCheckedChange={(checked) =>
                          setConsentGiven(checked as boolean)
                        }
                        className="mt-1"
                      />
                      <Label
                        htmlFor="consent"
                        className="leading-relaxed cursor-pointer"
                      >
                        <span>
                        I agree to VoiceSewa's{" "}
                        <span className="text-primary underline">
                          Terms of Service
                        </span>{" "}
                        and{" "}
                        <span className="text-primary underline">
                          Privacy Policy.
                        </span>
                        </span>
                      </Label>
                    </div>
                    <Label
                      htmlFor="consent-description"
                      className="leading-relaxed cursor-pointer"
                    >
                      My data will be processed in compliance
                      with the Digital Personal Data Protection
                      Act 2023.
                    </Label>
                  </div>

                  <div className="bg-blue-50 p-3 rounded-lg border border-blue-200">
                    <div className="flex items-start space-x-2">
                      <Shield className="w-4 h-4 text-blue-600 mt-0.5 flex-shrink-0" />
                      <p className="text-blue-800">
                        VoiceSewa is designed for professional
                        services only. We do not collect or
                        store personal identifying information
                        unnecessarily.
                      </p>
                    </div>
                  </div>
                </div>

                {/* Send OTP Button */}
                <Button
                  onClick={handleSendOtp}
                  className="w-full h-12 bg-primary hover:bg-primary/90"
                  disabled={
                    phoneNumber.length !== 10 ||
                    !consentGiven ||
                    isLoading
                  }
                >
                  {isLoading ? (
                    <>
                      <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                      Sending OTP...
                    </>
                  ) : (
                    <>
                      Send OTP
                      <ArrowRight className="w-4 h-4 ml-2" />
                    </>
                  )}
                </Button>
              </>
            ) : (
              <>
                {/* OTP Input */}
                <div className="space-y-4">
                  <div className="space-y-3">
                    <Label htmlFor="otp">
                      Enter 4-digit OTP
                    </Label>
                    <Input
                      id="otp"
                      type="text"
                      placeholder="••••"
                      value={otp}
                      onChange={(e) =>
                        setOtp(
                          e.target.value
                            .replace(/\D/g, "")
                            .slice(0, 4),
                        )
                      }
                      className="text-center tracking-wider h-14"
                      maxLength={4}
                    />
                    <div className="flex items-center justify-center space-x-2">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={onVoiceCommand}
                        className="h-8 w-8 rounded-full p-0"
                      >
                        <Shield className="w-3 h-3" />
                      </Button>
                      <span className="text-gray-500">
                        Say OTP aloud
                      </span>
                    </div>
                  </div>

                  {/* Resend OTP */}
                  <div className="text-center">
                    <p className="text-gray-600 mb-2">
                      Didn't receive OTP?
                    </p>
                    <Button
                      variant="ghost"
                      onClick={handleResendOtp}
                      className="text-primary hover:text-primary/80"
                      disabled={isLoading}
                    >
                      {isLoading
                        ? "Resending..."
                        : "Resend OTP"}
                    </Button>
                  </div>
                </div>

                {/* Verify Button */}
                <Button
                  onClick={handleVerifyOtp}
                  className="w-full h-12 bg-accent hover:bg-accent/90"
                  disabled={otp.length !== 4 || isLoading}
                >
                  {isLoading ? (
                    <>
                      <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                      Verifying...
                    </>
                  ) : (
                    <>
                      <Check className="w-4 h-4 mr-2" />
                      Verify & Continue
                    </>
                  )}
                </Button>

                {/* Back to Phone */}
                <Button
                  variant="outline"
                  onClick={() => setStep("phone")}
                  className="w-full"
                >
                  Change Number
                </Button>
              </>
            )}
          </CardContent>
        </Card>

        {/* Security Footer */}
        <div className="text-center space-y-2">
          <div className="flex items-center justify-center space-x-2 text-gray-500">
            <Shield className="w-3 h-3" />
            <span>Secured by 256-bit encryption</span>
          </div>
          <p className="text-gray-400">
            Trusted by thousands of workers and clients across
            India
          </p>
        </div>
      </div>
    </div>
  );
}