/**
 * Firebase Cloud Functions (v2) - Twilio SMS Integration
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");
const twilio = require("twilio");

// Load environment variables from .env (DEV ONLY)
require("dotenv").config();

// Limit max instances (cost control)
setGlobalOptions({maxInstances: 10});

/**
 * Send Emergency SMS
 */
exports.sendEmergencySMS = onRequest(async (req, res) => {
  try {
    const {phone, message} = req.body;

    if (!phone || !message) {
      return res.status(400).json({
        error: "Phone and message are required.",
      });
    }

    // Initialize Twilio client using .env values
    const client = twilio(
        process.env.TWILIO_SID,
        process.env.TWILIO_AUTH_TOKEN,
    );

    // Send SMS
    const response = await client.messages.create({
      body: message,
      from: process.env.TWILIO_PHONE,
      to: phone,
    });

    logger.info("SMS sent successfully", response.sid);

    return res.status(200).json({
      success: true,
      sid: response.sid,
    });
  } catch (error) {
    logger.error("Error sending SMS", error);

    return res.status(500).json({
      error: error.message,
    });
  }
});
