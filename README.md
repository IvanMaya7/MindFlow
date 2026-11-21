# MindFlow

App móvil de seguimiento emocional y apoyo psicológico.

```
mindflow/
├── backend/auth-service/   # Microservicio de autenticación (Node.js + Express + Prisma)
└── mobile/lib/             # Código Flutter (login, registro, home, tema claro/oscuro)
```

## Backend (auth-service)

```bash
cd backend/auth-service
cp .env.example .env        # y edita DATABASE_URL (RDS) y JWT_SECRET
npm install
npx prisma migrate dev --name init
npm run dev
```

Endpoints (puerto 4001):

| Método | Ruta                 | Descripción                                   |
|--------|----------------------|-----------------------------------------------|
| POST   | /api/auth/register   | Crear cuenta (email, password, displayName)   |
| POST   | /api/auth/login      | Iniciar sesión                                |
| GET    | /api/auth/me         | Perfil (requiere Bearer token)                |
| GET    | /health              | Estado del servicio                           |

En AWS RDS: permite tu IP en el Security Group (puerto 5432) y usa `sslmode=require`.

## Frontend (Flutter)

```bash
flutter create mobile        # crea el proyecto base
cd mobile
flutter pub add http provider flutter_secure_storage google_fonts
```

Luego reemplaza la carpeta `lib/` generada por la `lib/` de este zip.

- El emulador de Android accede al backend local por `http://10.0.2.2:4001` (ya configurado en `lib/core/api_config.dart`).
- Para producción cambia `_prod` en `api_config.dart` por la URL de tu backend en AWS.
- `flutter_secure_storage` requiere `minSdkVersion 23` en `android/app/build.gradle`.
