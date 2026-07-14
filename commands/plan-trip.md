---
description: Plan a trip end to end — live flights, hotels, Airbnb, and routes in one itinerary
---

Dispatch the `travel-planner` agent with the user's request: $ARGUMENTS

If no arguments were given, ask (in one question) for origin, destination, dates or
date flexibility, and the trip's purpose — then dispatch the agent.

The agent loads the `plan-trip` skill, reads the traveler-preferences file if present,
searches flights (SerpApi Google Flights), stays (Google Hotels + Airbnb, optionally
Booking.com), and ground routes (Google Maps), and returns one clean itinerary with
booking links. It never books or pays anything.
