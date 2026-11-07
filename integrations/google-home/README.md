# Google Home Cloud-to-Cloud Integration

## Setup
1. Create a project in Google Actions Console
2. Configure OAuth 2.0 Account Linking
3. Deploy fulfillment endpoint
4. Set up device SYNC, QUERY, EXECUTE intents

## Supported Traits
- OnOff (lights, switches, plugs)
- Brightness (dimmable lights)
- FanSpeed (fans)
- SensorState (temperature, humidity sensors)

## Architecture
Google Home → Fulfillment Endpoint → Supabase → MQTT → Device
