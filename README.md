<<<<<<< HEAD
# MindFlow

App de seguimiento emocional y apoyo psicológico.
Stack: **Flutter** (app) · **Node.js + Express** (API) · **PostgreSQL** (base de datos).

```
mindflow/
├── backend/          API REST
│   ├── db/schema.sql
│   └── src/ (config, db, middleware, controllers, routes)
└── app/              Flutter
    └── lib/ (core, features/*)
```

## 1. Backend

```bash
cd backend
cp .env.example .env        # edita DATABASE_URL y JWT_SECRET
npm install

createdb mindflow           # o créala desde pgAdmin
npm run db:init             # ejecuta db/schema.sql

npm run dev                 # http://localhost:3000/api/health
```

### Endpoints

| Método | Ruta | Descripción |
|---|---|---|
| POST | `/api/auth/register` | Crear cuenta |
| POST | `/api/auth/login` | Iniciar sesión (devuelve JWT) |
| GET/PATCH | `/api/me` | Perfil y preferencias (tema, consentimiento de IA) |
| GET/POST | `/api/journal` | Listar / crear entradas del diario |
| GET | `/api/journal/stats?days=30` | Promedios diarios para las gráficas |
| GET/DELETE | `/api/journal/:id` | Ver / borrar una entrada |
| GET/POST/DELETE | `/api/contacts` | Red de apoyo |
| GET | `/api/resources?category=` | Biblioteca psicoeducativa |

Todas excepto `/auth/*` y `/health` requieren `Authorization: Bearer <token>`.

## 2. App Flutter

```bash
cd app
flutter create . --org com.tuusuario --project-name mindflow   # genera android/ios (conserva lib/ y pubspec.yaml)
flutter pub get
flutter run
```

La URL del API está en `lib/core/api_client.dart` (`10.0.2.2` para emulador Android;
en un dispositivo físico usa la IP de tu PC).

## 3. Siguientes pasos sugeridos

1. Pantalla de registro diario (CU01) → `POST /api/journal`
2. Gráficas en Progreso → `GET /api/journal/stats`
3. Pantalla de contactos de confianza → `/api/contacts`
4. Onboarding con disclaimer y consentimiento de IA → `PATCH /api/me`
5. Análisis de IA asíncrono (solo con `allow_ai_analysis = true`)
6. Directorio de profesionales (Google Maps) y líneas de emergencia
7. Exportación por QR

## Nota sobre las alertas automáticas a contactos

El esquema ya guarda `risk_level` por entrada, pero **no** hay envío automático de SMS.
Antes de implementarlo conviene decidir con calma: consentimiento explícito del usuario y del
contacto, confirmación del usuario antes de avisar (como describe tu flujo), manejo de falsos
positivos y revisión legal (datos de salud mental son datos sensibles).
=======
# MindFlow
>>>>>>> 37aeac537062c702d1c41e841f79728eb916f052
