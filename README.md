# GridMap AI

**A Self-Service Indoor Digital Infrastructure Platform for Intelligent Navigation and Accessibility**

> Status: 🚧 In active development — final year engineering project

---

## Overview

Outdoor navigation has been solved brilliantly by apps like Google Maps — but the moment you walk into a large building, that navigation disappears. GridMap AI solves this by letting any organization — a college, hospital, warehouse, or public office — digitize their building using nothing but a smartphone, with no CAD drawings, no professional surveyors, and no dedicated hardware.

GridMap AI is not just an indoor navigation app — it's an **Indoor Digital Infrastructure Platform**. Navigation, accessibility routing, and analytics are all services built on top of one core asset: a self-service digital map.

## The Problem

- Existing indoor mapping solutions require CAD drawings, professional surveying, or expensive infrastructure — putting them out of reach for colleges, MSMEs, hospitals, and public institutions
- Visitors waste time navigating unfamiliar buildings
- Visually impaired and mobility-impaired users face real accessibility barriers indoors
- Organizations have zero indoor analytics or emergency-navigation support

## How It Works

**Administrators** register their organization, then create a virtual grid over their building by simply walking through it and tapping cells to mark rooms, walls, stairs, lifts, entrances, and exits — no architectural expertise required.

**AI-assisted validation** checks the completed map for structural issues before publishing — unreachable rooms, isolated staircases, disconnected corridors, or missing accessible routes — using deterministic, explainable graph analysis.

**Visitors** search for a destination and get an optimal route calculated via A*/Dijkstra pathfinding, with full offline support once a building's map is downloaded. A multilingual voice assistant provides turn-by-turn spoken directions, and accessibility mode automatically routes wheelchair users away from stairs toward ramps and lifts.

## Key Features

- 📱 Self-service grid-based building mapping (mobile-first)
- 🧠 Rule-based AI validation for map integrity and accessibility
- 🗺️ A*/Dijkstra shortest-path indoor routing
- 🎙️ Multilingual voice-guided navigation
- ♿ Accessibility-first routing (wheelchair mode)
- 📶 Full offline navigation support
- 📊 Administrator analytics dashboard (planned)
- 🔄 Collaborative mapping with version history (planned)

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile App | Flutter (Dart), Android Studio |
| Backend / Database | Firebase (Firestore, Auth, Cloud Functions, Storage) |
| Routing | A* / Dijkstra graph algorithms |
| Voice | Speech-to-Text + Text-to-Speech |

## Project Status

Currently in active development as a final-year engineering project. See the [project roadmap](#) for build phases (updated as development progresses).

## Author

**Hasan Syed** — [GitHub](https://github.com/hasansyed18)
