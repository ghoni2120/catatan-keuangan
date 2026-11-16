import 'dotenv/config';

function required(name) {
  const value = process.env[name];
  if (!value) {
    console.error(`[env] Variabel ${name} belum diisi di file .env`);
    process.exit(1);
  }
  return value;
}

const jwtAccessSecret = required('JWT_ACCESS_SECRET');
if (jwtAccessSecret.length < 32) {
  console.error('[env] JWT_ACCESS_SECRET minimal 32 karakter');
  process.exit(1);
}

export const env = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: Number(process.env.PORT) || 3000,
  databaseUrl: required('DATABASE_URL'),
  dbSsl: process.env.DB_SSL !== 'false',
  jwtAccessSecret,
  accessTtl: process.env.ACCESS_TOKEN_TTL || '15m',
  refreshDays: Number(process.env.REFRESH_TOKEN_DAYS) || 30,
  corsOrigins: (process.env.CORS_ORIGINS || '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean),
};

export const isProd = env.nodeEnv === 'production';