- MQTT v5 must be used for messaging
- Mosquitto is the preferred MQTT broker (supporting MQTT v5)
- MQTT topics should follow a hierarchical structure
- Use Quality of Service (QoS) level 2 for high reliability and exactly-once delivery
- Use Session Expiry Interval (sticky sessions) for non-connected clients to handle persistent session state (set to a
  reasonable timeout)
- Utilize User Properties by adding metadata to messages
- Consider Shared Subscriptions for load balancing across multiple consumers
- Use retained messages where appropriate for stateful information
- Ensure secure connections using TLS/SSL where possible
- Use persistent topics and ensure all messages are saved using the broker's persistence features (e.g., Mosquitto
  persistence)
