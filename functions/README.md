# Firebase Functions for Agora Token Generation

This directory contains Firebase Cloud Functions for the Emtech School app.

## Functions

### generateAgoraToken
Generates Agora RTC tokens on-demand for secure voice/video calling.

### checkAgoraConfig
Admin-only function to verify Agora configuration.

### cleanupOldCalls
Scheduled function that runs daily to clean up old call records (older than 30 days).

## Setup

See AGORA_TOKEN_SERVER_SETUP.md in the project root for complete setup instructions.
