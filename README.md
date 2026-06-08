# Finance Tracker Application

A comprehensive mobile finance tracking solution built as a monorepo containing a Flutter mobile application and a Node.js/Express backend API.

## Project Structure

This project follows a monorepo architecture, combining both the client application and the server in a single repository:

- `/lib` - Contains the Flutter mobile application source code (Dart).
- `/api` - Contains the Node.js Express backend API.

## Backend API Architecture

The backend API is designed following enterprise best practices, utilizing the **Controller-Service-Repository** pattern to ensure scalability, maintainability, and clean code separation.

### Security Features
- **Helmet**: Secures HTTP headers against common vulnerabilities.
- **Express Rate Limit**: Protects against brute-force and DDoS attacks.
- **Mongo Sanitize**: Prevents NoSQL injection attacks.
- **Joi Validation**: Provides strict input validation before reaching the controllers.
- **Global Error Handling**: Centralized error management using custom `AppError` classes and `express-async-handler`.

### Technical Stack (Backend)
- Node.js & Express.js
- MongoDB & Mongoose
- JSON Web Token (JWT) for Authentication
- Bcrypt.js for Password Hashing

## Setup Instructions

### Backend (API) Setup

1. Navigate to the API directory:
   ```bash
   cd api
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Environment Variables:
   Create a `.env` file in the `/api` directory using the provided `.env.example` as a template. You must provide your MongoDB connection string and a secret key for JWT.
   ```env
   MONGO_URI=mongodb+srv://<username>:<password>@cluster.mongodb.net/dbname
   PORT=3000
   JWT_SECRET=your_super_secret_jwt_key
   ```

4. Start the development server:
   ```bash
   npm run dev
   ```

### Frontend (Flutter) Setup

1. Ensure you have the Flutter SDK installed and configured on your machine.

2. Navigate to the root directory of the project.

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the application on an emulator or connected device:
   ```bash
   flutter run
   ```

## Postman Documentation

A complete Postman collection is included in the `.github` directory: `.github/postman_collection.json`. 

To use it:
1. Open Postman.
2. Click "Import" and select the `.github/postman_collection.json` file.
3. Configure the `baseUrl` variable (e.g., `http://localhost:3000`).
4. After logging in, copy your JWT token and place it in the Collection's `token` variable to access protected endpoints.

## License

This project is licensed under the MIT License.
