# 🚀 Circle — Skill Exchange Social Platform

> Learn. Teach. Grow.  
> A modern Flutter-powered social platform where users exchange knowledge using a token-based system.

---

## 📱 Overview

**Circle** is a real-time social learning platform that allows users to:

- Share what they are learning 📚  
- Offer what they can teach 🎓  
- Connect with others 🤝  
- Exchange value using a token system 💰  

Built with **Flutter + Supabase**, designed for scalability and real-world usage.

---

## ✨ Features

### 🔐 Authentication
- Secure signup & login
- Supabase Auth integration
- Persistent sessions

### 🏠 Dashboard
- Bottom navigation (Feed, Explore, Post, Sessions, Profile)
- Smooth navigation using GoRouter

### 📰 Feed System
- Create posts (Learning / Teaching / Availability)
- Real-time updates ⚡
- Like & comment system ❤️💬
- Image upload support 🖼️

### 💬 Interaction
- Add comments on posts
- View comment threads
- Like/unlike posts

### 💰 Token Economy (Core Feature)
- Learn → Spend 1 token
- Teach → Earn 1 token
- Dynamic token updates via Supabase RPC

### 👤 Profile
- View user details
- Token balance display
- Upload profile avatar
- Logout functionality

### ☁️ Backend (Supabase)
- Auth + Database + Storage
- Real-time subscriptions
- Image storage (posts & avatars)

---

## 🏗️ Project Structure

```bash
lib/
├── core/
│   ├── constants/
│   ├── router/
│   ├── services/
│   └── utils/
│
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── feed/
│   ├── explore/
│   ├── sessions/
│   └── profile/
│
├── shared/
│   ├── models/
│   └── widgets/
````

---

## ⚙️ Tech Stack

* **Frontend:** Flutter (Dart)
* **State Management:** Riverpod
* **Routing:** GoRouter
* **Backend:** Supabase
* **Storage:** Supabase Storage
* **Database:** PostgreSQL (via Supabase)

---

## 📸 Screens (Coming Soon)

> UI previews will be added soon.

---

## 🚀 Getting Started

### 1. Clone the repo

```bash
git clone https://github.com/your-username/circle02.git
cd circle02
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run the app

```bash
flutter run
```

---

## 🔑 Environment Setup

Create a `.env` or configure directly:

* Supabase URL
* Supabase Anon Key

---

## 🧠 Core Idea

> “Knowledge should not be free — it should be fairly exchanged.”

Circle introduces a **token-based learning economy**, where:

* Learners pay with tokens
* Teachers earn tokens

Creating a **self-sustaining ecosystem**.

---

## 🛠️ Upcoming Features

* 🔔 Notifications
* 💬 Real-time chat
* 📅 Session booking system
* ⭐ Ratings & reviews
* 🔍 Smart search & recommendations
* 📊 Analytics dashboard

---

## 🤝 Contributing

Contributions are welcome!

```bash
# Fork the repo
# Create a new branch
git checkout -b feature-name

# Commit changes
git commit -m "Add feature"

# Push
git push origin feature-name
```

---

## 📄 License

This project is licensed under the MIT License.

---

## 👨‍💻 Author

**Pratyush Prakash**

> Building real-world scalable products 🚀

---

## 🌟 Support

If you like this project:

⭐ Star the repo
🍴 Fork it
📢 Share it

---

## 💡 Final Note

This is not just a project —
It’s a step towards building a **real startup-level product**.

---
👉 **"make it elite README"** 🔥
```
