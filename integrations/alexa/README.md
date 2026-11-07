# Alexa Smart Home Integration

## Setup
1. Create an Alexa Smart Home Skill in the Alexa Developer Console
2. Configure Account Linking with OAuth 2.0 (Supabase Auth)
3. Deploy the Lambda handler (see `lambda/`)
4. Set environment variables: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
5. Test with Alexa Simulator or Echo device

## Supported Commands
- "Alexa, turn on [device name]"
- "Alexa, turn off [device name]"
- "Alexa, set [device] brightness to 50%"
- "Alexa, set [device] to [level]"

## Architecture
Alexa → Lambda → Supabase Edge Functions → MQTT → Device
