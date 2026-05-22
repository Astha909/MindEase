/**
 * Firebase Cloud Functions (v2) - Twilio SMS Integration
 */

const { setGlobalOptions } = require("firebase-functions");
const { onCall } = require("firebase-functions/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const twilio = require("twilio");
const { GoogleGenerativeAI } = require("@google/generative-ai");

// Limit max instances (cost control)
setGlobalOptions({ maxInstances: 10 });

/**
 * 🔐 Secret Definitions
 */
const twilioSid = defineSecret("TWILIO_SID");
const twilioToken = defineSecret("TWILIO_AUTH_TOKEN");
const twilioPhone = defineSecret("TWILIO_PHONE");
const geminiApiKey = defineSecret("GEMINI_API_KEY");

/**
 * Send Emergency SMS
 */
exports.sendEmergencySMS = onCall(
  { secrets: [twilioSid, twilioToken, twilioPhone] },
  async (request) => {
    try {
      // 🔐 Auth Check
      if (!request.auth) {
        throw new Error("Unauthenticated");
      }

      // 📩 Input
      const { phone, message } = request.data;

      if (!phone || !message) {
        throw new Error("Phone and message are required");
      }

      // 📲 Twilio Client
      const client = twilio(twilioSid.value(), twilioToken.value());

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

/**
 * Generate AI Response (Gemini)
 */
exports.generateAIResponse = onCall(
  { secrets: [geminiApiKey] },
  async (request) => {
    try {
      // 🔐 Auth check
      if (!request.auth) {
        throw new Error("Unauthenticated");
      }

      // 📩 Request Data
      const { message, mood, tips, activity } = request.data;

      if (!message) {
        throw new Error("Message is required");
      }

      // 🤖 Gemini init
      const genAI = new GoogleGenerativeAI(geminiApiKey.value());

      const model = genAI.getGenerativeModel({
        model: "gemini-2.5-flash",
      });

      // 🧠 Prompt
      const prompt = `
You are a supportive wellness assistant.

Return ONLY valid JSON.
No markdown.
No explanation text.

Required JSON format:
{
  "chat_reply":"",
  "is_crisis":false,
  "crisis_level":"none"
}

Rules:
- Never diagnose mental illness
- Never encourage self-harm
- Never claim certainty
- Keep responses short and supportive
- Use the provided mood and wellness tips
- If crisis detected, set crisis_level appropriately

Detected mood:
${mood || "neutral"}

Suggested wellness tips:
${
  Array.isArray(tips)
    ? tips
        .map((t) => {
          if (typeof t === "string") {
            return "- " + t;
          }

          return "- " + (t.content || "");
        })
        .join("\n")
    : "None"
}

Suggested activity:
${activity || "None"}

User input:
${message}
`;

      // 🚀 Generate response
      const result = await model.generateContent(prompt);

      const rawText = result.response.text().trim();

      logger.info("Gemini raw response:", rawText);

      let cleanedText = rawText;

      // Remove markdown wrappers
      cleanedText = cleanedText
        .replace(/```json/g, "")
        .replace(/```/g, "")
        .trim();

      // Extract JSON safely
      const jsonStart = cleanedText.indexOf("{");

      const jsonEnd = cleanedText.lastIndexOf("}");

      if (jsonStart === -1 || jsonEnd === -1) {
        throw new Error("Invalid JSON response from Gemini");
      }

      cleanedText = cleanedText.substring(jsonStart, jsonEnd + 1);

      let parsed;

      try {
        parsed = JSON.parse(cleanedText);
      } catch (e) {
        logger.error("JSON parse failed:", cleanedText);

        parsed = {
          chat_reply: rawText,
          is_crisis: false,
          crisis_level: "none",
        };
      }

      return parsed;
    } catch (error) {
      logger.error("Gemini error", error);

      return {
        chat_reply: "I'm here with you 🤍",
        is_crisis: false,
        crisis_level: "none",
      };
    }
  },
);
