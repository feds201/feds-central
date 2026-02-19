# FEDS Dev Console - Installation & Setup Guide

## 🎯 Quick Start

### Prerequisites
- Node.js 18+ and npm
- Supabase account (free tier works fine)

### 1️⃣ Environment Setup

Copy `.env.example` to `.env.local` and fill in your values (see `.env.example` for the full list with descriptions):

```bash
cp .env.example .env.local
nano .env.local
```

### 2️⃣ Install Dependencies

```bash
npm install
```

### 3️⃣ Setup Supabase Database

Run the SQL schema in your Supabase SQL editor:

```sql
-- Create audit_logs table
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id bigint PRIMARY KEY DEFAULT (nextval('audit_logs_id_seq'::regclass)),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  action text NOT NULL,
  details jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now()
);

-- Create authenticator table
CREATE TABLE IF NOT EXISTS public.authenticator (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  totp_secret text NOT NULL,
  totp_period int DEFAULT 30,
  recovery_codes text[],
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create authenticator_entries table
CREATE TABLE IF NOT EXISTS public.authenticator_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  service_name text NOT NULL,
  totp_secret text NOT NULL,
  totp_period int DEFAULT 30,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create services table
CREATE TABLE IF NOT EXISTS public.services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  url text,
  description text,
  tags text[],
  owner_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create credentials table
CREATE TABLE IF NOT EXISTS public.credentials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  service_id uuid REFERENCES public.services(id) ON DELETE CASCADE,
  username text NOT NULL,
  password_encrypted text NOT NULL,
  notes text,
  owner_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create sequences for audit_logs
CREATE SEQUENCE IF NOT EXISTS audit_logs_id_seq AS bigint START WITH 1 INCREMENT BY 1;

-- Enable Row Level Security (RLS)
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE authenticator ENABLE ROW LEVEL SECURITY;
ALTER TABLE authenticator_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE credentials ENABLE ROW LEVEL SECURITY;

-- RLS Policies for audit_logs
CREATE POLICY "Users can view their own audit logs" 
  ON audit_logs FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "System can insert audit logs" 
  ON audit_logs FOR INSERT 
  WITH CHECK (true);

-- RLS Policies for authenticator
CREATE POLICY "Users can view their own authenticator" 
  ON authenticator FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own authenticator" 
  ON authenticator FOR INSERT, UPDATE, DELETE 
  USING (auth.uid() = user_id);

-- RLS Policies for authenticator_entries
CREATE POLICY "Users can view their own entries" 
  ON authenticator_entries FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own entries" 
  ON authenticator_entries FOR INSERT, UPDATE, DELETE 
  USING (auth.uid() = user_id);

-- RLS Policies for services
CREATE POLICY "Users can view their own services" 
  ON services FOR SELECT 
  USING (auth.uid() = owner_id);

CREATE POLICY "Users can manage their own services" 
  ON services FOR INSERT, UPDATE, DELETE 
  USING (auth.uid() = owner_id);

-- RLS Policies for credentials
CREATE POLICY "Users can view their own credentials" 
  ON credentials FOR SELECT 
  USING (auth.uid() = owner_id);

CREATE POLICY "Users can manage their own credentials" 
  ON credentials FOR INSERT, UPDATE, DELETE 
  USING (auth.uid() = owner_id);
```

### 4️⃣ Setup Google OAuth (Optional but Recommended)

In your Supabase project:
1. Go to Authentication → Providers
2. Enable Google OAuth
3. Add your redirect URL: `http://localhost:5173/dashboard` (for dev)
4. Copy the Google Client ID & Secret from [Google Cloud Console](https://console.cloud.google.com)

### 5️⃣ Run Development Server

```bash
npm run dev
```

The app will open at `http://localhost:5173`

## 🚀 Build for Production

```bash
npm run build
```

Output will be in the `dist/` folder.

## 📦 Tech Stack

- **Frontend**: React 18 + Vite
- **Styling**: Tailwind CSS + Custom components
- **Animation**: Framer Motion
- **Auth**: Supabase OAuth (Google)
- **Database**: Supabase PostgreSQL
- **TOTP**: otplib + qrcode.react
- **Routing**: React Router v6
- **UI Icons**: Lucide React

## 🎨 Features

✅ **Google OAuth Sign-in** - Secure authentication  
✅ **Services Management** - Create, edit, delete services  
✅ **Credentials Vault** - Store usernames and passwords  
✅ **TOTP Manager** - Generate QR codes, manage authenticators  
✅ **Audit Logs** - Track all user actions  
✅ **Dark/Light Theme** - Toggle theme preference  
✅ **Responsive Design** - Works on desktop and mobile  
✅ **Real-time TOTP** - Live authenticator codes with timer  
✅ **Glassmorphism UI** - Modern, elegant interface  

## 🔐 Security Notes

- Passwords are currently stored as plain text in the `password_encrypted` field. **In production**, implement client-side encryption before sending to server.
- Use Supabase's Row Level Security (RLS) policies for data isolation.
- Never commit `.env.local` or real secrets to version control.

## 📚 Project Structure

```
src/
├── components/
│   ├── layout/          # Sidebar, TopNav, Layouts
│   ├── dashboard/       # Dashboard cards & stats
│   ├── services/        # Service components
│   ├── credentials/     # Credential components
│   ├── authenticator/   # TOTP components
│   └── audit/          # Audit log components
├── pages/              # Page components
├── lib/                # Utilities (Supabase client)
├── styles/             # Global CSS
├── App.jsx             # Main app component
└── main.jsx            # Entry point
```

## 🛠️ Development Commands

```bash
npm run dev          # Start dev server
npm run build        # Build for production
npm run preview      # Preview production build
npm run lint         # Run ESLint
npm run type-check   # Check TypeScript
```

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📄 License

MIT

---

**Built with 💜 for FEDS Programmers**
