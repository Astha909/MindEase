/**
 * Firebase Cloud Functions (v2) - Twilio SMS Integration
 */

const {setGlobalOptions} = require("firebase-functions");
const {onCall} = require("firebase-functions/https");
const {defineSecret} = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const twilio = require("twilio");

// Limit max instances (cost control)
setGlobalOptions({maxInstances: 10});

/**
 * 🔐 Secret Definitions (NEW)
 */
const twilioSid = defineSecret("TWILIO_SID");
const twilioToken = defineSecret("TWILIO_AUTH_TOKEN");
const twilioPhone = defineSecret("TWILIO_PHONE");

/**
 * Send Emergency SMS
 */
exports.sendEmergencySMS = onCall(
    {secrets: [twilioSid, twilioToken, twilioPhone]},
    async (request) => {
      try {
      // 🔐 Auth Check
        if (!request.auth) {
          throw new Error("Unauthenticated");
        }

        // 📩 Input
        const {phone, message} = request.data;

        if (!phone || !message) {
          throw new Error("Phone and message are required");
        }

        // 📲 Twilio Client
        const client = twilio(
            twilioSid.value(),
            twilioToken.value(),
        );

        // 🚀 Send SMS
        const response = await client.messages.create({
          body: message,
          from: twilioPhone.value(),
          to: phone,
        });

        logger.info("SMS sent successfully", response.sid);

        return {
          success: true,
          sid: response.sid,
        };
      } catch (error) {
        logger.error("Error sending SMS", error);
        throw new Error(error.message);
      }
    },
);
