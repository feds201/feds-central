# ⚡ FEDS Dev Console - Quick Reference

## 🚀 Getting Started (< 5 minutes)

```bash
# 1. Setup environment
cp .env.example .env.local
# Edit .env.local with your Supabase credentials

# 2. Install dependencies
npm install

# 3. Start dev server
npm run dev

# 4. Open http://localhost:5173
```

## 📝 Environment Variables

```
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGc...
```

Get these from Supabase → Settings → API

## 🎯 Key Files

| File | Purpose |
|------|---------|
| `src/App.jsx` | Main app with routing |
| `src/pages/` | Page components |
| `src/components/` | Reusable UI components |
| `src/lib/supabase.js` | Supabase client |
| `src/styles/globals.css` | Global styles |
| `package.json` | Dependencies |
| `.env.local` | Your secrets |
| `supabase-setup.sql` | Database schema |

## 🛣️ Routes

| Route | Purpose |
|-------|---------|
| `/signin` | Google OAuth login |
| `/dashboard` | Overview & stats |
| `/services` | Manage services |
| `/credentials` | Manage credentials |
| `/authenticator` | Manage TOTP |
| `/audit` | Activity logs |

## 🗄️ Tables

| Table | Purpose |
|-------|---------|
| `audit_logs` | User action history |
| `services` | Digital services |
| `credentials` | Stored credentials |
| `authenticator` | User's main TOTP |
| `authenticator_entries` | Service-specific TOTP |

## 🔐 Row Level Security (RLS)

All tables have RLS enabled. Users can only see their own data.

Policies auto-enforced:
- SELECT: Users see their own records
- INSERT/UPDATE/DELETE: Users modify their own records

## 🎨 Styling

Uses Tailwind CSS classes:

```jsx
<button className="btn-primary">Save</button>
<input className="input-field" />
<div className="card">Content</div>
```

Custom classes in `globals.css`:
- `.glass` — Glassmorphism effect
- `.gradient-text` — Gradient text
- `.btn-primary`, `.btn-secondary`, `.btn-ghost`
- `.card` — Card container

## 📦 Key Dependencies

```json
{
  "react": "18.3.1",
  "react-router-dom": "6.21.3",
  "@supabase/supabase-js": "2.39.3",
  "framer-motion": "10.16.16",
  "tailwindcss": "3.3.6",
  "otplib": "12.0.1",
  "qrcode.react": "3.1.0",
  "lucide-react": "0.294.0"
}
```

## 🧪 Common Tasks

### Add a new page
1. Create `src/pages/MyPage.jsx`
2. Import in `src/App.jsx`
3. Add route
4. Add to sidebar nav

### Add a new component
1. Create `src/components/MyComponent.jsx`
2. Import where needed
3. Use

### Query database
```jsx
const { data } = await supabase
  .from('table_name')
  .select('*')
  .eq('user_id', session.user.id)
```

### Insert record
```jsx
const { data, error } = await supabase
  .from('table_name')
  .insert([{ field: 'value' }])
  .select()
```

### Delete record
```jsx
await supabase
  .from('table_name')
  .delete()
  .eq('id', recordId)
```

## 🐛 Debug Tips

### Check if authenticated
```jsx
const { data } = await supabase.auth.getSession()
console.log(data.session) // null if not logged in
```

### View Supabase logs
Supabase dashboard → Logs → Recent errors

### Check RLS policies
Supabase dashboard → Authentication → Policies

### Browser DevTools
- Network tab: Check API calls
- Console: Check errors
- Application: Check localStorage

## 📱 Responsive Breakpoints

Tailwind breakpoints used:
- `md:` — 768px (tablet)
- `lg:` — 1024px (desktop)
- `xl:` — 1280px (large)

## 🎯 Build Commands

```bash
npm run dev          # Start dev server
npm run build        # Production build
npm run preview      # Preview build locally
npm run lint         # Check code style
npm run type-check   # TypeScript check
```

## 🚀 Deployment

### Build
```bash
npm run build
```

### Deploy to Vercel
```bash
npm i -g vercel
vercel
```

### Deploy to Netlify
1. Push to GitHub
2. Connect repo to Netlify
3. Set environment variables
4. Netlify auto-deploys

## 🔗 Quick Links

- **Supabase Docs**: https://supabase.com/docs
- **React Docs**: https://react.dev
- **Tailwind Docs**: https://tailwindcss.com
- **Vite Docs**: https://vitejs.dev
- **Framer Motion**: https://www.framer.com/motion/

## 💡 Pro Tips

1. **Use RLS for security** — Never trust client-side data
2. **Enable CORS** — In production, set specific origins
3. **Cache data** — Use React state or localStorage
4. **Batch queries** — Reduce API calls
5. **Index foreign keys** — Improves query performance
6. **Monitor costs** — Set Supabase spending limits
7. **Use transactions** — For multi-table operations

## ❓ FAQ

**Q: Why do I get auth errors?**  
A: Check `.env.local` has correct Supabase URL & key

**Q: How do I add a new user?**  
A: They sign up via Google OAuth automatically

**Q: Can I export data?**  
A: Use Supabase export tools or build an export API

**Q: How do I deploy?**  
A: Build → Deploy to Vercel, Netlify, or your server

---

**Need more help?** Check `README.md` or `SETUP_GUIDE.md`
