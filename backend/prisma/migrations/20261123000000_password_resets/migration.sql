CREATE TABLE "password_resets" (
  "id" SERIAL NOT NULL,
  "email" TEXT NOT NULL,
  "code_hash" TEXT NOT NULL,
  "expires_at" TIMESTAMP(3) NOT NULL,
  "attempts" INTEGER NOT NULL DEFAULT 0,
  "used_at" TIMESTAMP(3),
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "password_resets_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "password_resets_email_idx" ON "password_resets"("email");