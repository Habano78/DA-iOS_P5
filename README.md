Aura Banking App
This is a modern banking application built using SwiftUI, demonstrating a robust architecture and best practices for iOS development. It allows users to authenticate, manage their account, and perform transfers.

Table of Contents
Introduction

Features

Architecture (MVVM)

Getting Started

Tests

Introduction
Aura is a simple banking application that simulates the core functionalities of a financial app. It allows users to log in securely, view their account balance and transaction history, and send money. The project emphasizes a clean, testable, and maintainable codebase.

Features
✅ User Authentication: Log in with an email and password.

✅ Secure Session Persistence: The session token is securely stored in the Keychain, allowing the user to stay logged in between app launches.

✅ Account Overview: View the current account balance and a list of recent transactions.

✅ Full Transaction History: Access a detailed, scrollable list of all transactions in a modal view.

✅ Money Transfer: A dedicated screen to send money to a recipient, including input validation.

✅ Asynchronous State Management: The UI clearly indicates loading states and displays user-friendly error messages during network operations.

Architecture (MVVM)
The project is built following the Model - View - ViewModel architecture to ensure a clear separation of responsibilities.

View
Built entirely with SwiftUI. The views are responsible for displaying the state provided by the ViewModel and capturing user input. They contain no business logic.

ViewModel
This layer acts as the bridge between the View and the Model. It listens for user actions from the View, processes them by calling the appropriate services, and exposes the state to the View via @Published properties. This separation makes the logic testable independently of the UI.

Model Layer
This layer is responsible for providing data and handling business logic. It's composed of several parts:

Service Layer: Manages all network communication with the backend API. It's defined by protocols (e.g., AuthenticationServiceProtocol) to allow for Dependency Injection and easy mocking in tests.

Persistence Layer: Handles the secure storage of the authentication token using the Keychain. The AuthTokenPersistence class provides a simple interface for saving, retrieving, and deleting the token.

Data Models:

DTOs (Data Transfer Objects): Structures that mirror the exact JSON format of the API.

Domain Models: Structures that represent the data in a way that is optimized for use within the app.

Getting Started
To get the project running, you'll need to set up both the backend and the iOS application.

Prerequisites
Xcode 16 or later

iOS 17 or later

Homebrew (to install Vapor)

Installation
Run the Backend (Vapor)

Clone the backend repository to your local machine.

Navigate to the backend project folder in your Terminal.

Open the project in Xcode using the command:

Bash

open Package.swift
Once Xcode resolves the dependencies, build and run the project (Cmd+R). The backend server will start on http://127.0.0.1:8080.

Run the Aura iOS App

Clone this repository to your local machine.

Open the Aura.xcodeproj file in Xcode.

Build and run the project on your preferred simulator or a physical device connected to the same Wi-Fi network as your Mac.

Note for Physical Devices: If running on a real device, you must update the baseURLString constant in APIConfiguration.swift to use your Mac's local IP address (e.g., http://192.168.1.XX:8080).

Usage
Launch the app and use the following test credentials to log in 💪:

Username: test@aura.app

Password: test123

Tests
The project includes a suite of unit tests built with the Swift Testing framework (@Test, #expect). These tests ensure the reliability of the application's core logic.

You can execute the unit tests by selecting the AuraTests scheme in Xcode and pressing Cmd+U. The current test suite covers 🕵️‍♀️:

Data Models: Correct encoding and decoding of DTOs, and proper mapping to Domain Models.

Service Layer: Behavior of AuthService, AccountService, and TransferService for both success and various error scenarios, using a mocked network layer (MockURLProtocol).

ViewModels: (In progress) Testing the state management and logic of the ViewModels.
